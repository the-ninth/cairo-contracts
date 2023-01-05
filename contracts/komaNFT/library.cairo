// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_lt, unsigned_div_rem
from starkware.cairo.common.bool import FALSE,TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_eq, uint256_not
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

namespace KomaType {

    func air_drop_len{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (len: felt) {
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

    func set_koma_type_URI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        koma_creature_id: felt, token_uri: felt
    ) -> () {
        Koma_Type_URI.write(koma_creature_id, token_uri);
        return ();
    }

    func set_koma_type_base_URI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        base_uri_len: felt, base_uri: felt*
    ) -> () {
        Koma_Type_Base_URI_len.write(base_uri_len);
        _set_koma_type_base_URI_loop(base_uri, 1, base_uri_len);
        return ();
    }

    func _set_koma_type_base_URI_loop{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(token_uri_array: felt*, count, max) -> () {
        alloc_locals;
        if (count == max + 1) {
            return ();
        }
        let token_uri = token_uri_array[0];
        Koma_Type_Base_URI.write(count, token_uri);
        _set_koma_type_base_URI_loop(token_uri_array + 1, count + 1, max);
        return ();
    }

    func get_koma_type_base_URI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> (token_uri_len: felt, token_uri: felt*) {
        alloc_locals;
        let (local token_uri: felt*) = alloc();
        let (token_uri_len: felt) = Koma_Type_Base_URI_len.read();
        _get_koma_type_base_URI_loop(token_uri_len, token_uri, 1);
        return (token_uri_len, token_uri);
    }

    func _get_koma_type_base_URI_loop{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(max_len: felt, token_uri_array: felt*, count) -> () {
        alloc_locals;
        if (count == max_len + 1) {
            return ();
        }
        let (token_uri) = Koma_Type_Base_URI.read(count);
        assert [token_uri_array] = token_uri;
        _get_koma_type_base_URI_loop(max_len, token_uri_array=token_uri_array + 1, count=count + 1);
        return ();
    }

    func get_koma_type_URI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        koma_creature_id: felt
    ) -> (token_uri_len: felt, token_uri: felt*) {
        alloc_locals;
        let (token_uri_len: felt, token_uri: felt*) = get_koma_type_base_URI();
        let (token_uri_: felt) = Koma_Type_URI.read(koma_creature_id);
        assert [token_uri + token_uri_len] = token_uri_;
        return (token_uri_len + 1, token_uri);
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

    func check_koma_creature_id_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        koma_creature_id: felt,count
    ) -> (result: felt) {
        alloc_locals;
        if (count == 0) {
            return (result = FALSE);
        }
        let (_koma_creature_id) = Air_Drop_Type.read(count);
        if (_koma_creature_id == koma_creature_id) {
            return (result = TRUE);
        }
        
        return check_koma_creature_id_loop(koma_creature_id,count-1);
    }
}
