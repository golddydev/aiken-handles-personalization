use aiken/builtin.{index_bytearray}
use aiken/bytearray
use aiken/transaction/value.{AssetName}
use common/collections.{get_single_value_from_pairs}

pub type CIP68Datum {
  metadata: Pairs<Data, Data>,
  version: Int,
  extra: Data,
}

/// (100) Reference Token Prefix
pub const prefix_100: ByteArray = #"000643b0"

/// (222) Non-Fungible Token Prefix
pub const prefix_222: ByteArray = #"000de140"

/// (333) Fungible Token Prefix
pub const prefix_333: ByteArray = #"0014df10"

/// (444) Rich-Fungible Token Prefix
pub const prefix_444: ByteArray = #"001bc280"

// ------------------------- custom for Koralabs

/// (000) Virtual Sub Handle Prefix
pub const prefix_000: ByteArray = #"00000000"

/// Owner Settings Handle Prefix
pub const prefix_001: ByteArray = #"00001070"

pub fn check_asset_name_is_reference_asset_name(asset_name: ByteArray) -> Bool {
  let prefix = bytearray.take(asset_name, 4)
  prefix == prefix_100
}

pub fn check_asset_name_is_virtual_subhandle_asset_name(
  asset_name: ByteArray,
) -> Bool {
  let prefix = bytearray.take(asset_name, 4)
  prefix == prefix_000
}

/// Check if asset is CIP-25
/// or not, then asset must be user token or RFT
/// return valid or NOT, and CIP-68 or CIP-25
///
pub fn check_asset_name_is_user_asset_or_rft(
  asset_name: ByteArray,
) -> (Bool, Bool) {
  let prefix = bytearray.take(asset_name, 4)
  let is_prefix_valid = check_asset_name_prefix_is_valid(prefix)
  when is_prefix_valid is {
    True -> {
      // if asset is CIP-68, must be user asset or RFT
      let is_user_asset_or_rft = or {
          prefix == prefix_222,
          prefix == prefix_444,
        }
      (is_user_asset_or_rft, True)
    }
    False ->
      // if asset is CIP-25, then this is user asset
      (True, False)
  }
}

/// This function returns reference asset name from any asset name (user or RFT)
/// NOTE:
/// this function assumes that asset name is CIP-68
///
pub fn get_reference_asset_name(cip68_asset_name: AssetName) -> AssetName {
  expect bytearray.length(cip68_asset_name) > 4
  let without_prefix = bytearray.drop(cip68_asset_name, 4)

  bytearray.concat(prefix_100, without_prefix)
}

/// This function checks asset name's prefix is valid
/// If asset name is less than 4 bytes, then it's not valid (CIP-25 Asset Name)
/// otherwise, check asset name prefix's first and fourth bytes are 0
/// then it is CIP-67 Asset Name Label
///
pub fn check_asset_name_prefix_is_valid(prefix: ByteArray) -> Bool {
  let is_four_bytes = bytearray.length(prefix) == 4

  when is_four_bytes is {
    True -> {
      let first_byte = index_bytearray(prefix, 0)
      let fourth_byte = index_bytearray(prefix, 3)

      let is_valid = first_byte == 0 && fourth_byte == 0
      is_valid
    }
    False -> False
  }
}

pub fn get_image_from_cip68_datum(datum: CIP68Datum) -> ByteArray {
  let CIP68Datum { metadata, .. } = datum
  let image_data_opt = get_single_value_from_pairs(metadata, "image")
  when image_data_opt is {
    Some(image_data) -> {
      expect image: ByteArray = image_data
      image
    }
    None -> fail @"cip68 datum must have image"
  }
}
