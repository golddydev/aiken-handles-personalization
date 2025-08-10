use common/collections.{
  get_single_bytearray_value_from_pairs, get_single_int_value_from_pairs,
}

// This function checks whether new_datum is reset or not (same as initial value)
// returns: Bool
//
pub fn check_new_datum_reset(
  new_extra: Pairs<Data, Data>,
  new_image: ByteArray,
) -> Bool {
  let new_image_hash_opt =
    get_single_bytearray_value_from_pairs(new_extra, "image_hash")
  let new_standard_image_opt =
    get_single_bytearray_value_from_pairs(new_extra, "standard_image")
  let new_standard_image_hash_opt =
    get_single_bytearray_value_from_pairs(new_extra, "standard_image_hash")
  let new_bg_image_opt =
    get_single_bytearray_value_from_pairs(new_extra, "bg_image")
  let new_pfp_image_opt =
    get_single_bytearray_value_from_pairs(new_extra, "pfp_image")
  let new_bg_asset_opt =
    get_single_bytearray_value_from_pairs(new_extra, "bg_asset")
  let new_pfp_asset_opt =
    get_single_bytearray_value_from_pairs(new_extra, "pfp_asset")

  // is `designer` set
  // NOTE: this is actually ipfs url
  let new_designer_opt =
    get_single_bytearray_value_from_pairs(new_extra, "designer")
  let is_designed = new_designer_opt != None

  // get pz flags
  let new_nsfw_opt = get_single_int_value_from_pairs(new_extra, "nsfw")
  let new_trial_opt = get_single_int_value_from_pairs(new_extra, "trial")

  let is_new_datum_reset = and {
      Some(new_image) == new_standard_image_opt,
      new_image_hash_opt == new_standard_image_hash_opt,
      new_bg_image_opt == None,
      new_pfp_image_opt == None,
      new_bg_asset_opt == None,
      new_pfp_asset_opt == None,
      is_designed == False,
      new_nsfw_opt == Some(0),
      new_trial_opt == Some(0),
    }
  is_new_datum_reset
}
