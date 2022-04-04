# Combat contract

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from contracts.access.interfaces.IAccessControl import IAccessControl

const COMBAT_STATUS_NOT_EXIST = 0
const COMBAT_STATUS_WAITING = 1
const COMBAT_STATUS_PLAYING = 2
const COMBAT_STATUS_END = 3

struct Combat:
    member host_player: felt
    member guest_player: felt
    member status: felt # 0: not exist, 1: waiting, 2: playing, 3: end
end

struct CombatCarriage:
    member carriage_id: Uint256
    
end



#
# Storage
#

@storage_var
func Combat_access_contract() -> (access_contract: felt):
end

@storage_var
func combat_counter() -> (count: felt):
end

@storage_var
func combats(combat_id: felt) -> (combat: Combat):
end

@storage_var
func combat_carriage(combat_id: felt, account: felt) -> (combat_carriage: CombatCarriage):
end

#
# View
#

@view
func combatCount{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (count: felt):
    let (count) = combat_counter.read()
    return (count)
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
        access_contract: felt
    ):
    
    Combat_access_contract.write(access_contract)
    return ()
end

#
# External
#

# caller create a new combat with specified carriage
# @notice only the owner of the carriage could invoke this function
# @todo: make the carriage info hidden from L2 public starknet,
# L2 just accept a proving generated outside of L2
@external
func newCombat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(carriage_id: Uint256) -> (combat_id: felt):
    let (access_contract) = Combat_access_contract.read()
    let (carriage_contract) = IAccessControl.carriageContract(contract_address=access_contract)

    let (caller) = get_caller_address()
    let (owner) = IERC721.ownerOf(contract_address=carriage_contract, tokenId=carriage_id)
    assert caller = owner

    let (self) = get_contract_address()
    IERC721.transferFrom(contract_address=carriage_contract, from_=caller, to=self, tokenId=carriage_id)

    let (last_combat_id) = combat_counter.read()
    let combat = Combat(host_player=caller, guest_player=0, status=COMBAT_STATUS_WAITING)
    combat_counter.write(last_combat_id + 1)
    combats.write(last_combat_id + 1, combat)
    combat_carriage.write(last_combat_id + 1, caller, CombatCarriage(carriage_id=carriage_id))
    
    return (last_combat_id + 1)
end