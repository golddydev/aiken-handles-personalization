use aiken/builtin.{b_data}
use aiken/cbor
use aiken/list
use aiken/option
use aiken/pairs
use aiken/string
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{
  Address, ScriptCredential, VerificationKeyCredential,
}
use aiken/transaction/value.{PolicyId}
use common/address.{make_address_from_bytearray}
use common/collections.{
  get_single_bytearray_value_from_pairs, get_single_int_value_from_pairs,
  get_single_value_from_pairs,
}
use common/hashes.{VerificationKeyHash}
use configs/settings_v1.{PzSettingsV1}
use handles/constants.{agreed_terms_url}
use handles/types.{Handle,
  NFTHandle, NFTSubhandle, VirtualSubhandle} as handles_types
use subhandle/utils.{find_owner_settings}
use validations/pz_governor/types.{PzIndexes}

// This function parses outputs using `pz_indexes`
// - first output must be `pz_output` (ref_output)
// - second output must be `user_output`
// - retrieve relevant outputs using pz_indexes
//
pub fn parse_outputs(
  outputs: List<Output>,
  pz_indexes: PzIndexes,
) -> (Output, Output, Option<Output>, Option<Output>, Option<Output>) {
  expect [pz_output, user_output, ..] = outputs

  let PzIndexes {
    treasury_output_index,
    provider_fee_output_index,
    shared_fee_output_index,
  } = pz_indexes

  let treasury_output_opt = list.at(outputs, treasury_output_index)
  let provider_fee_output_opt = list.at(outputs, provider_fee_output_index)
  let shared_fee_output_opt = list.at(outputs, shared_fee_output_index)

  (
    pz_output,
    user_output,
    treasury_output_opt,
    provider_fee_output_opt,
    shared_fee_output_opt,
  )
}

// - `new_metadata` must have `image` and `mediaType` (as single value)
// - for all keys in `old_metadata` other than `image` and `mediaType`,
//   there must be a corresponding key in `new_metadata` with same value.
//
// returns: Bool
//
pub fn check_new_metadata(
  new_metadata: Pairs<Data, Data>,
  old_metadata: Pairs<Data, Data>,
) -> Bool {
  // immutable values
  let new_image_opt =
    get_single_bytearray_value_from_pairs(new_metadata, "image")
  let new_media_type_opt =
    get_single_bytearray_value_from_pairs(new_metadata, "mediaType")
  expect Some(_) = new_image_opt
  expect Some(_) = new_media_type_opt

  let immutables_stay_same =
    old_metadata
      |> pairs.foldl(
          True,
          fn(key, value, acc) -> Bool {
            acc && if key == b_data("image") || key == b_data("mediaType") {
              True
            } else {
              let new_value_opt = pairs.get_first(new_metadata, key)
              let immutable_stay_same = new_value_opt == Some(value)
              if immutable_stay_same {
                True
              } else {
                trace string.concat(
                  @"immutable metadata changed: ",
                  cbor.diagnostic(key),
                )
                False
              }
            }
          },
        )
  expect immutables_stay_same

  True
}

// - transaction must be signed by `validated_by` if it is set as single value.
// - `standard_image`, `standard_image_hash`, `original_address` must be same as `old_extra`. (as single value or None)
// - `agreed_terms` must be same as `agreed_terms_url`.
// - `last_edited_time` must be same as transaction's start time.
//
// returns: Bool
//
pub fn check_new_extra(
  new_extra: Pairs<Data, Data>,
  old_extra: Pairs<Data, Data>,
  extra_signatories: List<VerificationKeyHash>,
  transaction_start_time: Int,
) -> Bool {
  // tansaction must be signed by `validated_by` if it is set as single value.
  let is_tx_signed_by_validated_by =
    get_single_bytearray_value_from_pairs(new_extra, "validated_by")
      |> option.map(
          fn(validated_by) -> Bool { list.has(extra_signatories, validated_by) },
        )
      |> option.or_else(True)
  expect is_tx_signed_by_validated_by

  // - `standard_image`, `standard_image_hash`, `original_address` must be same as `old_extra`. (as single value or None)
  let immutables_stay_same =
    ["standard_image", "standard_image_hash", "original_address"]
      |> list.all(
          fn(key) -> Bool {
            let new_value = get_single_value_from_pairs(new_extra, key)
            let old_value = get_single_value_from_pairs(old_extra, key)
            let immutable_stay_same = new_value == old_value

            if immutable_stay_same {
              True
            } else {
              trace string.concat(
                @"immutable extra changed: ",
                cbor.diagnostic(key),
              )
              False
            }
          },
        )
  expect immutables_stay_same

  // `agreed_terms` must be same as `"https://handle.me/$/tou"`.
  let agreed_terms_opt =
    get_single_bytearray_value_from_pairs(new_extra, "agreed_terms")
  expect Some(agreed_terms) = agreed_terms_opt
  let is_agreed_terms_valid = agreed_terms == agreed_terms_url
  expect is_agreed_terms_valid

  // `last_edited_time` must be same as transaction validity range's lower bound.
  let last_edited_time_opt =
    get_single_int_value_from_pairs(new_extra, "last_edited_time")
  expect Some(last_edited_time) = last_edited_time_opt
  let is_last_edited_time_valid = last_edited_time == transaction_start_time
  expect is_last_edited_time_valid

  True
}

