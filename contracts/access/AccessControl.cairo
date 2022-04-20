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
func AccessControl_noah_contract() -> (res: felt):
end

@storage_var
func AccessControl_ninth_contract() -> (res: felt):
end

@storage_var
func AccessControl_stone_contract() -> (res: felt):
end

@storage_var
func AccessControl_farmer_contract() -> (res: felt):
end

@storage_var
func AccessControl_land_contract() -> (res: felt):
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
func noahContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (contract: felt):
    let (addr) = AccessControl_noah_contract.read()
    return (addr)
end

@view
func ninthContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (contract: felt):
    let (addr) = AccessControl_ninth_contract.read()
    return (addr)
end

@view
func stoneContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (contract: felt):
    let (addr) = AccessControl_stone_contract.read()
    return (addr)
end

@view
func farmerContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (contract: felt):
    let (addr) = AccessControl_farmer_contract.read()
    return (addr)
end

@view
func landContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (contract: felt):
    let (addr) = AccessControl_land_contract.read()
    return (addr)
end


#
# external
#

@external
func setNoahContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(contract: felt):
    AccessControl_only_super_admin()
    AccessControl_noah_contract.write(contract)
    return ()
end

@external
func setNinthContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(contract: felt):
    AccessControl_only_super_admin()
    AccessControl_ninth_contract.write(contract)
    return ()
end

@external
func setStoneContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(contract: felt):
    AccessControl_only_super_admin()
    AccessControl_stone_contract.write(contract)
    return ()
end

@external
func setFarmerContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(contract: felt):
    AccessControl_only_super_admin()
    AccessControl_farmer_contract.write(contract)
    return ()
end

@external
func setLandContract{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(contract: felt):
    AccessControl_only_super_admin()
    AccessControl_land_contract.write(contract)
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