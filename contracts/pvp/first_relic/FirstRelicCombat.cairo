%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero

from starkware.starknet.common.syscalls import get_caller_address

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import ROLE_FRCOMBAT_CREATOR
from contracts.random.IRandomProducer import IRandomProducer
from contracts.pvp.first_relic.structs import Combat, Koma, Chest, Coordinate
from contracts.pvp.first_relic.FRCombatLibrary import (
    FirstRelicCombat_new_combat,
    FirstRelicCombat_get_combat,
    FirstRelicCombat_get_combat_count,
    FirstRelicCombat_init_combat_by_random,
    FirstRelicCombat_get_chest_count,
    FirstRelicCombat_get_chests,
    FirstRelicCombat_get_chest_by_coordinate
)


const RANDOM_TYPE_COMBAT_INIT = 1

@storage_var
func access_contract() -> (access_contract: felt):
end

@storage_var
func random_request_type(request_id: felt) -> (type: felt):
end

@storage_var
func random_request_combat_init(request_id: felt) -> (combat_id: felt):
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

@view
func getCombatCount{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (count: felt):
    let (count) = FirstRelicCombat_get_combat_count()
    return (count)
end

@view
func getCombat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (combat: Combat):
    let (combat) = FirstRelicCombat_get_combat(combat_id)
    return (combat)
end

@view
func getChestCount{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (count: felt):
    let (count) = FirstRelicCombat_get_chest_count(combat_id)
    return (count)
end

@view
func getChests{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, offset: felt, length: felt) -> (data_len: felt, data: Chest*):
    let (data_len, data) = FirstRelicCombat_get_chests(combat_id, offset, length)
    return (data_len, data)
end

@view
func getChestByCoordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, coordinate: Coordinate) -> (chest: Chest):
    let (chest) = FirstRelicCombat_get_chest_by_coordinate(combat_id, coordinate)
    return (chest)
end

@external
func newCombat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (combat_id: felt):
    let (access_contract_address) = access_contract.read()
    let (caller) = get_caller_address()
    IAccessControl.onlyRole(access_contract_address, ROLE_FRCOMBAT_CREATOR, caller)
    let (combat_id) = FirstRelicCombat_new_combat()
    
    let (producer_address) = IAccessControl.randomProducerContract(contract_address=access_contract_address)
    let (request_id) = IRandomProducer.requestRandom(contract_address=producer_address)
    random_request_type.write(request_id, RANDOM_TYPE_COMBAT_INIT)
    random_request_combat_init.write(request_id, combat_id)

    # trigger random fulfill, this should be removed after switch to random oracle
    IRandomProducer.triggerFulfill(producer_address, request_id)

    return (combat_id)
end

@external
func fulfillRandom{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(request_id: felt, random: felt):
    let (caller) = get_caller_address()
    let (access_contract_address) = access_contract.read()
    let (producer_address) = IAccessControl.randomProducerContract(contract_address=access_contract_address)

    with_attr error_message("FirstRelicCombat: random fulfill invalid producer"):
        assert caller = producer_address
    end
    let (type) = random_request_type.read(request_id)
    with_attr error_message("FirstRelicCombat: random request type missed"):
        assert_not_zero(type)
    end

    if type==RANDOM_TYPE_COMBAT_INIT:
        let (combat_id) = random_request_combat_init.read(request_id)
        FirstRelicCombat_init_combat_by_random(combat_id, random)
        return ()
    end

    return ()

end
