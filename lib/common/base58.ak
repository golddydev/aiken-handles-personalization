use aiken/builtin
use aiken/bytearray

pub fn base58_to_hash(base58_str: ByteArray) -> ByteArray {
  // Count leading '1's efficiently
  let leading_ones = count_leading_ones(base58_str)
  // Convert to integer with optimized algorithm
  let decoded_int = base58_to_int(base58_str, leading_ones)
  // Convert integer to bytes and handle leading zeros
  int_to_bytes(decoded_int, leading_ones)
}

fn count_leading_ones(data: ByteArray) -> Int {
  let len = builtin.length_of_bytearray(data)
  do_count_leading_ones(data, 0, len)
}

fn do_count_leading_ones(data: ByteArray, index: Int, len: Int) -> Int {
  if index >= len {
    0
  } else {
    let byte = builtin.index_bytearray(data, index)
    if byte == 0x31 {
      // '1' ASCII = 0x31
      1 + do_count_leading_ones(data, index + 1, len)
    } else {
      0
    }
  }
}

/// Base58 to integer conversion
fn base58_to_int(data: ByteArray, leading_ones: Int) -> Int {
  let len = builtin.length_of_bytearray(data)
  do_base58_to_int(data, leading_ones, len, 0)
}

fn do_base58_to_int(
  data: ByteArray,
  index: Int,
  len: Int,
  accumulator: Int,
) -> Int {
  if index >= len {
    accumulator
  } else {
    let char_byte = builtin.index_bytearray(data, index)
    let char_value = lookup_base58_char(char_byte)
    if char_value == -1 {
      fail @"invalid Base58 character"
    } else {
      let new_acc = accumulator * 58 + char_value
      do_base58_to_int(data, index + 1, len, new_acc)
    }
  }
}

fn lookup_base58_char(char_byte: Int) -> Int {
  if char_byte >= 0x31 && char_byte <= 0x39 {
    // Characters '1'-'9' map to values 0-8
    char_byte - 0x31
  } else if char_byte >= 0x41 && char_byte <= 0x48 {
    // Characters 'A'-'H' map to values 9-16
    char_byte - 0x41 + 9
  } else if char_byte >= 0x4a && char_byte <= 0x4e {
    // Characters 'J'-'N' map to values 17-21 (skip 'I')
    char_byte - 0x4a + 17
  } else if char_byte >= 0x50 && char_byte <= 0x5a {
    // Characters 'P'-'Z' map to values 22-32 (skip 'O')
    char_byte - 0x50 + 22
  } else if char_byte >= 0x61 && char_byte <= 0x6b {
    // Characters 'a'-'k' map to values 33-43
    char_byte - 0x61 + 33
  } else if char_byte >= 0x6d && char_byte <= 0x7a {
    // Characters 'm'-'z' map to values 44-57 (skip 'l')
    char_byte - 0x6d + 44
  } else {
    -1
  }
  // Invalid character indicator
}

fn int_to_bytes(value: Int, leading_zeros: Int) -> ByteArray {
  do_int_to_bytes(value, #"") |> prepend_zeros(leading_zeros)
}

fn do_int_to_bytes(value: Int, acc: ByteArray) -> ByteArray {
  if value == 0 {
    acc
  } else {
    let byte = value % 256
    let remaining = value / 256
    let new_acc = bytearray.push(acc, byte)
    do_int_to_bytes(remaining, new_acc)
  }
}

fn prepend_zeros(data: ByteArray, zero_count: Int) -> ByteArray {
  let zeros_bytes = make_zeros_bytes(zero_count)
  bytearray.concat(zeros_bytes, data)
}

fn make_zeros_bytes(zero_count: Int) -> ByteArray {
  do_make_zeros_bytes(zero_count, #"")
}

fn do_make_zeros_bytes(zero_count: Int, acc: ByteArray) -> ByteArray {
  if zero_count <= 0 {
    acc
  } else {
    do_make_zeros_bytes(zero_count - 1, bytearray.push(acc, 0))
  }
}

test test_leading_ones_fast() {
  let test_str = "111ABC"
  let count = count_leading_ones(test_str)
  count == 3
}

test base58_to_hash_test_1() {
  let base58_str = "b2rhnffvtxSA5zyNs5uYK9z1iBjZSr8dfVzA39XJLyhZYLBj"
  base58_to_hash(base58_str) == #"01551220ee1647bc42cdcfe547f348090aa9f2332f0085860d5f40bf502d0d0c64eeec72"
}

test base58_to_hash_test_2() {
  let base58_str = "1111111SA5zyNs5uYK9z1iBjZSr8dfVzA39XJLyhZYLBj"
  base58_to_hash(base58_str) == #"000000000000002a2baba41722bb829c6ba51a324501e415152292afc50ccc64eeec72"
}
