use aiken/bytearray
use aiken/list
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{PolicyId}
use common/address.{convert_address_from_bytearray}
use common/cip68.{prefix_001}
use handles/types.{Handle,
  NFTHandle, NFTSubhandle, VirtualSubhandle} as handles_types
use subhandle/types.{OwnerSettings}

// This function finds Owner Settings from reference inputs.
//
// NOTE:
// root_handle_name is without asset name label.
//
pub fn find_owner_settings(
  policy_ids: List<PolicyId>,
  reference_inputs: List<Input>,
  root_handle_name: ByteArray,
) -> OwnerSettings {
  let owner_asset_name = bytearray.concat(prefix_001, root_handle_name)
  let owner_settings_input_opt =
    list.find(
      reference_inputs,
      fn(i) {
        list.any(
          policy_ids,
          fn(policy_id) -> Bool {
            value.quantity_of(i.output.value, policy_id, owner_asset_name) == 1
          },
        )
      },
    )
  expect Some(owner_settings_input) = owner_settings_input_opt

  let Input { output: Output { datum, .. }, .. } = owner_settings_input

  // parse OwnerSettings as InlineDatum
  expect InlineDatum(inline_datum) = datum
  expect owner_settings: OwnerSettings = inline_datum

  owner_settings
}

// This function checks
// personalization is enabled and get payment_address for Subhandle.
// check pz_enabled is set to 1 for
// - nft_settings for NFTSubHandle
// - virtual_settings for VirtualSubHandle
//
// Returns:
// - pz_enabled: Bool
// - payment_address: Option<Address>
//
pub fn check_pz_enabled(
  handle: Handle,
  policy_ids: List<PolicyId>,
  reference_inputs: List<Input>,
) -> (Bool, Option<Address>) {
  when handle is {
    NFTHandle(_) -> (True, None)
    NFTSubhandle(_, root_handle_name, _) -> {
      let owner_settings =
        find_owner_settings(policy_ids, reference_inputs, root_handle_name)
      let (nft_settings, _, _, _, _, _, _, payment_address_hex) = owner_settings
      let (_, pz_enabled, _, _, _) = nft_settings
      let payment_address = convert_address_from_bytearray(payment_address_hex)
      (pz_enabled == 1, Some(payment_address))
    }
    VirtualSubhandle(_, root_handle_name, _) -> {
      let owner_settings =
        find_owner_settings(policy_ids, reference_inputs, root_handle_name)
      let (_, virtual_settings, _, _, _, _, _, payment_address_hex) =
        owner_settings
      let (_, pz_enabled, _, _, _) = virtual_settings
      let payment_address = convert_address_from_bytearray(payment_address_hex)
      (pz_enabled == 1, Some(payment_address))
    }
  }
}
