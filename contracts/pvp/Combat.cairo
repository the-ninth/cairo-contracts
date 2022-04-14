# Combat contract

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_block_timestamp

from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.util.random import get_random_number

const COMBAT_STATUS_NOT_EXIST = 0
const COMBAT_STATUS_WAITING = 1
const COMBAT_STATUS_PLAYING = 2
const COMBAT_STATUS_END = 3

const RECT_SIZE = 200

struct Combat:
    member host_player: felt
    member host_carriage_id: Uint256
    member guest_player: felt
    member guest_carriage_id: Uint256
    member status: felt # 0: not exist, 1: waiting, 2: playing, 3: end
end

struct Location:
    member x: felt
    member y: felt
end

struct CombatCarriage:
    member combat_id: felt
    member location: Location
end

struct Node:
    member carriage_id: Uint256
    member carriage_soldier_index: felt
    member is_head: felt
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
func combat_carriage(carriage_id: Uint256) -> (combat_carriage: CombatCarriage):
end

@storage_var
func combat_carriage_nodes_location_len(carriage_id: Uint256) -> (len: felt):
end

@storage_var
func combat_carrage_nodes_location_by_index(carriage_id: Uint256) -> (location: Location):
end

# todo: remove node location storage, instead, use a proving
@storage_var
func combat_nodes_by_location(location: Location) -> (node: Node):
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
    alloc_locals

    let (access_contract) = Combat_access_contract.read()
    let (carriage_contract) = IAccessControl.carriageContract(contract_address=access_contract)

    let (caller) = get_caller_address()
    let (owner) = IERC721.ownerOf(contract_address=carriage_contract, tokenId=carriage_id)
    assert caller = owner

    let (self) = get_contract_address()
    IERC721.transferFrom(contract_address=carriage_contract, from_=caller, to=self, tokenId=carriage_id)

    let (last_combat_id) = combat_counter.read()
    tempvar next_combat_id = last_combat_id + 1
    let combat = Combat(host_player=caller, host_carriage_id=carriage_id, guest_player=0, guest_carriage_id=Uint256(0,0), status=COMBAT_STATUS_WAITING)
    combat_counter.write(next_combat_id)
    combats.write(next_combat_id, combat)

    let (carriage_location, step) = _get_random_location(0)
    combat_carriage.write(carriage_id, CombatCarriage(combat_id=next_combat_id, location=carriage_location))
    combat_nodes_by_location.write(carriage_location, Node(carriage_id=carriage_id, carriage_soldier_index=0, is_head=1))

    
    return (next_combat_id)
end

func _get_random_location{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(step: felt) -> (location: Location, step: felt):
    alloc_locals

    let (block_timestamp) = get_block_timestamp()
    let (x) = get_random_number(block_timestamp, step, RECT_SIZE)
    let (y) = get_random_number(block_timestamp, step + 1, RECT_SIZE)
    tempvar location = Location(x=x, y=y)

    let (node) = combat_nodes_by_location.read(location)
    let (is_zero) = uint256_eq(node.carriage_id, Uint256(0,0))
    if is_zero != 0:
        let (location, step) = _get_random_location(step + 2)
        return (location, step)
    end
    return (location, step)

end