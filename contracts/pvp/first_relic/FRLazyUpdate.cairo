%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import sign

from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.pvp.first_relic.structs import Combat, COMBAT_STATUS_PREPARING
from contracts.pvp.first_relic.FRCombatLibrary import FirstRelicCombat_get_combat, FirstRelicCombat_change_to_first_stage


func LazyUpdate_update_combat_status{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    alloc_locals

    let (combat) = FirstRelicCombat_get_combat(combat_id)
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