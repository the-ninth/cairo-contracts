%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero, assert_le_felt, assert_lt_felt, unsigned_div_rem, sign

from starkware.starknet.common.syscalls import get_caller_address, get_block_number, get_block_timestamp

from contracts.pvp.first_relic.constants import (
    ORE_STRUCTURE_HP_PER_WORKER
)
from contracts.pvp.first_relic.structs import (
    Coordinate,
    Ore,
    Koma,
    COMBAT_STATUS_NON_EXIST,
    COMBAT_STATUS_REGISTERING,
    COMBAT_STATUS_PREPARING,
    COMBAT_STATUS_THIRD_STAGE,
    COMBAT_STATUS_END,
    KOMA_STATUS_DEAD
)
from contracts.pvp.first_relic.storages import (
    FirstRelicCombat_ores,
    FirstRelicCombat_combats,
    FirstRelicCombat_komas,
    FirstRelicCombat_koma_ore_coordinates_len,
    FirstRelicCombat_koma_ore_coordinates_by_index
)

namespace OreLibrary:

    func mine_ore{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, target: Coordinate, workers_count: felt):
        alloc_locals

        let (ore) = FirstRelicCombat_ores.read(combat_id, target)
        with_attr error_message("FirstRelicCombat: invalid ore"):
            assert_not_zero(ore.total_supply)
        end
        with_attr error_message("FirstRelicCombat: invalid workers"):
            assert_lt_felt(0, workers_count)
        end
        with_attr error_message("FirstRelicCombat: empty supply"):
            assert_lt_felt(0, ore.current_supply)
        end
        let (res) = _can_mine(combat_id, account)
        with_attr error_message("FirstRelicCombat: can not mine"):
            assert res = TRUE
        end
        with_attr error_message("FirstRelicCombat: ore has a miner"):
            assert ore.mining_account * (account - ore.mining_account) = 0
        end
        let (koma) = FirstRelicCombat_komas.read(combat_id, account)
        let available_workers_count = koma.workers_count - koma.mining_workers_count
        with_attr error_message("FirstRelicCombat: not enough workers"):
            assert_le_felt(workers_count, available_workers_count)
        end

        # let (_, koma_actual_at) = FirstRelicCombat_get_koma_actual_coordinate(combat_id, account, koma)
        # let (in_range) = in_on_layer(koma_actual_at, ore.coordinate, koma.action_radius)
        # with_attr error_message("FirstRelicCombat: action out of range"):
        #     assert in_range = TRUE
        # end

        let (block_timestamp) = get_block_timestamp()
        
        let mining_workers_count = ore.mining_workers_count + workers_count
        # mining_speed: how much ore mined per second by all workers on this ore
        let mining_speed = ore.mining_workers_count * koma.worker_mining_speed
        
        let (empty_time) = _get_ore_empty_timestamp(ore.current_supply, mining_speed, block_timestamp)
        let new_ore = Ore(
            coordinate=ore.coordinate, total_supply=ore.total_supply, current_supply=ore.current_supply, collectable_supply=ore.collectable_supply,
            mining_account=account, mining_workers_count=mining_workers_count, mining_speed=mining_speed, structure_hp=ORE_STRUCTURE_HP_PER_WORKER * workers_count,
            structure_max_hp=ORE_STRUCTURE_HP_PER_WORKER * workers_count, start_time=block_timestamp, empty_time=empty_time
        )

        let new_koma = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed,
            koma.props_weight, koma.props_max_weight, koma.workers_count, koma.mining_workers_count+workers_count,
            koma.drones_count, koma.action_radius, koma.element, koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed
        )

        FirstRelicCombat_komas.write(combat_id, account, new_koma)
        FirstRelicCombat_ores.write(combat_id, target, new_ore)
        if ore.mining_workers_count == 0:
            # insert into koma ores list
            let (len) = FirstRelicCombat_koma_ore_coordinates_len.read(combat_id, account)
            FirstRelicCombat_koma_ore_coordinates_by_index.write(combat_id, account, len, target)
            FirstRelicCombat_koma_ore_coordinates_len.write(combat_id, account, len + 1)
        end

        return ()
    end

    func clear_koma_ores{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt):
        let (koma_ores_len) = FirstRelicCombat_koma_ore_coordinates_len.read(combat_id, account)
        _clear_koma_ores(combat_id, account, 0, koma_ores_len)
        FirstRelicCombat_koma_ore_coordinates_len.write(combat_id, account, 0)
        return ()
    end

end

func _can_mine{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt) -> (res: felt):
    let (combat) = FirstRelicCombat_combats.read(combat_id)
    if combat.status == COMBAT_STATUS_NON_EXIST:
        return (FALSE)
    end
    if combat.status == COMBAT_STATUS_REGISTERING:
        return (FALSE)
    end
    if combat.status == COMBAT_STATUS_PREPARING:
        return (FALSE)
    end
    if combat.status == COMBAT_STATUS_THIRD_STAGE:
        return (FALSE)
    end
    if combat.status == COMBAT_STATUS_END:
        return (FALSE)
    end
    let (koma) = FirstRelicCombat_komas.read(combat_id, account)
    if koma.status == KOMA_STATUS_DEAD:
        return (FALSE)
    end

    return (TRUE)
end

func _get_ore_empty_timestamp{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(current_supply: felt, mining_speed: felt, start_time: felt) -> (empty_time):
    if current_supply == 0:
        return (0)
    end
    if mining_speed == 0:
        return (0)
    else:
        let (empty_time_need, r) = unsigned_div_rem(current_supply, mining_speed)
        let empty_timestamp = start_time + empty_time_need
        if r != 0:
            return (empty_timestamp + 1)
        else:
            return (empty_timestamp)
        end
    end
end

# remove all mining_ores of a dead player and recalculate ore storage
func _clear_koma_ores{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, index: felt, ore_coordinates_len: felt):
    # alloc_locals

    # if index == mining_ore_coordinates_len:
    #     return ()
    # end
    # let (mining_ore_coordinate) = FirstRelicCombat_koma_mining_ore_coordinates_by_index.read(combat_id, account, index)
    # let (mining_ore) = FirstRelicCombat_koma_mining_ores.read(combat_id, account, mining_ore_coordinate)
    # let (ore) = FirstRelicCombat_ores.read(combat_id, mining_ore_coordinate)
    # let (block_timestamp) = get_block_timestamp()
    # let (end_time) = min(block_timestamp, ore.empty_time)
    # let ore_mined_amount = (end_time - ore.start_time) * ore.mining_speed + ore.mined_supply
    # let (remaining_amount) = min(ore.total_supply - ore_mined_amount, 0)
    # let mining_workers_count = ore.mining_workers_count - mining_ore.mining_workers_count
    # let mining_speed = ore.mining_speed - mining_ore.worker_mining_speed * mining_ore.mining_workers_count
    # let (empty_timestamp) = _get_ore_empty_timestamp(remaining_amount, mining_speed, block_timestamp)
    # let ore_updated = Ore(
    #     coordinate=ore.coordinate,
    #     total_supply=ore.total_supply,
    #     mined_supply=ore.mined_supply,
    #     mining_workers_count=mining_workers_count,
    #     mining_speed=mining_speed,
    #     start_time=block_timestamp,
    #     empty_time=empty_timestamp
    # )
    # FirstRelicCombat_ores.write(combat_id, ore.coordinate, ore_updated)

    # # ignore modifying mining ore storage becuase it's not necessary

    # _clear_mining_ores(combat_id, account, index + 1, mining_ore_coordinates_len)

    return ()
end