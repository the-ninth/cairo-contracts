%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import sign
from starkware.cairo.common.bool import FALSE, TRUE

from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.pvp.first_relic.structs import (
    Combat,
    Coordinate,
    Ore,
    Koma,
    KomaMiningOre,
    COMBAT_STATUS_PREPARING,
    COMBAT_STATUS_FIRST_STAGE
)
from contracts.pvp.first_relic.constants import WORKER_MINING_SPEED
from contracts.pvp.first_relic.storages import (
    FirstRelicCombat_combats,
    FirstRelicCombat_ores,
    FirstRelicCombat_komas,
    FirstRelicCombat_koma_mining_ore_coordinates_len,
    FirstRelicCombat_koma_mining_ore_coordinates_by_index,
    FirstRelicCombat_koma_mining_ores
)
from contracts.pvp.first_relic.FRCombatLibrary import (
    FirstRelicCombat_change_to_first_stage,
    FirstRelicCombat_change_to_second_stage
)
from contracts.util.math import min


func LazyUpdate_update_combat_status{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    alloc_locals

    let (combat) = FirstRelicCombat_combats.read(combat_id)
    local status_changed
    if combat.status == COMBAT_STATUS_PREPARING:
        let (res) = _update_combat_status_preparing(combat_id, combat)
        status_changed = res
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    if combat.status == COMBAT_STATUS_FIRST_STAGE:
        let (res) = _update_combat_status_first_stage(combat_id, combat)
        status_changed = res
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    
    # update until combat status no change
    if status_changed == TRUE:
        LazyUpdate_update_combat_status(combat_id)
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
    }(combat_id: felt, combat: Combat) -> (status_changed: felt):
    alloc_locals

    let (block_timestamp) = get_block_timestamp()
    let (time_passed) = sign(block_timestamp - combat.first_stage_time)
    if time_passed != -1:
        # change to first stage
        FirstRelicCombat_change_to_first_stage(combat_id)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        return (TRUE)
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        return (FALSE)
    end
    
end

func _update_combat_status_first_stage{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, combat: Combat) -> (status_changed: felt):
    alloc_locals

    let (block_timestamp) = get_block_timestamp()
    let (time_passed) = sign(block_timestamp - combat.second_stage_time)
    if time_passed != -1:
        # change to first stage
        FirstRelicCombat_change_to_second_stage(combat_id)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        return (TRUE)
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        return (FALSE)
    end

end

# update ore mined_supply
func LazyUpdate_update_ore{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, ore_coordinate: Coordinate):
    alloc_locals

    let (ore) = FirstRelicCombat_ores.read(combat_id, ore_coordinate)
    if ore.mining_workers_count == 0:
        return ()
    end
    let (block_timestamp) = get_block_timestamp()
    let (end_time) = min(block_timestamp, ore.empty_time)
    let mined_amount = (end_time - ore.start_time) * ore.mining_workers_count * WORKER_MINING_SPEED
    let new_ore = Ore(ore.coordinate, ore.total_supply, ore.mined_supply + mined_amount, ore.mining_workers_count, block_timestamp, ore.empty_time)
    FirstRelicCombat_ores.write(combat_id, ore_coordinate, new_ore)

    return ()
end

# todo: update koma mining ores and add mined amount to koma
func LazyUpdate_update_koma_mining{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt):
    alloc_locals

    let (koma) = FirstRelicCombat_komas.read(combat_id, account)
    let (mining_ore_coordinates_len) = FirstRelicCombat_koma_mining_ore_coordinates_len.read(combat_id, account)
    let (ore_amount) = _retreive_mining_ores(combat_id, account, 0, mining_ore_coordinates_len, 0)
    let koma_updated = Koma(
        koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed,
        koma.props_weight, koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count,
        koma.action_radius, koma.element, koma.ore_amount + ore_amount, koma.atk, koma.defense, koma.worker_mining_speed
    )
    FirstRelicCombat_komas.write(combat_id, account, koma_updated)

    return ()
end

func _retreive_mining_ores{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, index: felt, len: felt, retreive_amount: felt) -> (ore_amount: felt):
    alloc_locals
    
    if index == len:
        return (0)
    end
    let (mining_ore_coordinate) = FirstRelicCombat_koma_mining_ore_coordinates_by_index.read(combat_id, account, index)
    let (mining_ore) = FirstRelicCombat_koma_mining_ores.read(combat_id, account, mining_ore_coordinate)
    let (ore) = FirstRelicCombat_ores.read(combat_id, mining_ore_coordinate)

    let (block_timestamp) = get_block_timestamp()
    let (end_time) = min(block_timestamp, ore.empty_time)
    let current_retreive_amount = (end_time - mining_ore.start_time) * mining_ore.mining_workers_count * WORKER_MINING_SPEED

    let mining_ore_updated = KomaMiningOre(
        mining_ore.coordinate, mining_ore.mining_workers_count, block_timestamp
    )
    FirstRelicCombat_koma_mining_ores.write(combat_id, account, mining_ore_coordinate, mining_ore_updated)

    let (ore_amount) = _retreive_mining_ores(combat_id, account, index + 1, len, retreive_amount + current_retreive_amount)
    return (ore_amount)
end