use aiken/bytearray

/// (100) Reference Token Prefix
pub const prefix_100: ByteArray = #"000643b0"

/// (222) Non-Fungible Token Prefix
pub const prefix_222: ByteArray = #"000de140"

/// (333) Fungible Token Prefix
pub const prefix_333: ByteArray = #"0014df10"

/// (444) Rich-Fungible Token Prefix
pub const prefix_444: ByteArray = #"001bc280"

/// custom for Koralabs
///
/// (000) Virtual Sub Handle Prefix
pub const prefix_000: ByteArray = #"00000000"

pub const prefix_001: ByteArray = #"00001070"

pub fn is_user_asset_name(asset_name: ByteArray) -> Bool {
  let prefix = bytearray.take(asset_name, 4)
  or {
    prefix == prefix_222,
    prefix == prefix_444,
  }
}

pub fn make_reference_asset_name_from_user_asset_name(
  asset_name: ByteArray,
) -> ByteArray {
  expect is_user_asset_name(asset_name)
  let without_prefix = bytearray.drop(asset_name, 4)
  bytearray.concat(prefix_100, without_prefix)
}
