use aiken/builtin
use aiken/bytearray
use aiken/transaction/credential.{
  Address, Inline, ScriptCredential, VerificationKeyCredential,
}

pub fn convert_address_from_bytearray(addr_hex: ByteArray) -> Address {
  let header = builtin.index_bytearray(addr_hex, 0)
  let payload = bytearray.drop(addr_hex, 1)

  if header == 0x0 || header == 0x1 {
    // 	PaymentKeyHash + StakeKeyHash
    expect bytearray.length(payload) == 56
    let payment_key_hash = bytearray.take(payload, 28)
    let stake_key_hash = bytearray.drop(payload, 28)
    Address {
      payment_credential: VerificationKeyCredential(payment_key_hash),
      stake_credential: Some(Inline(VerificationKeyCredential(stake_key_hash))),
    }
  } else if header == 0x10 || header == 0x11 {
    // ScriptHash + StakeKeyHash
    expect bytearray.length(payload) == 56
    let payment_key_hash = bytearray.take(payload, 28)
    let stake_key_hash = bytearray.drop(payload, 28)
    Address {
      payment_credential: ScriptCredential(payment_key_hash),
      stake_credential: Some(Inline(VerificationKeyCredential(stake_key_hash))),
    }
  } else if header == 0x20 || header == 0x21 {
    // PaymentKeyHash + ScriptHash
    expect bytearray.length(payload) == 56
    let payment_key_hash = bytearray.take(payload, 28)
    let stake_key_hash = bytearray.drop(payload, 28)
    Address {
      payment_credential: VerificationKeyCredential(payment_key_hash),
      stake_credential: Some(Inline(ScriptCredential(stake_key_hash))),
    }
  } else if header == 0x30 || header == 0x31 {
    // ScriptHash + ScriptHash
    expect bytearray.length(payload) == 56
    let payment_key_hash = bytearray.take(payload, 28)
    let stake_key_hash = bytearray.drop(payload, 28)
    Address {
      payment_credential: ScriptCredential(payment_key_hash),
      stake_credential: Some(Inline(ScriptCredential(stake_key_hash))),
    }
  } else if header == 0x60 || header == 0x61 {
    // PaymentKeyHash + ø
    expect bytearray.length(payload) == 28
    Address {
      payment_credential: VerificationKeyCredential(payload),
      stake_credential: None,
    }
  } else if header == 0x70 || header == 0x71 {
    // ScriptHash + ø
    expect bytearray.length(payload) == 28
    Address {
      payment_credential: ScriptCredential(payload),
      stake_credential: None,
    }
  } else {
    fail @"invalid address hex or pointer address"
  }
}
