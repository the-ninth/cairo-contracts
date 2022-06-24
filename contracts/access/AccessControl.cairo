%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.access.library import (
    AccessControl_role_accounts,
    AccessControl_hasRole,
    AccessControl_grantRole,
    AccessControl_only_super_admin,
    ROLE_SUPER_ADMIN
)

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        super_admin: felt
    ):
    AccessControl_grantRole(ROLE_SUPER_ADMIN, super_admin)
    # AccessControl_role_accounts.write(ROLE_SUPER_ADMIN, super_admin, 1)
    return ()
end

#
# Storage
#

@storage_var
func AccessControl_contract_address(contract_name: felt) -> (contract_address: felt):
end


#
# View
#

@view
func hasRole{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(role: felt, account: felt) -> (res: felt):
    let (res) = AccessControl_hasRole(role, account)
    return (res)
end

@view
func getContractAddress{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(contract_name: felt) -> (contract_address: felt):
    let (addr) = AccessControl_contract_address.read(contract_name)
    return (addr)
end

#
# external
#

@external
func setContractAddress{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(contract_name: felt, contract_address: felt):
    AccessControl_only_super_admin()
    AccessControl_contract_address.write(contract_name, contract_address)
    return ()
end

@external
func grantRole{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(role: felt, account: felt):
    AccessControl_only_super_admin()
    AccessControl_grantRole(role, account)
    return ()
end

@external
func onlyRole{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(role: felt, account: felt):
    let (res) = AccessControl_hasRole(role, account)
    assert res = 1
    return ()
end