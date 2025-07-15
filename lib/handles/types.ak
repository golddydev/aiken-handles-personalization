use aiken/transaction/value.{AssetName}

pub type HandleType {
  NFTHandle
  NFTSubhandle
  VirtualSubhandle
}

pub type Handle {
  asset_name: AssetName,
  handle_type: HandleType,
}
