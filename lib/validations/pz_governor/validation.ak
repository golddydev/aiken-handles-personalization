use aiken/transaction.{Transaction}
use configs/settings.{PzSettings, find_pz_settings}
use configs/settings_v1.{PzSettingsV1}
use validations/pz_governor/utils.{find_pz_utxo}

pub fn can_personalize(transaction: Transaction) -> Bool {
  let Transaction { inputs, reference_inputs, .. } = transaction

  // must attach `Settings` NFT in reference inputs.
  let PzSettings { data: settings_data, .. } =
    find_pz_settings(reference_inputs)
  expect settings_datum: PzSettingsV1 = settings_data
  let PzSettingsV1 { policy_ids, .. } = settings_datum

  // must have only one UTxO with handle Reference Asset or Virtual Subhandle Asset
  let pz_utxo = find_pz_utxo(inputs, policy_ids)

  todo
}
