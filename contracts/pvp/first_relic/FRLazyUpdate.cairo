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
    COMBAT_STATUS_PREPARING,
    COMBAT_STATUS_FIRST_STAGE,
    COMBAT_STATUS_SECOND_STAGE
)
from contracts.pvp.first_relic.storages import (
    FirstRelicCombat_combats,
    FirstRelicCombat_ores,
    FirstRelicCombat_komas
)
from contracts.pvp.first_relic.FRCombatLibrary import (
    FirstRelicCombat_change_to_first_stage,
    FirstRelicCombat_change_to_second_stage,
    FirstRelicCombat_change_to_third_stage
)
from contracts.pvp.first_relic.FROreLibrary import OreLibrary
from contracts.util.math import min


func LazyUpdate_update_combat_status{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    alloc_locals

    let (combat) = FirstRelicCombat_combats.read(combat_id)
    let status_changed = FALSE
    if combat.status == COMBAT_STATUS_PREPARING:
        let (status_changed) = _update_combat_status_preparing(combat_id, combat)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar status_changed = status_changed
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar status_changed = status_changed
    end
    if combat.status == COMBAT_STATUS_FIRST_STAGE:
        let (status_changed) = _update_combat_status_first_stage(combat_id, combat)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar status_changed = status_changed
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar status_changed = status_changed
    end
    if combat.status == COMBAT_STATUS_SECOND_STAGE:
        let (status_changed) = _update_combat_status_second_stage(combat_id, combat)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar status_changed = status_changed
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar status_changed = status_changed
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
        # change to second stage
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

func _update_combat_status_second_stage{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, combat: Combat) -> (status_changed: felt):
    alloc_locals

    let (block_timestamp) = get_block_timestamp()
    let (time_passed) = sign(block_timestamp - combat.third_stage_time)
    if time_passed != -1:
        # change to third stage
        FirstRelicCombat_change_to_third_stage(combat_id)
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
    OreLibrary.update_ore(combat_id, ore_coordinate)
    return ()
end
