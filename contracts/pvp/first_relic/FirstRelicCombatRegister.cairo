%lang starknet

# combat register for first relic combat

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.ERC20.interfaces.IERC20 import IERC20

from contracts.access.interfaces.IAccessControl import IAccessControl


const REGISTER_FEE = 5000000000000000000 # charged in NINTH

@storage_var
func access_contract() -> (access_contract: felt):
end

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        access_contract_: felt
    ):
    access_contract.write(access_contract_)
    return ()
end

func register{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    let (caller) = get_caller_address()
    let (self) = get_contract_address()
    let (access_contract_address) = access_contract.read()
    let (ninth_contract_address) = IAccessControl.ninthContract(contract_address=access_contract_address)
    let (res) = IERC20.transferFrom(contract_address=ninth_contract_address, sender=caller, recipient=self, amount=Uint256(REGISTER_FEE, 0))
    # todo: add registration
    return ()
end

func getTotalNinthRewards{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (rewards: Uint256):
    # todo: calculate total rewards from register fee
    return (Uint256(0, 0))
end

func distributeNinthRewards{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    # todo: distribute NINTH rewards from register fee
    return ()
end

