%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

const ROLE_SUPER_ADMIN = 0

# permission admin keccak224('ROLE_ADMIN')
const ROLE_ADMIN = 0x9a865f51c556bd6d6cf6999ca74b4fc19ab8fb6a756db54e1e0c80b3

# permission to mint land, keccak224('ROLE_LAND_MINTER')
const ROLE_LAND_MINTER = 0x38e5770043859d87f53b82995e7d4e9b3128fff8abdd209988d3bc03

# permission to mint farmer, keccak224('ROLE_FARMER_MINTER')
const ROLE_FARMER_MINTER = 0x5ca0a20c64d420776352fb99142bf9974cb6457eed577553731b8218

# permission to mint noah, keccak224('ROLE_NOAH_MINTER')
const ROLE_NOAH_MINTER = 0x5c097e559fc5fd50a3390492f7e3fde92c8ec92c6e5bdc99175a650e

# permission to mint stone, keccak224('ROLE_STONE_MINTER')
const ROLE_STONE_MINTER = 0x1bb34cdea55bb453aae61132fb0c32ac08e64bbd354deb228ee12e6d

# permission to mint wood, keccak224('ROLE_WOOD_MINTER')
const ROLE_WOOD_MINTER = 0x87896d86891f0735a9a4c3fd07b50f5c9341eb265c1ae11de1f09031

# permission to mint tuaoi, keccak224('ROLE_TUAOI_MINTER')
const ROLE_TUAOI_MINTER = 0x52e9771b847a049399cb49c8c9feec800beb5e7fd5ff91043f1cf1f0


@storage_var
func AccessControl_role_accounts(role: felt, account: felt) -> (res: felt):
end

func AccessControl_hasRole{
        pedersen_ptr : HashBuiltin*,
        syscall_ptr : felt*, 
        range_check_ptr
    }(role: felt, account: felt) -> (res: felt):
    let (res) = AccessControl_role_accounts.read(role, account)
    return (res)
end

func AccessControl_grantRole{
        pedersen_ptr : HashBuiltin*,
        syscall_ptr : felt*, 
        range_check_ptr
    }(role: felt, account: felt):
    AccessControl_role_accounts.write(role, account, 1)
    return ()
end

#
# Guards
#

func AccessControl_only_super_admin{
        pedersen_ptr : HashBuiltin*,
        syscall_ptr : felt*, 
        range_check_ptr
    }():
    let (caller) = get_caller_address()
    let (res) = AccessControl_hasRole(ROLE_SUPER_ADMIN, caller)
    assert res = 1
    return ()
end
