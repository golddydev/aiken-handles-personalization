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

## PERSONALIZE Redeemer Analysis

### Redeemer Structure

```rust
PERSONALIZE { 
    handle: Handle              // Handle info (type and name)
    root_handle: ByteArray      // Root handle name for subhandles
    indexes: PzIndexes          // Reference input/output indexes
    designer: Map[String]Data   // Designer settings for personalization
    reset: Int                  // Flag indicating if this is a reset operation (0 or 1)
}
```

### Handle Types and Processing

The contract processes three different handle types with specific validation rules:

#### 1. **HANDLE** (Normal Handle)
- Uses `LBL_100` (Reference Token)
- Address comes from the asset output
- `resolved_addresses.ada` must be None (cannot contain ada resolution)
- `last_update_address` must match the asset output address
- No root handle settings validation required

#### 2. **NFT_SUBHANDLE** 
- Uses `LBL_100` (Reference Token)  
- Must end with `@{root_handle}` format
- Requires `OwnerSettings` token (`LBL_001` + root_handle name)
- `resolved_addresses.ada` must be None
- Personalization must be enabled either:
  - At handle level: `old_datum.extra.pz_enabled == 1`, OR
  - At root level: `owner_settings.nft.pz_enabled == 1`
- When root allows personalization: `new_datum.extra.pz_enabled` must be set to `1`
- `last_update_address` must match the asset output address

#### 3. **VIRTUAL_SUBHANDLE**
- Uses `LBL_000` (Virtual Subhandle)
- Must end with `@{root_handle}` format  
- Requires `OwnerSettings` token (`LBL_001` + root_handle name)
- Must be signed by current Virtual Subhandle owner (`old_datum.extra.resolved_addresses.ada`)
- New owner address must match old owner address (cannot change ownership)
- Virtual Subhandle datum must not change (`old_virtual_datum == new_virtual_datum`)
- Personalization must be enabled (same rules as NFT_SUBHANDLE)
- `last_update_address` must match the resolved ada address

### Core Validation Logic

#### 1. **Asset Validation**
- **Background Asset (`bg_asset`)**: Must be approved in BG Approvers MPF
- **Profile Picture Asset (`pfp_asset`)**: Must be approved in PFP Approvers MPF  
- **Asset-Image Consistency**: `bg_image` must match `bg_asset`'s datum image field
- **NSFW/Trial Flags**: Automatically set based on asset flags from MPF lookups

#### 2. **Designer Settings Validation**
When designer settings are provided (`designer` map is not empty):
- Settings must match IPFS CID multihash validation
- Creator-defined constraints must be respected (forced vs optional settings)
- Bounds checking for numeric properties (font_shadow_size, pfp_zoom, pfp_offset)
- Color palette restrictions based on creator defaults
- QR code style validations

#### 3. **Fee Payment Validation**
Fees are required unless within grace period:
- **Treasury Fee**: Paid to treasury address with handle name as datum
- **Provider Fee**: Paid to approved personalization provider
- **Subhandle Share**: Additional fee for subhandles paid to root handle owner
- **Grace Period**: No fees required if within `grace_period` after `last_edited_time`

#### 4. **Required Asset Collections**
Creators can specify required asset collections that must be held:
- Collection policy ID and name prefix matching
- Attribute requirements for CIP-68 assets  
- Asset display requirements (must be shown as pfp/bg or be the handle itself)
- Required signature validation for restricted backgrounds

#### 5. **Immutable Field Protection**
Certain fields cannot be changed during personalization:
- `standard_image` and `standard_image_hash`
- `original_address` 
- All NFT metadata except `image` and `mediaType`
- `agreed_terms` must be set to canonical ToU URL

### Validation Flow Summary

1. **Load PZ Settings** from reference input with `pz_settings` handle
2. **Validate Handle Type** and extract appropriate address/label
3. **Check Personalization Permissions** (enabled at handle or root level)
4. **Load Approver Data** from MPF reference inputs for bg/pfp assets
5. **Validate Asset Approvals** against MPF data and set NSFW/trial flags
6. **Verify Designer Settings** against creator constraints and bounds
7. **Validate Required Assets** if creator specified collection requirements
8. **Check Fee Payments** (treasury, provider, subhandle share)
9. **Ensure Immutables Unchanged** and contract output validity
10. **Confirm Proper Signatures** (validated_by, required signatures, etc.)

### Key Constants

```rust
const HANDLE_HASH: ByteArray = #f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a
const LBL_444: ByteArray = #001bc280  // CIP-68 (444) label
const LBL_222: ByteArray = #000de140  // User token (222) label  
const LBL_100: ByteArray = #000643b0  // Reference token (100) label
const LBL_001: ByteArray = #00001070  // Owner settings (001) label
const LBL_000: ByteArray = #00000000  // Virtual subhandle (000) label
```

## Types

### Personalization Settings

This is loaded from reference input, which contains `pz_settings` handle.

Reference Input address must be same as `pz_settings.settings_cred` validator address.

```rust
struct PzSettings {
    treasury_fee: Int
    treasury_cred: ByteArray
    pz_min_fee: Int
    pz_providers: Map[ByteArray]ByteArray
    valid_contracts: []ByteArray
    admin_creds: []ByteArray
    settings_cred: ByteArray
    grace_period: Int
    subhandle_share_percent: Int
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

**1. For `Handle`**

- second output must be `user_output` with `222 - User Token`.

- `new_datum` -> `extra` -> `resolved_addresses` -> `ada` must be None.

- `last_update_address` must be same as `user_output` address.

**2. For `NFT_SUBHANDLE`**

- must attach `OwnerSetting` Token. This is `LBL_001` Token with root handle name.

- second output must be `user_output` with `222 - User Token`.

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
