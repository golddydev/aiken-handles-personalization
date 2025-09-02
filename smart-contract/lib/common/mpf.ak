use aiken/merkle_patricia_forestry as mpt

/// This function checks non-membership of key in the MPT.
/// Just insert that key into the MPT.
/// If insertion failed, then key is already in the MPT.
///
pub fn not_has(
  self: mpt.MerklePatriciaForestry,
  key: ByteArray,
  proof: mpt.Proof,
) -> Bool {
  let new_root = mpt.insert(self, key, #"", proof)
  new_root != self
}
