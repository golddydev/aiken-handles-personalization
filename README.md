# aiken-handles-personalization

## Smart Contract Overview

The Personalization contract is used to personalize Ada Handle NFTs.

This smart contract holds asset name label of `100 - Reference token` and `000 - Virtual Subhandle`.

## Handles

There are 3 types of handles.

- **HANDLE**: The normal handle without `@` symbol in its name. (E.g. `papag00se`, `bigirishlion`, `golddy`)

- **NFT_SUBHANDLE**: The sub handle with `@` in its name. (E.g. `papag00se@kora`, `bigirishlion@kora`, `golddy@kora`)

  > NOTE: `kora` handle must exist.

- **VIRTUAL_SUBHANDLE**: The virtual subhandle with `@` in its name. (E.g. `virtual_goose@kora`).

  > NOTE: This asset's asset name label is `LBL_000` and datum is directly attached to this token.

## Types

### Personalization Settings

This is loaded from reference input, which contains `pz_settings` handle.

Reference Input address must be same as `pz_settings.settings_cred` validator address.

```rust
pub type PzSettings {
  pz_governor: ByteArray,
  data: PzSettingsV1,
}

pub type PzSettingsV1 {
  treasury_fee: Int,
  treasury_cred: ByteArray,
  pz_min_fee: Int,
  valid_providers: List<ByteArray>,
  valid_contracts: List<ByteArray>,
  admin_verification_key_hashes: List<ByteArray>,
  settings_script_hash: ByteArray,
  grace_period: Int,
  subhandle_share_percent: Int,
}
```

### OwnerSettings

This is root handle owner settings.

For all NFT Subhandles and Virtual Subhandles, there is owner settings Token.

Asset Name Label is `LBL_001` and name is Root handle name.

```rust
//(001) token
struct OwnerSettings {
    nft: SubHandleSettings
    virtual: SubHandleSettings
    buy_down_price: Int
    buy_down_paid: Int
    buy_down_percent: Int
    agreed_terms: Data
    migrate_sig_required: Int
    payment_address: ByteArray
}

struct SubHandleSettings {
    public_minting_enabled: Int
    pz_enabled: Int
    tier_pricing: [][]Int
    default_styles: Data
    save_original_address: Int
}
```

### CIP68 Datum

This is most recent handle's datum type

```rust
enum Datum {
    CIP68 {
        nft: Map[String]Data
        version: Int
        extra: Data
    }
}

enum Datum {
    CIP68 {
        // It is Map[String]Data
        nft: {
            name: ByteArray,
            image: ByteArray, // ipfs image
            mediaType: ByteArray, // "image/jpeg"
            og: Int, // boolean
            og_number: Int,
            rarity: ByteArray, // "basic" | "common" | "rare" | "ultraRare",
            length: Int, // Handle length
            characters: ByteArray, // "letters" | "numbers" | "special" - combined with "," when multiple
            numeric_modifiers: ByteArray, // "negative" | "decimal" - combined with "," when multiple
            handle_type: ByteArray, // "handle" | "nft_subhandle" | "virtual_subhandle"
            version: Int, // 1

        },
        version: Int, // 1
        // It is Data
        extra: {
            resolved_addresses: {
                ada?: ByteArray,
                eth?: ByteArray,
                btc?: ByteArray,
            },
            // []ByteArray
            bg_image: []Bytearray | ByteArray, // ipfs image
            pfp_image: []Bytearray | ByteArray, // ipfs image
            portal: ByteArray, // ipfs file
            designer: ByteArray, // ipfs file
            socials: ByteArray, // ipfs file
            vendor: ByteArray,
            default: Int,
            standard_image: ByteArray, // ipfs image
            last_update_address: ByteArray, // address hex format
            validated_by: ByteArray, // pub key hash
            image_hash: ByteArray,
            standard_image_hash: ByteArray,
            svg_version: ByteArray, // "3.0.8" to hex format
            agreed_terms: ByteArray, // url
            migrate_sig_required: Int, // boolean
            trial: Int, // boolean
            nsfw: Int, // boolean
            pz_enabled: Int, // boolean
            last_edited_time: Int,
            bg_asset: ByteArray, // asset id
            pfp_asset: ByteArray, // asset id
        }
    }
}
```

