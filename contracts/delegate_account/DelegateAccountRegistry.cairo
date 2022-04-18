%lang starknet

# register a delegate account which would be a local wallet, 

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_zero, assert_not_zero
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

@external
func setDelegateAccount{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(delegate_account: felt, actions_len: felt, actions: felt*):

    let (caller) = get_caller_address()
    with_attr error_message("DelegateAccountRegistry: caller and delegate account must not be zero"):
        assert_not_zero(caller * delegate_account)
    end

    let (is_caller_delegate_account) = accounts.read(caller)
    with_attr error_message("DelegateAccountRegistry: caller must not be a delegate account"):
        assert_zero(caller * delegate_account)
    end
    
    delegate_accounts.write(caller, delegate_account)
    _setAuthorizedActions(caller, delegate_account, accounts_len, actions)
    accounts.write(delegate_account, caller)
    return ()
end

@external
func removeDelegateAccount{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }():
    let (caller) = get_caller_address()

    let (delegate_account) = delegate_accounts.read(caller)
    if delegate_account == 0:
        return ()
    end

    delegate_accounts.write(caller, 0)
    accounts.write(delegate_account, 0)
    return ()
end

#
# Events
#
@event
func SetDelegateAccount(account: felt, delegate_account: felt):
end


#
# Internals
#

func _setAuthorizedActions{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(account:felt, delegate_acocunt:felt, actions_len: felt, actions: felt*):
    if actions_len == 0:
        
    end
end