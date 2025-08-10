use aiken/builtin
use aiken/bytearray
use aiken/transaction/value.{AssetName}
use common/cip68.{prefix_000, prefix_100}
use handles/types.{Handle, NFTHandle, NFTSubhandle, VirtualSubhandle}

// This function
// parse Ref Handle OR Virtual Subhandle's asset_name as Handle
// 
// Returns: Handle and handle_name
//
pub fn parse_handle_asset_name(asset_name: AssetName) -> (Handle, ByteArray) {
  let prefix = bytearray.take(asset_name, 4)
  let handle_name = bytearray.drop(asset_name, 4)
  let (root_handle_name, is_subhandle, subhandle_name) =
    parse_handle_name(handle_name)

  if prefix == prefix_100 {
    // NFTHandle or NFTSubhandle
    if is_subhandle {
      (NFTSubhandle(handle_name, root_handle_name, subhandle_name), handle_name)
    } else {
      (NFTHandle(handle_name), handle_name)
    }
  } else if prefix == prefix_000 {
    // VirtualSubhandle
    expect is_subhandle

    (
      VirtualSubhandle(handle_name, root_handle_name, subhandle_name),
      handle_name,
    )
  } else {
    fail @"invalid asset name label for pz asset"
  }
}

// Get root_handle_name (empty if handle is not Subhandle)
// Get is_subhandle and subhandle_name (Empty when handle is not Subhandle)
// This function checks handle_name must have at most one @ symbol.
//
// CAUTION:
// This function assumes that handle_name is valid. (without asset name label)
//
pub fn parse_handle_name(handle_name: ByteArray) -> (ByteArray, Bool, ByteArray) {
  when index_of_at_symbol(handle_name) is {
    Some(idx) -> {
      // if handle_name contains @ symbol, it is a subhandle
      let root_handle_name = bytearray.drop(handle_name, idx + 1)
      // root_handle_name should not contain @ symbol
      expect index_of_at_symbol(root_handle_name) == None
      // subhandle_name is [0, idx)
      let subhandle_name = bytearray.take(handle_name, idx)
      (root_handle_name, True, subhandle_name)
    }
    None -> (#"", False, #"")
  }
}

pub fn index_of_at_symbol(handle_name: ByteArray) -> Option<Int> {
  let length = bytearray.length(handle_name)
  do_index_of_at_symbol(handle_name, 0, length)
}

fn do_index_of_at_symbol(
  handle_name: ByteArray,
  idx: Int,
  length: Int,
) -> Option<Int> {
  if idx >= length {
    None
  } else {
    if builtin.index_bytearray(handle_name, idx) == 0x40 {
      Some(idx)
    } else {
      do_index_of_at_symbol(handle_name, idx + 1, length)
    }
  }
}
