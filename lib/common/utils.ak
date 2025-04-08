use aiken/bytearray
use aiken/merkle_patricia_forestry as mpt

// parse asset bytearray into policy id and asset name
//
pub fn parse_asset_bytearray(asset: ByteArray) -> (ByteArray, ByteArray) {
  expect bytearray.length(asset) > 28
  let (policy_id, asset_name) =
    (bytearray.take(asset, 28), bytearray.drop(asset, 28))
  (policy_id, asset_name)
}

// Check non-membership of key in the MPT
// Just insert that key into the MPT
// if insertion failed, means key is already in the MPT
//
pub fn not_has(
  self: mpt.MerklePatriciaForestry,
  key: ByteArray,
  proof: mpt.Proof,
) -> Bool {
  let new_root = mpt.insert(self, key, #"", proof)
  new_root != self
}
