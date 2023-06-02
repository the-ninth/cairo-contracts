%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_lt
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.starknet.common.syscalls import get_caller_address, get_block_number
from contracts.token.interfaces.IMintable import IMintable

@storage_var
func signer_pub_key() -> (pub_key: felt) {
}

@storage_var
func noah_address() -> (address: felt) {
}

@storage_var
func account_claimed(account: felt) -> (amount: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _signer_pub_key: felt, _noah_address: felt
) {
    signer_pub_key.write(_signer_pub_key);
    noah_address.write(_noah_address);
    return ();
}

@external
func claim{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(amount: felt, signature_len: felt, signature: felt*) {
    let (caller) = get_caller_address();
    let (_account_claimed) = account_claimed.read(caller);
    with_attr error_message("account already claimed") {
        assert _account_claimed = 0;
    }
    assert_lt(0, amount);

    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(caller, amount);

    let (is_valid) = is_valid_signature(amount_hash, signature_len, signature);
    with_attr error_message("invalid signature") {
        assert is_valid = TRUE;
    }
    let (caller) = get_caller_address();
    let (_noah_address) = noah_address.read();
    let amount_uint256 = Uint256(amount, 0);
    IMintable.mint(contract_address=_noah_address, to=caller, amount=amount_uint256);
    account_claimed.write(caller, amount);
    return ();
}

@view
func get_account_claimed{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(account: felt) -> (amount: felt) {
    let (amount) = account_claimed.read(account);
    return (amount,);
}

func is_valid_signature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(hash: felt, signature_len: felt, signature: felt*) -> (is_valid: felt) {
    let (_public_key) = signer_pub_key.read();

    // This interface expects a signature pointer and length to make
    // no assumption about signature validation schemes.
    // But this implementation does, and it expects a (sig_r, sig_s) pair.
    let sig_r = signature[0];
    let sig_s = signature[1];

    verify_ecdsa_signature(
        message=hash, public_key=_public_key, signature_r=sig_r, signature_s=sig_s
    );

    return (is_valid=TRUE);
}
