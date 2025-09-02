// struct SubHandleSettings {
//     public_minting_enabled: Int
//     pz_enabled: Int
//     tier_pricing: [][]Int
//     default_styles: Data
//     save_original_address: Int
// }
pub type SubHandleSettings =
  (Int, Int, List<(Int, Int)>, Data, Int)

// struct OwnerSettings {
//     nft: SubHandleSettings
//     virtual: SubHandleSettings
//     buy_down_price: Int
//     buy_down_paid: Int
//     buy_down_percent: Int
//     agreed_terms: Data
//     migrate_sig_required: Int
//     payment_address: ByteArray
// }
pub type OwnerSettings =
  (SubHandleSettings, SubHandleSettings, Int, Int, Int, Data, Int, ByteArray)
