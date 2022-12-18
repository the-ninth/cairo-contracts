%lang starknet

// register a delegate account which would be a local wallet,

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bitwise import bitwise_and
from starkware.starknet.common.syscalls import get_caller_address

@storage_var
func access_contract() -> (access_contract: felt) {
}

@storage_var
func delegate_accounts(account: felt) -> (delegate_account: felt) {
}

@storage_var
func accounts(delegate_account: felt) -> (account: felt) {
}

@storage_var
func delegate_account_authorized_actions_len(account: felt, delegate_account: felt) -> (len: felt) {
}

@storage_var
func delegate_account_authorized_action_by_index(
    account: felt, delegate_account: felt, index: felt
) -> (action: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    access_contract_: felt
) {
    access_contract.write(access_contract_);
    return ();
}

@view
func getDelegateAccount{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    account: felt
) -> (delegate_account: felt) {
    let (delegate_account) = delegate_accounts.read(account);
    return (delegate_account,);
}

@view
func getAccount{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    delegate_account: felt
) -> (account: felt) {
    let (account) = accounts.read(delegate_account);
    return (account,);
}

@view
func authorized{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    account: felt, delegate_account: felt, action: felt
) -> (res: felt) {
    let (actions_len) = delegate_account_authorized_actions_len.read(account, delegate_account);
    let (res) = _checkAuthorized(account, delegate_account, action, 0, actions_len);
    return (res,);
}

@external
func setDelegateAccount{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    delegate_account: felt, actions_len: felt, actions: felt*
) {
    alloc_locals;

    let (caller) = get_caller_address();
    with_attr error_message(
            "DelegateAccountRegistry: caller and delegate account must not be zero") {
        assert_not_zero(caller * delegate_account);
    }

    let (is_caller_delegate_account) = accounts.read(caller);
    with_attr error_message("DelegateAccountRegistry: caller must not be a delegate account") {
        assert is_caller_delegate_account = 0;
    }

    delegate_accounts.write(caller, delegate_account);
    accounts.write(delegate_account, caller);
    delegate_account_authorized_actions_len.write(caller, delegate_account, actions_len);
    _setAuthorizedActions(caller, delegate_account, 0, actions_len, actions);

    SetDelegateAccount.emit(caller, delegate_account);
    return ();
}

@external
func removeDelegateAccount{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    let (caller) = get_caller_address();

    let (delegate_account) = delegate_accounts.read(caller);
    if (delegate_account == 0) {
        return ();
    }

    delegate_accounts.write(caller, 0);
    accounts.write(delegate_account, 0);
    delegate_account_authorized_actions_len.write(caller, delegate_account, 0);

    RemoveDelegateAccount.emit(caller, delegate_account);
    return ();
}

//
// Internals
//

func _setAuthorizedActions{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    account: felt, delegate_account: felt, index: felt, actions_len: felt, actions: felt*
) {
    if (actions_len == 0) {
        return ();
    }

    delegate_account_authorized_action_by_index.write(account, delegate_account, index, actions[0]);
    _setAuthorizedActions(account, delegate_account, index + 1, actions_len - 1, actions + 1);
    return ();
}

func _checkAuthorized{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    account: felt, delegate_account: felt, action: felt, index: felt, actions_len: felt
) -> (res: felt) {
    if (actions_len == 0) {
        return (res=0);
    }
    let (action_authorized) = delegate_account_authorized_action_by_index.read(
        account, delegate_account, index
    );
    if (action_authorized == action) {
        return (res=1);
    }
    let (res) = _checkAuthorized(account, delegate_account, action, index + 1, actions_len - 1);
    return (res,);
}

//
// Events
//
@event
func SetDelegateAccount(account: felt, delegate_account: felt) {
}

@event
func RemoveDelegateAccount(account: felt, delegate_account: felt) {
}
