use aiken/builtin.{b_data}
use aiken/cbor
use aiken/pairs
use aiken/string

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
