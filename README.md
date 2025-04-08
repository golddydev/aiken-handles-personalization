# aiken-handles-personalization

## How contracts works

The Personalization contract is used to personalize NFTs.

It has 4 redeemers

- PERSONALIZE

- MIGRATE

- REVOKE

- UPDATE

- RETURN_TO_SENDER

### Before going through Redeeemers

3 Handle types are supported:

```rust
enum HandleType {
    HANDLE
    NFT_SUBHANDLE
    VIRTUAL_SUBHANDLE
}
```

```rust
struct Handle {
    type: HandleType
    name: ByteArray
}
```

There are indices used to find PZ asset, addional information from reference inputs or input datum.

```rust
struct PzIndexes {
    pfp_approver: Int
    bg_approver: Int
    pfp_datum: Int
    bg_datum: Int
    required_asset: Int
    owner_settings: Int
    contract_output: Int
    pz_assets: Int
    provider_fee: Int
}
```

There are indices used to update virtual handles.

```rust
struct VirtIndexes {
    admin_settings: Int
    root_settings: Int
    contract_output: Int
    root_handle: Int
}
```

### Types

This is personalization settings.

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

**Redeemer**

```rust
PERSONALIZE {
    handle: Handle
    root_handle: ByteArray
    indexes: PzIndexes
    designer: Map[String]Data
    reset: Int
}
```

- Get Personalization Asset Output

If `reset` set to true find in `reference_inputs`, otherwise find in transaction outputs using `pz_asset_index` from `PzIndexes`.

- Handle Name check (redeemer and spending datum)

Get handle `name` from spending datum and match that with redeemer.

-