## Data Structures

We use [aiken-lang MPF](https://github.com/aiken-lang/merkle-patricia-forestry) which is key-value store to handle billions of entries.

### Approvers MPF

We have `BG Approvers MPF` and `PFP Approvers MPF` to verify allowed NFT Policy IDs for Handle's Background Profile picture.

- `Key`: Policy Id

- `Value`: `Assets Flags MPF` `root_hash`

### Assets Flags MPF

We have `Assets Flags MPF` for some Policy Ids (for either `BG` or `PFP`) to verify some assets which are `NSFW` (not safe for work) or `Trial`.

- `Key`: Asset Name

  > NOTE: Asset Name include asset name label.

- `Value`: CBOR Hex of 2 integers.

```rust
// `nsfw` and `trial`
// 1 -> True, 0 -> False, _ -> fail
type AssetFlags = (Int, Int)
```

## Validations

**Common Rule**

- Spending UTxO must be only one UTxO in transaction inputs which has either `100 - Reference Token` or `000 - Virtual Subhandle`.

### PERSONALIZE

**0. `Common Checks`**

- Spending UTxO must be from `valid_contracts` from `PzSettings`.

- there will be `ref_output` (output at `ref_output_index`) which has either `100 - Reference Token` or `000 - Virtual Subhandle` with updated datum.

- `ref_output` must be from `valid_contracts` from `PzSettings`.

- there will be `user_output` (output at `user_output_index`) which has `222 - User Token` and `BG Asset` and `PFP Asset` (if they are set)

  > NOTE: there can be no `user_output` in case of `Virtual Subhandle` with no `BG Asset` and `PFP Asset`.

- there can be `treasury_output` (output at `treasury_output_index`) and `root_handle_payment_output` (output at `root_handle_payment_output`).

- transaction must be signed by `new_extra` -> `validated_by`, if that is set.

- `new_nft` must be valid. (`CIP68Datum`'s nft field)

  - check immutable fields.

    the fields other than `image` and `mediaType` must be same as the ones from `old_nft`.

- `new_extra` must be valid. (`CIP68Datum`'s extra field)

  - check `bg_image` and `bg_asset`.

    - `bg_image` must be set when `bg_asset` is set.

    - `bg_image` must be same as `bg_asset`'s datum's image field (`bg_asset`'s datum must be in [CIP68](https://cips.cardano.org/cip/CIP-68) Format)

    - `bg_asset`'s policy ID must be listed in `BG Approvers MPF`.

    - personalized_output

  - check `pfp_image` and `pfp_asset`.

    Do same check as `bg_image` and `bg_asset`.

  - check `nsfw` and `trial`.

    - `nsfw` must be set to `1` if either `bg_asset` or `pfp_asset` is `nfsw`.

      check `Assets Flags MPF` for `bg_asset`

    - `trial` must be set to `1` if either `bg_asset` or `pfp_asset` is `trial`.

      check `Assets Flags MPF` for `bg_asset`

  - check immutable fields.

    `standard_image`, `standard_image_hash`, `original_address` must be same as the ones from `old_extra`.

  - check `last_edited_time` must be bigger than transaction's validity range's low bound.

  - `agreed_terms` must be same as `"https://handle.me/$/tou"`.

- Check `designer` settings. This is `datum` -> `extra` -> `designer`.

  - either `new_designer` is not None and `new_designer` === `old_designer`

  - otherwise

    - check `BG Asset`'s required asset in `default`. `default` is `bg_datum` -> `extra` as `Pairs<Data, Data>`.

      - transaction must be signed by `default` -> `required_signature`. (if it is set)

      - check `default` -> `require_asset_collections` - `List<ByteArray>`. (if it is set) For any of those asset

        - `user_output` must have that asset.

        - check `default` -> `require_asset_attributes` - `List<ByteArray>`. (if it is set) This is List of ByteArray which looks like `"key:value"` in utf8 format.

          - either `required_asset` (from `requried_asset_collections`) is CIP25. (asset name not starts with Asset Name Label 222 nor 444)

          - or get `required_asset`'s datum (from reference inputs) and retrieve `attributes` of from Datum (either `datum` -> `nft` -> `attributes` or `datum` -> `nft`) and for all `required_attribute` - `"key:value"`

            - `attributes` must have `key` which is starting part of `required_attribute` with the `value` which is ending part of `required_attribute`.

        - check `default` -> `require_asset_displayed`. If it is set, expect `Int` Data and parse it to Bool. Else consider it as False

          - either `required_asset_displayed` is False

          - if `required_asset_displayed` is True

            - either `PFP Asset` must be set and `PFF Asset Name` must be `requried_asset`

            - or `required_asset` is Handle whose asset name is same as the asset which is being personalized. HANDLE_POLICY_ID + LBL_222 + handle_name == `required_asset`

    - check fees are paid correctly.

      - check grace period. If transaction starts before `last_edited_time + grace_period`, don't charge fee. `grace_period` is from `PzSettings`.

      - payment credential of `treasury_output`'s address must be `treasury_cred` from `PzSettings`.

      - `treasury_output` must have Inline Datum as ByteArray - Handle Name being personalized.

      - `treasury_output` must have at least `treasury_fee` from `PzSettings`.

      - check provider fee and shared fee. (if subhandle)

        - fee formula: `shared_fee = pz_min_fee / 100 * subhandle_share_percent`, `provider_fee = pz_min_fee - shared_fee`. (from `PzSettings`)

        - `treasury_output` address must be one of `pz_providers`'s Values. (from `PzSettings`)

        - `treasury_output` value must contain lovelace of `provider_fee`.

        - `treasury_output` datum must be Handle Name.

        - if Handle is Subhandle, there must be `root_handle_payment_output`.

          - `root_handle_payment_output` address must be `payment_address` from `OwnerSettings`.

          - `root_handle_payment_output` value must contain lovelace of `shared_fee`.

          - `root_handle_payment_output` datum must be Handle Name.

      - check `designer` with ipfs hash and `default`.

        > Here `designer` is `Dict<ByteArray, Data>`, not `hash` like other place.

        - check `ipfs` hash matches hash calculated from `designer` `Dict`.

        - check `forced` value which is `default` -> `force_creator_settings` as `Int` -> `Bool`.

**1. For `Handle`**

- `new_datum` -> `extra` -> `resolved_addresses` -> `ada` must be None.

- `last_update_address` must be same as `user_output` address.

**2. For `NFT_SUBHANDLE`**

- must attach `OwnerSetting` Token. This is `LBL_001` Token with root handle name.

- `new_datum` -> `extra` -> `resolved_addresses` -> `ada` must be None.

- personalization must be enabled. By matching one these conditions

  - `old_datum` -> `extra` -> `pz_enabled` must be set to `1`, OR

  - root handle allows personalization. `owner_settings` -> `nft` -> `pz_enabled` must be set to `1`.

    - when root handle allows personalization, `new_datum` -> `extra` -> `pz_enabled` must be set to `1`.

- `last_update_address` must be same as `user_output` address.

**3. For `VIRTUAL_SUBHANDLE`**

- must attach `OwnerSetting` Token. This is `LBL_001` Token with root handle name.

- personalization must be enabled. By matching one these conditions

  - `old_datum` -> `extra` -> `pz_enabled` must be set to `1`, OR

  - root handle allows personalization. `owner_settings` -> `nft` -> `pz_enabled` must be set to `1`.

    - when root handle allows personalization, `new_datum` -> `extra` -> `pz_enabled` must be set to `1`.

- transaction must be signed by `Virtual Subhandle Owner`. `old_datum` -> `extra` -> `resolved_addresses` -> `ada`.

- New `Virtual Subhandle Owner` must be same as old one.

- `Virtual Subhandle` Datum must not change. `old_virtual_datum` == `new_virtual_datum`.

  Virtual Subhandle Datum is located in `datum` -> `extra`'s first field's value.

  > NOTE: Need discussion

- `last_update_address` must be same as New `Virtual SubhandleOwner` address. `new_datum` -> `extra` -> `resolved_addresses` -> `ada`.
