use aiken/builtin.{b_data}
use aiken/cbor
use aiken/option
use aiken/pairs
use aiken/string
use common/bool.{convert_int_to_bool}

pub fn get_single_value_from_pairs(
  data: Pairs<Data, Data>,
  key: ByteArray,
) -> Option<Data> {
  let values = pairs.get_all(data, b_data(key))
  when values is {
    [] -> None
    [v] -> Some(v)
    _ -> fail string.concat(@"duplicate keys: ", cbor.diagnostic(key))
  }
}

pub fn get_single_int_value_from_pairs(
  data: Pairs<Data, Data>,
  key: ByteArray,
) -> Option<Int> {
  let single_value_opt = get_single_value_from_pairs(data, key)
  when single_value_opt is {
    None -> None
    Some(single_value) -> {
      trace string.concat(cbor.diagnostic(key), @"as single Int")
      expect single_value: Int = single_value
      Some(single_value)
    }
  }
}

pub fn get_single_int_as_bool_value_from_pairs(
  data: Pairs<Data, Data>,
  key: ByteArray,
) -> Bool {
  get_single_int_value_from_pairs(data, key)
    |> option.map(convert_int_to_bool)
    |> option.or_else(False)
}

pub fn get_first_int_value_from_pairs(
  data: Pairs<Data, Data>,
  key: ByteArray,
) -> Option<Int> {
  let value_opt = pairs.get_first(data, b_data(key))
  when value_opt is {
    None -> None
    Some(value) -> {
      trace string.concat(cbor.diagnostic(key), @"as first Int")
      expect value: Int = value
      Some(value)
    }
  }
}

pub fn get_single_bytearray_value_from_pairs(
  data: Pairs<Data, Data>,
  key: ByteArray,
) -> Option<ByteArray> {
  let single_value_opt = get_single_value_from_pairs(data, key)
  when single_value_opt is {
    None -> None
    Some(single_value) -> {
      trace string.concat(cbor.diagnostic(key), @"as single ByteArray")
      expect single_value: ByteArray = single_value
      Some(single_value)
    }
  }
}

pub fn get_single_list_bytearray_value_from_pairs(
  data: Pairs<Data, Data>,
  key: ByteArray,
) -> Option<List<ByteArray>> {
  let single_value_opt = get_single_value_from_pairs(data, key)
  when single_value_opt is {
    None -> None
    Some(single_value) -> {
      trace string.concat(cbor.diagnostic(key), @"as single List<ByteArray>")
      expect single_value: List<ByteArray> = single_value
      Some(single_value)
    }
  }
}

pub fn get_single_pairs_value_from_pairs(
  data: Pairs<Data, Data>,
  key: ByteArray,
) -> Option<Pairs<Data, Data>> {
  let single_value_opt = get_single_value_from_pairs(data, key)
  when single_value_opt is {
    None -> None
    Some(single_value) -> {
      trace string.concat(cbor.diagnostic(key), @"as single Pairs<Data, Data>")
      expect single_value: Pairs<Data, Data> = single_value
      Some(single_value)
    }
  }
}
