use pz_items/types.{PzAssetProofs}

// NOTE:
// Index can be -1 to mean there is no such an output.
//
pub type PzIndexes {
  ref_output_index: Int,
  user_output_index: Int,
  treasury_output_index: Int,
  provider_fee_output_index: Int,
  shared_fee_output_index: Int,
}

// bg_asset_proofs_opt, pfp_asset_proofs_opt
//
pub type PzAssetsProofs =
  (Option<PzAssetProofs>, Option<PzAssetProofs>)
