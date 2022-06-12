%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero, assert_le_felt, assert_lt_felt, unsigned_div_rem, sign

from starkware.starknet.common.syscalls import get_caller_address, get_block_number, get_block_timestamp

from contracts.util.math import min, felt_le

from contracts.pvp.first_relic.constants import (
    ORE_STRUCTURE_HP_PER_WORKER,
    BOT_TYPE_WORKER,
    ORE_STRUCTURE_DEFENSE
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
    FirstRelicCombat_combats,
    FirstRelicCombat_ores,
    FirstRelicCombat_ore_coordinates_len,
    FirstRelicCombat_ore_coordinate_by_index,
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

    func recall_workers{
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
        with_attr error_message("FirstRelicCombat: not enough workers"):
            assert_le_felt(workers_count, ore.mining_workers_count)
        end

        let (block_timestamp) = get_block_timestamp()
        let (koma) = FirstRelicCombat_komas.read(combat_id, account)
        let mining_workers_count = ore.mining_workers_count - workers_count
        let mining_speed = mining_workers_count * koma.worker_mining_speed
        let (empty_time) = _get_ore_empty_timestamp(ore.current_supply, mining_speed, block_timestamp)
        let structure_max_hp = mining_workers_count * ORE_STRUCTURE_HP_PER_WORKER
        let (structure_hp) = min(structure_max_hp, ore.structure_hp)
        local mining_account
        if mining_workers_count == 0:
            mining_account = 0
        else:
            mining_account = ore.mining_account
        end

        let new_ore = Ore(
            coordinate=ore.coordinate, total_supply=ore.total_supply, current_supply=ore.current_supply, collectable_supply=ore.collectable_supply,
            mining_account=mining_account, mining_workers_count=mining_workers_count, mining_speed=mining_speed, structure_hp=structure_hp,
            structure_max_hp=structure_max_hp, start_time=block_timestamp, empty_time=empty_time
        )
        let new_koma = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed,
            koma.props_weight, koma.props_max_weight, koma.workers_count, koma.mining_workers_count+workers_count,
            koma.drones_count, koma.action_radius, koma.element, koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed
        )

        FirstRelicCombat_komas.write(combat_id, account, new_koma)
        FirstRelicCombat_ores.write(combat_id, target, new_ore)
        if mining_workers_count == 0:
            # remove from koma ore list
            let (len) = FirstRelicCombat_koma_ore_coordinates_len.read(combat_id, account)
            let (removed) = _remove_koma_ore_from_list(combat_id, account, target, 0, len)
            with_attr error_message("FirstRelicCombat: remove koma ore failed"):
                assert removed = TRUE
            end
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

    func produce_bot{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
    }(combat_id: felt, account: felt, bot_type: felt, quantity: felt):
        alloc_locals

        let (koma) = FirstRelicCombat_komas.read(combat_id, account)
        let bots_count = koma.workers_count + koma.drones_count
        let (ore_required) = _get_produce_bot_required_ore_amount(bots_count, quantity, 0)
        with_attr error_message("FirstRelicCombat: insufficient ores"):
            assert_le_felt(ore_required, koma.ore_amount)
        end
        let remaining_amount = koma.ore_amount - ore_required
        local workers_count
        local drones_count
        if bot_type == BOT_TYPE_WORKER:
            workers_count = koma.workers_count + quantity
            drones_count = koma.drones_count
        else:
            workers_count = koma.workers_count
            drones_count = koma.drones_count + quantity
        end
        let koma_updated = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility,
            koma.move_speed, koma.props_weight, koma.props_max_weight, workers_count, koma.mining_workers_count,
            drones_count, koma.action_radius, koma.element, remaining_amount, koma.atk, koma.defense, koma.worker_mining_speed
        )
        FirstRelicCombat_komas.write(combat_id, account, koma_updated)

        return ()
    end

    func collect_ore{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(combat_id: felt, account: felt, target: Coordinate):
        let (ore) = FirstRelicCombat_ores.read(combat_id, target)
        with_attr error_message("FirstRelicCombat: invalid ore"):
            assert_not_zero(ore.total_supply)
        end
        let (koma) = FirstRelicCombat_komas.read(combat_id, account)
        with_attr error_message("FirstRelicCombat: not your ore"):
            assert ore.mining_account = account
        end
        let ore_updated = Ore(
            coordinate=ore.coordinate, total_supply=ore.total_supply, current_supply=ore.current_supply, collectable_supply=0,
            mining_account=ore.mining_account, mining_workers_count=ore.mining_workers_count, mining_speed=ore.mining_speed, structure_hp=ore.structure_hp,
            structure_max_hp=ore.structure_max_hp, start_time=ore.start_time, empty_time=ore.empty_time
        )
        let koma_updated = Koma(
            account=koma.account, coordinate=koma.coordinate, status=koma.status, health=koma.health, max_health=koma.max_health,
            agility=koma.agility, move_speed=koma.move_speed, props_weight=koma.props_weight, props_max_weight=koma.props_max_weight,
            workers_count=koma.workers_count, mining_workers_count=koma.mining_workers_count, drones_count=koma.drones_count,
            action_radius=koma.action_radius, element=koma.element, ore_amount=koma.ore_amount+ore.collectable_supply, atk=koma.atk,
            defense=koma.defense, worker_mining_speed=koma.worker_mining_speed
        )
        FirstRelicCombat_ores.write(combat_id, target, ore_updated)
        FirstRelicCombat_komas.write(combat_id, account, koma_updated)
        return ()
    end

    func attack_ore{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(combat_id: felt, account: felt, target: Coordinate):
        alloc_locals

        let (ore) = FirstRelicCombat_ores.read(combat_id, target)
        with_attr error_message("FirstRelicCombat: invalid target"):
            assert_not_zero( (ore.mining_account-account) * ore.mining_account)
        end
        let (koma) = FirstRelicCombat_komas.read(combat_id, account)
        let (damage, _) = unsigned_div_rem(koma.atk * koma.atk, koma.atk + ORE_STRUCTURE_DEFENSE)
        let structure_hp = ore.structure_hp - damage
        let (destroyed) = felt_le(structure_hp, 0)
        if destroyed == TRUE:
            let (ore) = update_ore(combat_id, target)
            let (koma_miner) = FirstRelicCombat_komas.read(combat_id, ore.mining_account)
            let koma_miner_updated = Koma(
                account=koma_miner.account, coordinate=koma_miner.coordinate, status=koma_miner.status, health=koma_miner.health, max_health=koma_miner.max_health,
                agility=koma_miner.agility, move_speed=koma_miner.move_speed, props_weight=koma_miner.props_weight, props_max_weight=koma_miner.props_max_weight,
                workers_count=koma_miner.workers_count-ore.mining_workers_count, mining_workers_count=koma_miner.mining_workers_count-ore.mining_workers_count, drones_count=koma_miner.drones_count,
                action_radius=koma_miner.action_radius, element=koma_miner.element, ore_amount=koma_miner.ore_amount, atk=koma_miner.atk,
                defense=koma_miner.defense, worker_mining_speed=koma_miner.worker_mining_speed
            )
            FirstRelicCombat_komas.write(combat_id, koma_miner.account, koma_miner_updated)
            let ore_updated = Ore(
                coordinate=ore.coordinate, total_supply=ore.total_supply, current_supply=ore.current_supply, collectable_supply=0,
                mining_account=0, mining_workers_count=0, mining_speed=0, structure_hp=0, structure_max_hp=0, start_time=0, empty_time=0
            )
            FirstRelicCombat_ores.write(combat_id, ore.coordinate, ore_updated)
            let koma_updated = Koma(
                account=koma.account, coordinate=koma.coordinate, status=koma.status, health=koma.health, max_health=koma.max_health,
                agility=koma.agility, move_speed=koma.move_speed, props_weight=koma.props_weight, props_max_weight=koma.props_max_weight,
                workers_count=koma.workers_count, mining_workers_count=koma.mining_workers_count, drones_count=koma.drones_count,
                action_radius=koma.action_radius, element=koma.element, ore_amount=koma.ore_amount+ore.collectable_supply, atk=koma.atk,
                defense=koma.defense, worker_mining_speed=koma.worker_mining_speed
            )
            FirstRelicCombat_komas.write(combat_id, koma.account, koma_updated)
            return ()
        else:
            let ore_updated = Ore(
                coordinate=ore.coordinate, total_supply=ore.total_supply, current_supply=ore.current_supply, collectable_supply=ore.collectable_supply,
                mining_account=ore.mining_account, mining_workers_count=ore.mining_workers_count, mining_speed=ore.mining_speed, structure_hp=structure_hp,
                structure_max_hp=ore.structure_max_hp, start_time=ore.start_time, empty_time=ore.empty_time
            )
            FirstRelicCombat_ores.write(combat_id, target, ore_updated)
            return ()
        end
        
    end

    func get_ore_count{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(combat_id: felt) -> (count: felt):
        let (count) = FirstRelicCombat_ore_coordinates_len.read(combat_id)
        return (count)
    end

    func get_ores{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(combat_id: felt, index: felt, length: felt) -> (ores_len: felt, ores: Ore*):
        alloc_locals

        assert_le_felt(0, index)
        assert_lt_felt(0, length)

        let (local data: Ore*) = alloc()
        let (data_len, data) = _get_ores(combat_id, index, length, 0, data)
        return (data_len, data)
    end

    func get_ore_by_coordinate{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(combat_id: felt, coordinate: Coordinate) -> (ore: Ore):
        let (ore) = FirstRelicCombat_ores.read(combat_id, coordinate)
        return (ore)
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

    # update ore current_supply and return updated ore data
    func update_ore{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(combat_id: felt, ore_coordinate: Coordinate) -> (ore: Ore):
        alloc_locals

        let (ore) = FirstRelicCombat_ores.read(combat_id, ore_coordinate)
        if ore.mining_workers_count == 0:
            return (ore)
        end
        let (block_timestamp) = get_block_timestamp()
        let (end_time) = min(block_timestamp, ore.empty_time)
        let (mined_amount) = min(ore.current_supply, (end_time - ore.start_time) * ore.mining_speed)
        let current_supply = ore.current_supply - mined_amount
        let collectable_supply = ore.collectable_supply + mined_amount
        let new_ore = Ore(
            coordinate=ore.coordinate, total_supply=ore.total_supply, current_supply=current_supply, collectable_supply=collectable_supply,
            mining_account=ore.mining_account, mining_workers_count=ore.mining_workers_count, mining_speed=ore.mining_speed,
            structure_hp=ore.structure_hp, structure_max_hp=ore.structure_max_hp, start_time=block_timestamp, empty_time=ore.empty_time
        )
        FirstRelicCombat_ores.write(combat_id, ore_coordinate, new_ore)

        return (new_ore)
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
    alloc_locals

    if index == ore_coordinates_len:
        return ()
    end
    let (ore_coordinate) = FirstRelicCombat_koma_ore_coordinates_by_index.read(combat_id, account, index)
    let (ore) = OreLibrary.update_ore(combat_id, ore_coordinate)
    let ore_updated = Ore(
        coordinate=ore.coordinate, total_supply=ore.total_supply, current_supply=ore.current_supply, collectable_supply=ore.collectable_supply,
        mining_account=0, mining_workers_count=0, mining_speed=0, structure_hp=0, structure_max_hp=0, start_time=0, empty_time=0
    )
    FirstRelicCombat_ores.write(combat_id, ore.coordinate, ore_updated)
    _clear_koma_ores(combat_id, account, index + 1, ore_coordinates_len)
    return ()
end

func _remove_koma_ore_from_list{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, target: Coordinate, index: felt, len: felt) -> (removed: felt):
    if index == len:
        return (FALSE)
    end
    let (coordinate_by_index) = FirstRelicCombat_koma_ore_coordinates_by_index.read(combat_id, account, index)
    if target.x - coordinate_by_index.x + target.y - coordinate_by_index.y == 0:
        FirstRelicCombat_koma_ore_coordinates_len.write(combat_id, account, len - 1)
        # do not do value swapping if it's the last index
        if index != len - 1:
            let (last_ore_coordinate) = FirstRelicCombat_koma_ore_coordinates_by_index.read(combat_id, account, len - 1)
            FirstRelicCombat_koma_ore_coordinates_by_index.write(combat_id, account, index, last_ore_coordinate)
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
        return (TRUE)
    end
    let (removed) = _remove_koma_ore_from_list(combat_id, account, target, index + 1, len)
    
    return (removed)
end

func _get_produce_bot_required_ore_amount{
        range_check_ptr
    }(quantity_now: felt, quantity_produce: felt, ore_amount: felt) -> (ore_amount: felt):
    assert_le_felt(quantity_now, quantity_produce + quantity_now)
    if quantity_produce == 0:
        return (ore_amount)
    end

    let bots_count = quantity_now + 1
    let (ore_required, _) = unsigned_div_rem(bots_count * (bots_count + 1) * 1000, 2)

    return _get_produce_bot_required_ore_amount(quantity_now + 1, quantity_produce - 1, ore_amount + ore_required)
end

# recursively get ore struct array 
func _get_ores{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, index: felt, length: felt, data_len: felt, data: Ore*) -> (data_len: felt, data: Ore*):
    if length == 0:
        return (data_len, data)
    end

    let (ores_count) = FirstRelicCombat_ore_coordinates_len.read(combat_id)
    if index == ores_count:
        return (data_len, data)
    end

    let (coordinate) = FirstRelicCombat_ore_coordinate_by_index.read(combat_id, index)
    let (chest) = FirstRelicCombat_ores.read(combat_id, coordinate)
    assert data[data_len] = chest

    return _get_ores(combat_id, index+1, length-1, data_len+1, data)
end