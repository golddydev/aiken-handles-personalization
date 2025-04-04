// redeemer
pub type Indexes {
  pz_settings_index: Int,
  bg_approvers_index: Int,
  pfp_approvers_index: Int,
  bg_datum_index: Int,
  pfp_datum_index: Int,
}

pub type Redeemer {
  indexes: Indexes,
}

/// The generic CIP68 metadata type as defined in the CIP at
/// https://cips.cardano.org/cips/cip68/.
pub type HandleDatum {
  nft: Pairs<Data, Data>,
  version: Int,
  extra: Data,
}

// struct PzSettings {
//     treasury_fee: Int // 1st
//     treasury_cred: ByteArray // 2nd
//     pz_min_fee: Int // 3rd
//     pz_providers: Map[ByteArray]ByteArray // 4th
//     valid_contracts: []ByteArray // 5th
//     admin_creds: []ByteArray // 6th
//     settings_cred: ByteArray // 7th
//     grace_period: Int // 8th
//     subhandle_share_percent: Int // 9th
// }
pub type PZSettings =
  (
    Int,
    ByteArray,
    Int,
    Pairs<ByteArray, ByteArray>,
    List<ByteArray>,
    List<ByteArray>,
    ByteArray,
    Int,
    Int,
  )

pub type PZApproverData {
  mpt_root_hash: ByteArray,
}