// This function checks
// personalization is enabled and get payment_address for Subhandle.
// check pz_enabled is set to true
// - nft_settings for NFTSubHandle
// - virtual_settings for VirtualSubHandle
// check new_pz_enabled is set to correct value
//
// Returns:
// - pz_enabled: Bool
// - payment_address: Option<Address>
//
pub fn check_pz_enabled(
  new_pz_enabled: Bool,
  old_pz_enabled: Bool,
  handle: Handle,
  policy_ids: List<PolicyId>,
  reference_inputs: List<Input>,
) -> (Bool, Option<Address>) {
  let sub_handle_settings_opt =
    when handle is {
      NFTHandle(_) -> None
      NFTSubhandle(_, root_handle_name, _) -> {
        let owner_settings =
          find_owner_settings(policy_ids, reference_inputs, root_handle_name)
        let (nft_settings, _, _, _, _, _, _, payment_address_hex) =
          owner_settings
        Some((nft_settings, payment_address_hex))
      }
      VirtualSubhandle(_, root_handle_name, _) -> {
        let owner_settings =
          find_owner_settings(policy_ids, reference_inputs, root_handle_name)
        let (_, virtual_settings, _, _, _, _, _, payment_address_hex) =
          owner_settings
        Some((virtual_settings, payment_address_hex))
      }
    }

  when sub_handle_settings_opt is {
    None -> (True, None)
    Some((sub_handle_settings, payment_address_hex)) -> {
      let (_, pz_enabled, _, _, _) = sub_handle_settings
      let root_pz_enabled = pz_enabled == 1
      let payment_address = make_address_from_bytearray(payment_address_hex)

      let new_pz_enabled_valid = or {
          old_pz_enabled,
          new_pz_enabled == root_pz_enabled,
        }
      expect new_pz_enabled_valid

      (old_pz_enabled || root_pz_enabled, Some(payment_address))
    }
  }
}

// This function checks
// if resolved_addresses -> ada is set correctly
// corresponding each Handle type.
//
// resolved_addresses -> ada can only be set for VirtualSubhandle type.
//
// for VirtualSubhandle, transaction must be signed by VirtualSubhandle owner.
// `resolved_addresses` must not change.
//
pub fn check_resolved_addresses(
  handle: Handle,
  new_resolved_addresses_opt: Option<Pairs<Data, Data>>,
  old_resolved_addresses_opt: Option<Pairs<Data, Data>>,
  extra_signatories: List<VerificationKeyHash>,
) -> Bool {
  let new_resolved_ada_opt =
    new_resolved_addresses_opt
      |> option.map(
          fn(new_resolved_addresses) -> Option<ByteArray> {
            get_single_bytearray_value_from_pairs(new_resolved_addresses, "ada")
          },
        )
      |> option.flatten

  let old_resolved_ada_opt =
    old_resolved_addresses_opt
      |> option.map(
          fn(old_resolved_addresses) -> Option<ByteArray> {
            get_single_bytearray_value_from_pairs(old_resolved_addresses, "ada")
          },
        )
      |> option.flatten

  let resolved_ada_not_set = new_resolved_ada_opt == None
  let is_valid =
    when handle is {
      NFTHandle(_) -> {
        expect resolved_ada_not_set
        True
      }
      NFTSubhandle(_, _, _) -> {
        expect resolved_ada_not_set
        True
      }
      VirtualSubhandle(_, _, _) -> {
        expect Some(old_resolved_ada) = old_resolved_ada_opt
        let old_ada_address = make_address_from_bytearray(old_resolved_ada)

        // check tx is signed by virtual subhandle owner
        let is_tx_signed_by_virtual_subhandle_owner =
          check_tx_is_signed_by_virtual_subhandle_owner(
            old_ada_address,
            extra_signatories,
          )
        expect is_tx_signed_by_virtual_subhandle_owner

        // `resolved_addresses` must not change
        let resolved_addresses_stay_same =
          new_resolved_addresses_opt == old_resolved_addresses_opt
        expect resolved_addresses_stay_same

        True
      }
    }
  is_valid
}

