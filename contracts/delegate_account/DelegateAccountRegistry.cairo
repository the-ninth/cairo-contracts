%lang starknet

# register a delegate account which would be a local wallet, 

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bitwise import bitwise_and
from starkware.starknet.common.syscalls import get_caller_address

@storage_var
func access_contract() -> (access_contract: felt):
end

@storage_var
func delegate_accounts(account: felt) -> (delegate_account: felt):
end

@storage_var
func accounts(delegate_account: felt) -> (account: felt):
end

@storage_var
func delegate_account_authorized_actions_len(account: felt, delegate_account: felt) -> (len: felt):
end

@storage_var
func delegate_account_authorized_action_by_index(account: felt, delegate_account: felt, index: felt) -> (action: felt):
end

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        access_contract_: felt,
    ):
    access_contract.write(access_contract_)
    return ()
end

@view
func getDelegateAccount{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(account: felt) -> (delegate_account: felt):
    let (delegate_account) = delegate_accounts.read(account)
    return (delegate_account)
end

@view
func getAccount{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(delegate_account: felt) -> (account: felt):
    let (account) = accounts.read(delegate_account)
    return (account)
end

@view
func authorized{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(account: felt, delegate_account: felt, action: felt) -> (res: felt):
    let (actions_len) = delegate_account_authorized_actions_len.read(account, delegate_account)
    let (res) = _checkAuthorized(account, delegate_account, action, 0, actions_len)
    return (res)
end

@external
func setDelegateAccount{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(delegate_account: felt, actions_len: felt, actions: felt*):
    alloc_locals

    let (caller) = get_caller_address()
    with_attr error_message("DelegateAccountRegistry: caller and delegate account must not be zero"):
        assert_not_zero(caller * delegate_account)
    end

    let (is_caller_delegate_account) = accounts.read(caller)
    with_attr error_message("DelegateAccountRegistry: caller must not be a delegate account"):
        assert is_caller_delegate_account = 0
    end
    
    delegate_accounts.write(caller, delegate_account)
    accounts.write(delegate_account, caller)
    delegate_account_authorized_actions_len.write(caller, delegate_account, actions_len)
    _setAuthorizedActions(caller, delegate_account, 0, actions_len, actions)

    SetDelegateAccount.emit(caller, delegate_account)
    return ()
end

@external
func removeDelegateAccount{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }():
    alloc_locals

    let (caller) = get_caller_address()

    let (delegate_account) = delegate_accounts.read(caller)
    if delegate_account == 0:
        return ()
    end

    delegate_accounts.write(caller, 0)
    accounts.write(delegate_account, 0)
    delegate_account_authorized_actions_len.write(caller, delegate_account, 0)

    RemoveDelegateAccount.emit(caller, delegate_account)
    return ()
end

#
# Internals
#

func _setAuthorizedActions{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(account:felt, delegate_account:felt, index: felt, actions_len: felt, actions: felt*):
    if actions_len == 0:
        return ()
    end

    delegate_account_authorized_action_by_index.write(account, delegate_account, index, actions[0])
    _setAuthorizedActions(account, delegate_account, index + 1, actions_len - 1, actions + 1)
    return ()
end

func _checkAuthorized{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(account: felt, delegate_account: felt, action: felt, index: felt, actions_len: felt) -> (res: felt):
    if actions_len == 0:
        return (res = 0)
    end
    let (action_authorized) = delegate_account_authorized_action_by_index.read(account, delegate_account, index)
    if action_authorized == action:
        return (res = 1)
    end
    let (res) = _checkAuthorized(account, delegate_account, action, index + 1, actions_len - 1)
    return (res)
end

#
# Events
#
@event
func SetDelegateAccount(account: felt, delegate_account: felt):
end

@event
func RemoveDelegateAccount(account: felt, delegate_account: felt):
end


