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
  // valid handle policy ids
  policy_ids: List<PolicyId>,
  // script hash where
  // all important assets are locked
  settings_script_hash: ScriptHash,
  // valid personalization script hashes
  pz_script_hashes: List<ScriptHash>,
  // personalization provider script hashes
  provider_script_hashes: List<ScriptHash>,
  // treasury script hash
  treasury_script_hash: ScriptHash,
  // admin verification key hashes
  admin_verification_key_hashes: List<VerificationKeyHash>,
  // treasury fee
  treasury_fee: Int,
  // pz min fee
  pz_min_fee: Int,
  // grace period
  grace_period: Int,
  // subhandle share percent
  subhandle_share_percent: Int,
}
```

### OwnerSettings

This is root handle owner settings.

For all NFT Subhandles and Virtual Subhandles, there is owner settings Token.

Asset Name Label is `prefix_001` and name is Root handle name.

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

Most of Handles are following CIP68 Datum format. See [CIP68](https://cips.cardano.org/cip/CIP-68)

This is most recent handle's datum overview.

```rust
pub type CIP68Datum {
  metadata: Pairs<Data, Data>,
  version: Int,
  extra: Data, // Usually it is Pairs<Data, Data>
}

type CIP68 {
    metadata: {
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
    extra: {
        resolved_addresses: {
            ada?: ByteArray,
            eth?: ByteArray,
            btc?: ByteArray,
        },
        bg_image: ByteArray | List<Bytearray>, // ipfs image
        pfp_image: ByteArray | List<Bytearray>, // ipfs image
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
        nsfw: Int, // boolean
        trial: Int, // boolean
        pz_enabled: Int, // boolean
        last_edited_time: Int,
        bg_asset: ByteArray, // asset id
        pfp_asset: ByteArray, // asset id
    }
}
```

## Data Structures

We use [aiken-lang MPF](https://github.com/aiken-lang/merkle-patricia-forestry) which is key-value store to handle billions of entries.

This MPF is used keep Policy IDs, which are allowed to be personalized as background or pfp with Handles.

This MPF is also used to keep certain Asset IDs, which are nsfw or trial (not safe for work) to be personalized with Handles.

Here we will use type called `PzFlags`

```rust
// nsfw, trial
// 0: false, 1: true, otherwise: invalid
pub type PzFlags =
  (Int, Int)

// pz flags and merkle trie proof
// this proof is inclusion proof.
pub type PolicyIdPzFlagsProof =
  (PzFlags, mpt.Proof)

// pz flags and merkle trie proof
// when pz flags are None,
// it means to prove Non-membership of asset id.
pub type AssetIdPzFlagsProof =
  (Option<PzFlags>, mpt.Proof)

```

### Policies MPF

- `key`: policy id

- `value`: CBOR Hex of `PzFlags`

### Beta Assets MPF

- `key`: asset id

- `value`: CBOR Hex of `PzFlags`

### How to determine Asset is approved for Background or Profile Picture

- Find `PzFlags` for Asset's Policy ID from `Policies MPF`.

  If `PzFlags` are both `1`, then asset is nsfw and trial.

- Find `PzFlags` for Asset's ID from `Beta Assets MPF`.

  Combine `PzFlags` of Policy ID and `PzFlags` of Asset ID.

## Validations

### PERSONALIZE

- Spending UTxO (`pz_utxo`) must be only one UTxO in transaction inputs which has either `100 - Reference Token` or `000 - Virtual Subhandle`.

- `ref_output` must be valid. (output indexed by `ref_output_index`)

  - must have same address and same value as `pz_utxo`.

  - must NOT have reference script.

- check new datum's `metadata`.

  - must have `image` and `mediaType` field as single `ByteArray` value.

  - immutable fields (other than `image` and `mediaType`) must stay same.

- check new datum's `extra`.

  - immutable fields (`standard_image`, `standard_image_hash`, `original_address`) must stay same without key duplicate.

  - `agreed_terms` must be `"https://handle.me/$/tou"` as single value.

  - `last_edited_time` must be same as transaction validity range's lower bound as single value.

  - check `validated_by`.

    - `validated_by` must be single value or None.

  - transaction must be signed by it if it is set.

- there must be `PzItems` reference input. (input with `PzItems` assets)

  - this input must be from `settings_script_hash`.

  - Build `Polices MPF` and `Beta Assets MPF` from `PzItems` datum.

- check personlization background and retrieve background asset's PzFlags (for nsfw and trial), if background is set.

  - find `bg_image` and `bg_asset` from new datum's `extra`. Both of them must be set as single value or both must be None.

    If both are None, `PzFlags` are `(0, 0)`.

  - `bg_asset` must be valid `AssetClass` with `prefix_222` or `prefix_444`. (either User Token or RFT)

  - there must be valid background asset's on-chain datum.

    - there must be background asset's reference Token in reference inputs.

    - Datum (`bg_datum`) must be `InlineDatum` with `CIP68Datum` format.

  - `bg_image` must be same as background asset's datum's image. (`datum.metadata.image`)

  - Retrieve background asset's `PzFlags`.

    - background asset's policy id must be in `Policies MPF` with `PolicyIdPzFlagsProof`.

    - if policy id's `PzFlags` are `(1, 1)`, that is also background asset's `PzFlags`. Otherwise check asset id's `PzFlags`.

    - check background asset id against `Beta Assets MPF` with `AssetIdPzFlagsProof`.

      - if it proves non membership, asset id's `PzFlags` are `(0, 0)` otherwise value with inclusion proof.

      - combine policy id's `PzFlags` and asset id's `PzFlags`. (`flag = Math.min(1, policy id's flag + asset id's flag)`)

  > NOTE: return `bg_datum` to use it later.

- check personlization pfp and retrieve pfp asset's PzFlags (for nsfw and trial), if pfp is set.

- check asset's `PzFlags`.

  - `nsfw` and `trial` must be set in new datum's `extra` as single `Int` value.

  - `nsfw` must be 1 if either background asset's `PzFlags`'s `nsfw` or pfp asset's `PzFlags`'s `nsfw` are set. same for `trial`.

> NOTE: Check new datum is reset. (`is_new_datum_reset`)
>
> - `datum.metadata.image` == `datum.extra.standard_image`
> - `datum.metadata.image_hash` == `datum.extra.standard_image_hash`
> - `datum.extra.bg_asset` == `None` (not set)
> - `datum.extra.pfp_asset` == `None` (not set)
> - `datum.extra.bg_image` == `None` (not set)
> - `datum.extra.pfp_image` == `None` (not set)
> - `datum.extra.designer` == `None` (not set)
> - `datum.extra.nsfw` == `0`
> - `datum.extra.trial` == `0`

- check constraint settings from `BG Asset`. (`default` is `BG Asset`'s datum's extra)

  check `BG Asset`'s required constraints in `default`. `default` is `bg_datum` -> `extra` as `Pairs<Data, Data>`.

  - transaction must be signed by `default` -> `required_signature`. (if it is set)

  - check `default` -> `required_asset_collections` - `List<ByteArray>`. (if it is set) For any of those assets

    - `user_output` must have that asset.

    - check `default` -> `required_asset_attributes` - `List<ByteArray>`. (if it is set) This is List of ByteArray which looks like `"key:value"` in utf8 format.

      - either `required_asset` (from `requried_asset_collections`) is CIP25. (asset name not starts with Asset Name Label 222 nor 444)

      - or get `required_asset`'s datum (from reference inputs) and retrieve `attributes` of from Datum (either `datum` -> `nft` -> `attributes` or `datum` -> `nft`) and for all `required_attribute` (which is `"key:value"`)

        - `attributes` must have `key` with matching `value` (`value` can be either Int or ByteArray).

    - check `default` -> `required_asset_displayed`. If it is set, expect `Int` Data and parse it to Bool. Else consider it as False

      - either `required_asset_displayed` is False

      - if `required_asset_displayed` is True

        - either `PFP Asset` must be set and `PFF Asset Name` must be `required_asset`

        - or `required_asset` is Handle whose asset name is same as the asset which is being personalized. HANDLE_POLICY_ID + LBL_222 + handle_name == `required_asset`

- check `designer` with ipfs hash and `default`.

  > Here `designer` is `Pair<ByteArray, Data>` from redeemer
  > `designer` from datum's `extra` is actually designer's IPFS Hash

  - check `ipfs` hash matches hash calculated from `designer`.

  - check `forced` value which is `default` -> `force_creator_settings` as `Int` -> `Bool`.

- check fees are paid correctly.

  - either new `designer` is not None `AND` new `designer` is same as old `designer`.

  - or `is_datum_initiated`

  - otherwise DO check for fee is correctly paid.

    - check grace period. If transaction starts before `last_edited_time + grace_period`, don't charge fee. `grace_period` is from `PzSettings`.

      `last_edited_time` is old `datum.extra.last_edited_time` (can be `None`)

    - treasury fee must be paid correctly.

      - there must be `treasury_output` (output indexed by `treasury_output_index`)

      - payment credential of `treasury_output`'s address must be `treasury_cred` from `PzSettings`.

      - `treasury_output` must have Inline Datum as ByteArray - Handle Name being personalized.

      - `treasury_output` must have at least `treasury_fee` from `PzSettings`.

    - provider fee must be paid correctly.

      fee formula: `shared_fee = pz_min_fee / 100 * subhandle_share_percent`, `provider_fee = pz_min_fee - shared_fee`. (from `PzSettings`)

      - there must be `provider_fee_output` (output index by `provider_fee_output_index`)

      - payment credential of `provider_fee_output` must be one of `provider_script_hashes` from `PzSettings`.

      - `provider_fee_output` must have at least `provider_fee`.

      - `provider_fee_output` must have Inline Datum as ByteArray - Handle Name being personalized.

    - shared fee must be paid correctly. (only for Subhandle)

      fee formula: `shared_fee = pz_min_fee / 100 * subhandle_share_percent`, `provider_fee = pz_min_fee - shared_fee`. (from `PzSettings`)

      - there must be `root_handle_payment_output` (output indexed by `root_handle_payment_output_index`).

      - `root_handle_payment_output` address must be `payment_address` from `OwnerSettings`.

      - `root_handle_payment_output` must have value at least `shared_fee`.

      - `root_handle_payment_output` datum must be Handle Name.

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