fn check_tx_is_signed_by_virtual_subhandle_owner(
  old_ada_address: Address,
  extra_signatories: List<VerificationKeyHash>,
) -> Bool {
  // check old_ada_address's payment_credential must be VerificationKeyCredential
  when old_ada_address.payment_credential is {
    VerificationKeyCredential(old_ada_address_vk_hash) ->
      list.has(extra_signatories, old_ada_address_vk_hash)
    _ ->
      fail @"virtual subhandle owner address must be VerificationKeyCredential"
  }
}

// This function checks
// corresponding fees are paid correctly if `grace_period` is over.
// - `treasury_fee` must be paid
// - `provider_fee` must be paid
// - `shared_fee` must be paid if `is_subhandle` is True
//
// returns: Bool
//
pub fn check_fees_are_paid(
  handle_name: ByteArray,
  is_subhandle: Bool,
  settings_v1: PzSettingsV1,
  payment_address_opt: Option<Address>,
  treasury_output_opt: Option<Output>,
  provider_fee_output_opt: Option<Output>,
  shared_fee_output_opt: Option<Output>,
  last_edited_time_opt: Option<Int>,
  transaction_start_time: Int,
) -> Bool {
  let PzSettingsV1 {
    provider_script_hashes,
    treasury_script_hash,
    treasury_fee,
    pz_min_fee,
    grace_period,
    subhandle_share_percent,
    ..
  } = settings_v1

  // check tx is in grace period
  let is_in_grace_period =
    last_edited_time_opt
      |> option.map(
          fn(last_edited_time) -> Bool {
            transaction_start_time < last_edited_time + grace_period
          },
        )
      |> option.or_else(False)
  if is_in_grace_period {
    trace @"in grace period"
    True
  } else {
    // calculate provider and shared fee
    let shared_fee =
      if is_subhandle {
        pz_min_fee * subhandle_share_percent / 100
      } else {
        0
      }
    let provider_fee = pz_min_fee - shared_fee

    // treasury fee must be paid
    expect Some(treasury_output) = treasury_output_opt
    let is_treasury_fee_paid =
      check_fee_output_is_valid(
        treasury_output,
        fn(address: Address) -> Bool {
          address.payment_credential == ScriptCredential(treasury_script_hash)
        },
        treasury_fee,
        handle_name,
      )
    expect is_treasury_fee_paid

    // pz provider fee must be paid
    expect Some(provider_fee_output) = provider_fee_output_opt
    let is_provider_fee_paid =
      check_fee_output_is_valid(
        provider_fee_output,
        fn(address: Address) -> Bool {
          list.any(
            provider_script_hashes,
            fn(script_hash) -> Bool {
              address.payment_credential == ScriptCredential(script_hash)
            },
          )
        },
        provider_fee,
        handle_name,
      )
    expect is_provider_fee_paid

    // shared fee must be paid
    let is_shared_fee_paid =
      if is_subhandle {
        expect Some(shared_fee_output) = shared_fee_output_opt
        expect Some(payment_address) = payment_address_opt
        check_fee_output_is_valid(
          shared_fee_output,
          fn(address: Address) -> Bool { address == payment_address },
          shared_fee,
          handle_name,
        )
      } else {
        // shared fee is not paid for non-subhandle
        True
      }
    expect is_shared_fee_paid

    True
  }
}

fn check_fee_output_is_valid(
  fee_output: Output,
  check_address_is_valid: fn(Address) -> Bool,
  fee: Int,
  handle_name: ByteArray,
) -> Bool {
  let Output { address, datum, value: v, reference_script } = fee_output

  and {
    check_address_is_valid(address),
    datum == InlineDatum(handle_name),
    value.lovelace_of(v) >= fee,
    reference_script == None,
  }
}
