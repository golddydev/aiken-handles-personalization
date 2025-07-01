# aiken-handles-personalization

## Smart Contract Overview

The Personalization contract is used to personalize Ada Handle NFTs.

This smart contract holds asset name label of `100 - Reference token` and `000 - Virtual Subhandle`.

## Handles

There are 3 types of handles.

- **Handle**: The normal handle without `@` symbol in its name. (E.g. `papag00se`, `bigirishlion`, `golddy`)

- **SubHandle**: The sub handle with `@` in its name. (E.g. `papag00se@kora`, `bigirishlion@kora`, `golddy@kora`)

  > NOTE: `kora` handle must exist.

### Types

#### Personalization Settings

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

#### OwnerSettings

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

#### CIP68 Datum

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

### PERSONALIZE

The PERSONALIZE redeemer is used to personalize an NFT.

#### Validations

**Common Rule**

- There must be only one UTxO from transaction inputs which has either `100 - Reference Token` or `000 - Virtual Subhandle`.

- First output must be `personalized_output` which has either `100 - Reference Token` or `000 - Virtual Subhandle` with updated datum. (Except when user revokes Virtual Subhandle)

**Personalize**

1. For `Handle`

- second output must be output with `222 - User Token`.

- `new_datum` -> `extra` -> `resolved_addresses` -> `ada` must be None.

2. For `NFT_SUBHANDLE`

- must attach `OwnerSetting` Token. This is `LBL_001` Token with root handle name.

- second output must be output with `222 - User Token`.

- `new_datum` -> `extra` -> `resolved_addresses` -> `ada` must be None.

- personalization must be enabled. By matching one these conditions

  - `old_datum` -> `extra` -> `pz_enabled` must be set to `1`, OR

  - root handle allows personalization. `owner_settings` -> `nft` -> `pz_enabled` must be set to `1`.

    - when root handle allows personalization, `new_datum` -> `extra` -> `pz_enabled` must be set to `1`.

3. For `VIRTUAL_SUBHANDLE`

- must attach `OwnerSetting` Token. This is `LBL_001` Token with root handle name.

- personalization must be enabled. By matching one these conditions

  - `old_datum` -> `extra` -> `pz_enabled` must be set to `1`, OR

  - root handle allows personalization. `owner_settings` -> `nft` -> `pz_enabled` must be set to `1`.

    - when root handle allows personalization, `new_datum` -> `extra` -> `pz_enabled` must be set to `1`.
