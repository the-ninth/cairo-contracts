// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_lt, unsigned_div_rem, assert_le_felt
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_eq,
    uint256_not,
    uint256_unsigned_div_rem,
)
from starkware.cairo.common.alloc import alloc

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.utils.constants.library import UINT8_MAX

@storage_var
func White_List(account: felt) -> (result: felt) {
}

@storage_var
func Operator_List(account: felt) -> (result: felt) {
}

@storage_var
func Open_Status() -> (status: felt) {
}

@storage_var
func Koma_Type_Base_URI(index: felt) -> (base_uri: felt) {
}

@storage_var
func Koma_Type_Base_URI_len() -> (base_uri_len: felt) {
}

@storage_var
func Koma_Type_URI(koma_creature_id: felt) -> (token_uri: felt) {
}

@storage_var
func Air_Drop_Type(index: felt) -> (koma_creature_id: felt) {
}

@storage_var
func Air_Drop_Len() -> (len: felt) {
}

@storage_var
func Mint_Limit() -> (len: felt) {
}

@storage_var
func Koma_koma_creature_uri_len(koma_creature_id: felt) -> (len: felt) {
}

@storage_var
func Koma_koma_creature_uri_by_index(koma_creature_id: felt, index: felt) -> (uri: felt) {
}

namespace KomaType {
    func air_drop_len{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        len: felt
    ) {
        let (len) = Air_Drop_Len.read();
        return (len=len);
    }

    func set_op{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        target_status: felt, account: felt
    ) -> () {
        Operator_List.write(account, target_status);
        return ();
    }

    func set_mint_limit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        limit: felt
    ) -> () {
        Mint_Limit.write(limit);
        return ();
    }

    func set_wl_single{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        target_status: felt, account: felt
    ) -> () {
        White_List.write(account, target_status);
        return ();
    }

    func set_wl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        target_status: felt, accounts_len: felt, accounts: felt*
    ) -> () {
        _set_wl_loop(target_status, accounts, accounts_len);
        return ();
    }

    func _set_wl_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        target_status: felt, accounts: felt*, left
    ) -> () {
        alloc_locals;
        if (left == 0) {
            return ();
        }
        let account = accounts[0];
        White_List.write(account, target_status);
        _set_wl_loop(target_status, accounts + 1, left - 1);
        return ();
    }

    func wl_status{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt
    ) -> (result: felt) {
        let (_result) = White_List.read(account);
        return (result=_result);
    }

    func mint_limit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        result: felt
    ) {
        let (_result) = Mint_Limit.read();
        return (result=_result);
    }

    func assert_wl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (caller) = get_caller_address();
        let (target_status) = White_List.read(caller);
        with_attr error_message("koma: not in wl") {
            assert_not_zero(caller);
            assert target_status = 1;
        }
        return ();
    }

    func assert_op{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (caller) = get_caller_address();
        let (target_status) = Operator_List.read(caller);
        with_attr error_message("koma: not in op") {
            assert_not_zero(caller);
            assert target_status = 1;
        }
        return ();
    }

    func assert_mintable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (is_open) = Open_Status.read();
        with_attr error_message("koma: open closed") {
            assert is_open = 1;
        }
        return ();
    }

    func is_open{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        is_open: felt
    ) {
        let (_is_open) = Open_Status.read();
        return (is_open=_is_open);
    }

    func is_operator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt
    ) -> (result: felt) {
        let (_result) = Operator_List.read(account);
        return (result=_result);
    }

    func set_open{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        target_status: felt
    ) -> () {
        Open_Status.write(target_status);
        return ();
    }

    func get_token_uri{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        token_id: Uint256
    ) -> (token_uri_len: felt, token_uri: felt*) {
        let (_, remainder) = uint256_unsigned_div_rem(token_id, Uint256(10000000, 0));
        let (len) = Koma_koma_creature_uri_len.read(remainder.low);
        let (token_uri: felt*) = alloc();
        let (token_uri_len, token_uri) = _get_tokenURI(remainder.low, 0, len, token_uri);
        return (token_uri_len, token_uri);
    }

    func set_koma_creature_uri{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        koma_creature_id: felt, token_uri_len: felt, token_uri: felt*
    ) {
        with_attr error_message("invalid length") {
            assert_le_felt(0, token_uri_len);
        }

        Koma_koma_creature_uri_len.write(koma_creature_id, token_uri_len);
        _set_tokenURI(koma_creature_id, 0, token_uri_len, token_uri);
        return ();
    }

    func get_airdrop_type_num{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        num: felt
    ) -> (koma_creature_id: felt) {
        alloc_locals;
        let (len) = Air_Drop_Len.read();
        let (_, remainder) = unsigned_div_rem(num, len);
        let (_koma_creature_id) = Air_Drop_Type.read(remainder + 1);
        return (koma_creature_id=_koma_creature_id);
    }

    func get_airdrop_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt
    ) -> (koma_creature_id: felt) {
        alloc_locals;
        let (_koma_creature_id) = Air_Drop_Type.read(index);
        return (koma_creature_id=_koma_creature_id);
    }

    func add_airdrop_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        koma_creature_id: felt
    ) -> () {
        alloc_locals;
        let (len) = Air_Drop_Len.read();
        Air_Drop_Len.write(len + 1);
        Air_Drop_Type.write(len + 1, koma_creature_id);
        return ();
    }

    func check_koma_creature_id_loop{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(koma_creature_id: felt, count) -> (result: felt) {
        alloc_locals;
        if (count == 0) {
            return (result=FALSE);
        }
        let (_koma_creature_id) = Air_Drop_Type.read(count);
        if (_koma_creature_id == koma_creature_id) {
            return (result=TRUE);
        }

        return check_koma_creature_id_loop(koma_creature_id, count - 1);
    }
}

func _get_tokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    koma_creature_id: felt, index: felt, len: felt, tokenURI: felt*
) -> (tokenURI_len: felt, tokenURI: felt*) {
    if (index == len) {
        return (index, tokenURI);
    }

    let (uri) = Koma_koma_creature_uri_by_index.read(koma_creature_id, index);
    assert tokenURI[index] = uri;
    return _get_tokenURI(koma_creature_id, index + 1, len, tokenURI);
}

func _set_tokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    koma_creature_id: felt, index: felt, len: felt, tokenURI: felt*
) -> () {
    if (index == len) {
        return ();
    }

    Koma_koma_creature_uri_by_index.write(koma_creature_id, index, tokenURI[index]);
    _set_tokenURI(koma_creature_id, index + 1, len, tokenURI);
    return ();
}
