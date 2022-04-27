%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import sign

from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.pvp.first_relic.structs import Combat, Coordinate, Ore, COMBAT_STATUS_PREPARING
from contracts.pvp.first_relic.constants import WORKER_MINING_SPEED
from contracts.pvp.first_relic.storages import combats, ores
from contracts.pvp.first_relic.FRCombatLibrary import FirstRelicCombat_change_to_first_stage
from contracts.util.math import min


func LazyUpdate_update_combat_status{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    alloc_locals

    let (combat) = combats.read(combat_id)
    if combat.status == COMBAT_STATUS_PREPARING:
        _update_combat_status_preparing(combat_id, combat)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    return ()
end

func _update_combat_status_preparing{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, combat: Combat):
    alloc_locals

    let (block_timestamp) = get_block_timestamp()
    let (time_passed) = sign(block_timestamp - combat.first_stage_time)
    if time_passed == 1:
        # change to first stage
        FirstRelicCombat_change_to_first_stage(combat_id)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    return ()
end

# update ore mined_supply
func LazyUpdate_update_ore{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, ore_coordinate: Coordinate):
    alloc_locals

    let (ore) = ores.read(combat_id, ore_coordinate)
    if ore.mining_workers_count == 0:
        return ()
    end
    let (block_timestamp) = get_block_timestamp()
    let (end_time) = min(block_timestamp, ore.empty_time)
    let mined_amount = (end_time - ore.start_time) * ore.mining_workers_count * WORKER_MINING_SPEED
    let new_ore = Ore(ore.total_supply, ore.mined_supply + mined_amount, ore.mining_workers_count, block_timestamp, ore.empty_time)
    ores.write(combat_id, ore_coordinate, new_ore)

    return ()
end

# todo: update koma mining ores
func LazyUpdate_update_koma_mining{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt):
end
