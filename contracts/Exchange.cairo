# Exchange contract of The Ninth Game

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.ERC20.interfaces.IERC20 import IERC20

#
# Storage
#

@storage_var
func Exchange_access_contract() -> (access_contract: felt):
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        access_contract: felt,
    ):
    Exchange_access_contract.write(access_contract)
    return ()
end

# swap for 1:1
@external
func swap{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(fromToken: felt, toToken: felt, amount: Uint256):
    let (caller) = get_caller_address()
    let (self) = get_contract_address()
    let (res) = IERC20.transferFrom(contract_address=fromToken, sender=caller, recipient=self, amount=amount)
    assert res = 1
    let (res) = IERC20.transfer(contract_address=toToken, recipient=caller, amount=amount)
    assert res = 1
    return ()
end