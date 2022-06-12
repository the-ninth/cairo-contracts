%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero, assert_le_felt, assert_lt_felt, unsigned_div_rem, sign

from starkware.starknet.common.syscalls import get_caller_address, get_block_number, get_block_timestamp

from contracts.pvp.first_relic.structs import (
    Combat,
    Chest,
    Ore,
    Koma,
    Coordinate,
    Prop,
    PropEffect,
    RelicGate,
    COMBAT_STATUS_NON_EXIST,
    COMBAT_STATUS_REGISTERING,
    COMBAT_STATUS_PREPARING,
    COMBAT_STATUS_FIRST_STAGE,
    COMBAT_STATUS_SECOND_STAGE,
    COMBAT_STATUS_THIRD_STAGE,
    COMBAT_STATUS_END,
    KOMA_STATUS_DEAD,
    KOMA_STATUS_THIRD_STAGE
)
from contracts.pvp.first_relic.constants import (
    MAP_WIDTH,
    MAP_HEIGHT,
    MAP_INNER_AREA_WIDTH,
    MAP_INNER_AREA_HEIGHT,
    PREPARE_TIME,
    FIRST_STAGE_DURATION,
    SECOND_STAGE_DURATION,
    PROP_CREATURE_SHIELD,
    PROP_CREATURE_ATTACK_UP_30P,
    PROP_CREATURE_DAMAGE_DOWN_30P,
    get_relic_gate_key_ids,
    get_inner_coordinates,
    get_outer_coordinates
)
from contracts.pvp.first_relic.storages import (
    FirstRelicCombat_combat_counter,
    FirstRelicCombat_combats,
    FirstRelicCombat_chests,
    FirstRelicCombat_chest_coordinates_len,
    FirstRelicCombat_chest_coordinate_by_index,
    FirstRelicCombat_ores,
    FirstRelicCombat_ore_coordinates_len,
    FirstRelicCombat_ore_coordinate_by_index,
    FirstRelicCombat_komas,
    FirstRelicCombat_chest_options,
    FirstRelicCombat_relic_gates,
    FirstRelicCombat_relic_gate_number_by_coordinate,
    FirstRelicCombat_props,
    FirstRelicCombat_koma_props_effect,
    FirstRelicCombat_koma_props_effect_creature_id_len,
    FirstRelicCombat_koma_props_effect_creature_id_by_index,
    FirstRelicCombat_third_stage_players_count
)
from contracts.pvp.first_relic.FRPlayerLibrary import FirstRelicCombat_get_koma_actual_coordinate
from contracts.util.random import get_random_number_and_seed
from contracts.util.math import min, in_on_layer
from contracts.pvp.first_relic.IFirstRelicCombat import PlayerAttack

func FirstRelicCombat_get_combat_count{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (count: felt):
    let (count) = FirstRelicCombat_combat_counter.read()
    return (count)
end

func FirstRelicCombat_get_combat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (combat: Combat):
    let (combat) = FirstRelicCombat_combats.read(combat_id)
    return (combat)
end

func FirstRelicCombat_get_chest_count{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (count: felt):
    let (count) = FirstRelicCombat_chest_coordinates_len.read(combat_id)
    return (count)
end

func FirstRelicCombat_get_chests{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, index: felt, length: felt) -> (data_len: felt, data: Chest*):
    alloc_locals

    assert_le_felt(0, index)
    assert_lt_felt(0, length)

    let (local data: Chest*) = alloc()
    let (data_len, data) = _get_chests(combat_id, index, length, 0, data)
    return (data_len, data)
end

func FirstRelicCombat_get_chest_by_coordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, coordinate: Coordinate) -> (chest: Chest):
    let (chest) = FirstRelicCombat_chests.read(combat_id, coordinate)
    return (chest)
end





func FirstRelicCombat_attack{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, target_account: felt) -> (koma_attacked_status: felt):
    alloc_locals

    let (koma_attacker) = FirstRelicCombat_komas.read(combat_id, account)
    let (koma_attacked) = FirstRelicCombat_komas.read(combat_id, target_account)

    let (_, koma_attacker_actual_at) = FirstRelicCombat_get_koma_actual_coordinate(combat_id, account, koma_attacker)
    let (_, koma_attacked_actual_at) = FirstRelicCombat_get_koma_actual_coordinate(combat_id, account, koma_attacked)
    let (in_range) = in_on_layer(koma_attacker_actual_at, koma_attacked_actual_at, koma_attacker.action_radius)
    with_attr error_message("FirstRelicCombat: action out of range"):
        assert in_range = TRUE
    end

    # return if attacked koma has a shield
    let (prop_effect_sheild) = FirstRelicCombat_koma_props_effect.read(combat_id, account, PROP_CREATURE_SHIELD)
    if prop_effect_sheild.prop_creature_id != 0:
        _remove_prop_effect(combat_id, account, prop_effect_sheild)
        PlayerAttack.emit(combat_id, account, target_account, 0, koma_attacked.status)
        return (koma_attacked.status)
    end

    let atk = koma_attacker.atk * koma_attacker.drones_count
    # add atk if koma_attacker has a buff
    let (atk) = _use_prop_effect_attack_up(atk, combat_id, account)
    
    let (damage, _) = unsigned_div_rem(atk * atk, atk + koma_attacked.defense)
    # reduce damage
    let (damage) = _use_prop_effect_damage_down(damage, combat_id, target_account)

    let remain_health = koma_attacked.health - damage
    let (health_sign) = sign(remain_health)
    local koma_attacked_status
    if health_sign == 1:
        # still alive
        koma_attacked_status = koma_attacked.status
    else:
        koma_attacked_status = KOMA_STATUS_DEAD
    end
    let koma_attacked_updated = Koma(
        account=koma_attacked.account,
        coordinate=koma_attacked.coordinate,
        status=koma_attacked_status,
        health=remain_health,
        max_health=koma_attacked.max_health,
        agility=koma_attacked.agility,
        move_speed=koma_attacked.move_speed,
        props_weight=koma_attacked.props_weight,
        props_max_weight=koma_attacked.props_max_weight,
        workers_count=koma_attacked.workers_count,
        mining_workers_count=koma_attacked.mining_workers_count,
        drones_count=koma_attacked.drones_count,
        action_radius=koma_attacked.action_radius,
        element=koma_attacked.element,
        ore_amount=koma_attacked.ore_amount,
        atk=koma_attacked.atk,
        defense=koma_attacked.defense,
        worker_mining_speed=koma_attacked.worker_mining_speed
    )
    FirstRelicCombat_komas.write(combat_id, target_account, koma_attacked_updated)
    
    PlayerAttack.emit(combat_id, account, target_account, damage, koma_attacked_status)

    return (koma_attacked_status)
end

func FirstRelicCombat_new_combat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (combat_id: felt):
    let (count) = FirstRelicCombat_combat_counter.read()
    let combat_id = count + 1
    let combat = Combat(0, 0, 0, 0, 0, 0, status=COMBAT_STATUS_REGISTERING)
    FirstRelicCombat_combat_counter.write(combat_id)
    FirstRelicCombat_combats.write(combat_id, combat)
    return (combat_id)
end

func FirstRelicCombat_init_chests{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, chests_count: felt, seed: felt) -> (next_seed: felt):
    let (next_seed) = _init_chests(combat_id, chests_count, seed)
    return (next_seed)
end

func FirstRelicCombat_init_ores{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, ores_count: felt, seed: felt) -> (next_seed: felt):
    let (next_seed) = _init_ores(combat_id, ores_count, seed)
    return (next_seed)
end

func FirstRelicCombat_prepare_combat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    let (combat) = FirstRelicCombat_combats.read(combat_id)
    with_attr error_message("FirstRelicCombat: not registering"):
        assert combat.status = COMBAT_STATUS_REGISTERING
    end
    let (block_timestamp) = get_block_timestamp()
    let combat_updated: Combat = Combat(block_timestamp, block_timestamp + PREPARE_TIME, 0, 0, 0, 0, COMBAT_STATUS_PREPARING)
    FirstRelicCombat_combats.write(combat_id, combat_updated)
    return ()
end

func FirstRelicCombat_change_to_first_stage{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    let (combat) = FirstRelicCombat_combats.read(combat_id)
    with_attr error_message("FirstRelicCombat: not preparing"):
        assert combat.status = COMBAT_STATUS_PREPARING
    end
    let new_combat = Combat(
        prepare_time=combat.prepare_time,
        first_stage_time=combat.first_stage_time,
        second_stage_time=combat.first_stage_time + FIRST_STAGE_DURATION,
        third_stage_time=combat.third_stage_time,
        end_time=combat.end_time,
        expire_time=combat.expire_time,
        status=COMBAT_STATUS_FIRST_STAGE
    )
    FirstRelicCombat_combats.write(combat_id, new_combat)

    return ()
end

func FirstRelicCombat_change_to_second_stage{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    let (combat) = FirstRelicCombat_combats.read(combat_id)
    with_attr error_message("FirstRelicCombat: not first stage"):
        assert combat.status = COMBAT_STATUS_FIRST_STAGE
    end
    let new_combat = Combat(
        prepare_time=combat.prepare_time,
        first_stage_time=combat.first_stage_time,
        second_stage_time=combat.second_stage_time,
        third_stage_time=combat.second_stage_time + SECOND_STAGE_DURATION,
        end_time=combat.end_time,
        expire_time=combat.expire_time,
        status=COMBAT_STATUS_SECOND_STAGE
    )
    FirstRelicCombat_combats.write(combat_id, new_combat)

    # generate 9 gates
    let (block_timestamp) = get_block_timestamp()
    let (block_number) = get_block_number()
    let (key_ids_len, key_ids) = get_relic_gate_key_ids()
    _init_relic_gates(combat_id, 1, key_ids_len, key_ids, block_timestamp * block_number)    

    return ()
end


func FirstRelicCombat_change_to_third_stage{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt):
    let (combat) = FirstRelicCombat_combats.read(combat_id)
    with_attr error_message("FirstRelicCombat: not first stage"):
        assert combat.status = COMBAT_STATUS_SECOND_STAGE
    end
    let (count) = FirstRelicCombat_third_stage_players_count.read(combat_id)
    if count == 0:
        let new_combat = Combat(
            prepare_time=combat.prepare_time,
            first_stage_time=combat.first_stage_time,
            second_stage_time=combat.second_stage_time,
            third_stage_time=combat.third_stage_time,
            end_time=combat.end_time,
            expire_time=combat.expire_time,
            status=COMBAT_STATUS_END
        )
        FirstRelicCombat_combats.write(combat_id, new_combat)
    else:
        let new_combat = Combat(
            prepare_time=combat.prepare_time,
            first_stage_time=combat.first_stage_time,
            second_stage_time=combat.second_stage_time,
            third_stage_time=combat.third_stage_time,
            end_time=combat.end_time,
            expire_time=combat.expire_time,
            status=COMBAT_STATUS_THIRD_STAGE
        )
        FirstRelicCombat_combats.write(combat_id, new_combat)
    end

    return ()
end

func FirstRelicCombat_get_relic_gate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, number: felt) -> (relic_gate: RelicGate):
    let (relic_gate) = FirstRelicCombat_relic_gates.read(combat_id, number)
    with_attr error_message("FirstRelicCombat: relic gate invalid"):
        assert_not_zero(relic_gate.number)
    end
    return (relic_gate)
end

func FirstRelicCombat_get_relic_gates{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (relic_gates_len: felt, relic_gates: RelicGate*):
    alloc_locals

    let (local relic_gates: RelicGate*) = alloc()
    _get_relic_gates(combat_id, 1, relic_gates)

    return (9, relic_gates)
end

func FirstRelicCombat_enter_relic_gate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, to: Coordinate, prop_id: felt):
    alloc_locals

    let (number) = FirstRelicCombat_relic_gate_number_by_coordinate.read(combat_id, to)
    let (relic_gate) = FirstRelicCombat_relic_gates.read(combat_id, number)
    let (prop) = FirstRelicCombat_props.read(combat_id, prop_id)
    with_attr error_message("FirstRelicCombat: invalid gate"):
        assert_not_zero(relic_gate.number)
    end
    with_attr error_message("FirstRelicCombat: gate used"):
        assert relic_gate.account = 0
    end
    with_attr error_message("FirstRelicCombat: key invaid"):
        assert prop.prop_creature_id = relic_gate.require_creature_id
    end

    let gate_x = relic_gate.coordinate.x
    let gate_y = relic_gate.coordinate.y
    let (koma) = FirstRelicCombat_komas.read(combat_id, account)
    let (_, koma_actual_at) = FirstRelicCombat_get_koma_actual_coordinate(combat_id, account, koma)
    let (in_range) = in_on_layer(koma_actual_at, relic_gate.coordinate, koma.action_radius)
    with_attr error_message("FirstRelicCombat: action out of range"):
        assert in_range = TRUE
    end

    let relic_gate_updated = RelicGate(relic_gate.coordinate, relic_gate.number, relic_gate.require_creature_id, account)
    FirstRelicCombat_relic_gates.write(combat_id, number, relic_gate_updated)
    let koma_updated = Koma(
        koma.account, koma.coordinate, KOMA_STATUS_THIRD_STAGE, koma.health, koma.max_health, koma.agility,
        koma.move_speed, koma.props_weight, koma.props_max_weight, koma.workers_count, koma.mining_workers_count,
        koma.drones_count, koma.action_radius, koma.element, koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed
    )
    FirstRelicCombat_komas.write(combat_id, account, koma_updated)
    let (count) = FirstRelicCombat_third_stage_players_count.read(combat_id)
    FirstRelicCombat_third_stage_players_count.write(combat_id, count + 1)

    return ()
end

func FirstRelicCombat_in_moving_stage{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (in_moving_stage: felt):
    let (combat) = FirstRelicCombat_combats.read(combat_id)
    if combat.status == COMBAT_STATUS_FIRST_STAGE:
        return (TRUE)
    end
    if combat.status == COMBAT_STATUS_SECOND_STAGE:
        return (TRUE)
    end
    return (FALSE)
end



# func FirstRelicCombat_init_combat_by_random{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }(combat_id: felt, random: felt):
#     let (combat) = combats.read(combat_id)
#     with_attr error_message("FirstRelicCombat: combat initialized"):
#         assert combat.status = 0
#     end
#     # todo: setup chests and ore randomly
#     let (block_number) = get_block_number()
#     let (caller) = get_caller_address()
#     _init_chests(combat_id, MAP_MAX_CHESTS, block_number + caller)
#     return ()
# end

func _init_chests{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, chests_count: felt, seed: felt) -> (next_seed: felt):
    if chests_count == 0:
        return (seed)
    end
    let (coordinate, next_seed) = _fetch_outer_empty_coordinate(combat_id, seed)
    let (chest_len) = FirstRelicCombat_chest_coordinates_len.read(combat_id)
    let chest = Chest(coordinate=coordinate, opener=0, option_selected=0, id=chest_len+1)
    FirstRelicCombat_chests.write(combat_id, coordinate, chest)
    FirstRelicCombat_chest_coordinate_by_index.write(combat_id, chest_len, coordinate)
    FirstRelicCombat_chest_coordinates_len.write(combat_id, chest_len + 1)

    let (next_seed) = _init_chests(combat_id, chests_count - 1, next_seed)

    return (next_seed)
end

func _init_ores{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, ores_count: felt, seed: felt) -> (next_seed: felt):
    if ores_count == 0:
        return (seed)
    end
    let (coordinate, next_seed) = _fetch_outer_empty_coordinate(combat_id, seed)
    let ore = Ore(
        coordinate=coordinate, total_supply=1000000, current_supply=1000000, collectable_supply=0, mining_account=0,
        mining_workers_count=0, mining_speed=0, structure_hp=0, structure_max_hp=0, start_time=0, empty_time=0
    )
    let (ore_len) = FirstRelicCombat_ore_coordinates_len.read(combat_id)
    FirstRelicCombat_ores.write(combat_id, coordinate, ore)
    FirstRelicCombat_ore_coordinate_by_index.write(combat_id, ore_len, coordinate)
    FirstRelicCombat_ore_coordinates_len.write(combat_id, ore_len + 1)
    let (next_seed) = _init_ores(combat_id, ores_count - 1, next_seed)

    return (next_seed)
end

# fetch a empty coordinate randomly
func _fetch_outer_empty_coordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, seed: felt) -> (coordinate: Coordinate, next_seed: felt):
    alloc_locals

    let (coordinates_len, coordinates) = get_outer_coordinates()
    
    let (local index, local next_seed) = get_random_number_and_seed(seed, coordinates_len)
    local coordinate: Coordinate = coordinates[index]
    let (chest) = FirstRelicCombat_chests.read(combat_id, coordinate)
    let (ore) = FirstRelicCombat_ores.read(combat_id, coordinate)
    let exist = chest.coordinate.x * chest.coordinate.y * ore.total_supply
    if exist != 0:
        let (local coordinate, local next_seed) = _fetch_outer_empty_coordinate(combat_id, next_seed)
        return (coordinate, next_seed)
    end

    return (coordinate, next_seed)
end

# recursively get chest struct array 
func _get_chests{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, index: felt, length: felt, data_len: felt, data: Chest*) -> (data_len: felt, data: Chest*):
    if length == 0:
        return (data_len, data)
    end

    let (chests_count) = FirstRelicCombat_chest_coordinates_len.read(combat_id)
    if index == chests_count:
        return (data_len, data)
    end

    let (coordinate) = FirstRelicCombat_chest_coordinate_by_index.read(combat_id, index)
    let (chest) = FirstRelicCombat_chests.read(combat_id, coordinate)
    assert data[data_len] = chest

    return _get_chests(combat_id, index+1, length-1, data_len+1, data)
end



# func _retreive_mining_ore{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }(mining_ore: KomaMiningOre, ore_empty_time) -> (retreive_amount: felt):
#     alloc_locals
#     if mining_ore.mining_workers_count == 0:
#         return (0)
#     end
#     let (block_timestamp) = get_block_timestamp()
#     let (end_time) = min(block_timestamp, ore_empty_time)
#     let retreive_amount = (end_time - mining_ore.start_time) * mining_ore.mining_workers_count * mining_ore.worker_mining_speed
#     return (retreive_amount)
# end

# recursively get ore struct array 
# func _get_koma_mining_ores{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }(combat_id: felt, account: felt, index: felt, data_len: felt, data: KomaMiningOre*):
#     if data_len == 0:
#         return ()
#     end

#     let (coordinate) = FirstRelicCombat_koma_mining_ore_coordinates_by_index.read(combat_id, account, index)
#     let (mining_ore) = FirstRelicCombat_koma_mining_ores.read(combat_id, account, coordinate)
#     assert data[index] = mining_ore
#     _get_koma_mining_ores(combat_id, account, index+1, data_len-1, data)

#     return ()
# end




func _init_relic_gates{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, number: felt, key_ids_len: felt, key_ids: felt*, seed: felt) -> (next_seed: felt):
    if key_ids_len==0:
        return (seed)
    end
    let (coordinate, next_seed) = _fetch_relic_gate_coordinate(combat_id, seed)
    let gate = RelicGate(coordinate, number, key_ids[0], 0)
    FirstRelicCombat_relic_gates.write(combat_id, number, gate)
    FirstRelicCombat_relic_gate_number_by_coordinate.write(combat_id, coordinate, number)

    return _init_relic_gates(combat_id, number + 1, key_ids_len - 1, key_ids + 1, next_seed)
end

# fetch a empty coordinate randomly for gate
func _fetch_relic_gate_coordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, seed: felt) -> (coordinate: Coordinate, next_seed: felt):
    alloc_locals
    
    let (coordinates_len, coordinates) = get_inner_coordinates()
    let (local index, local next_seed) = get_random_number_and_seed(seed, coordinates_len)
    local coordinate: Coordinate = coordinates[index]
    # let (chest) = FirstRelicCombat_chests.read(combat_id, coordinate)
    # let (ore) = FirstRelicCombat_ores.read(combat_id, coordinate)
    let (number) = FirstRelicCombat_relic_gate_number_by_coordinate.read(combat_id, coordinate)
    let exist = number
    if exist != 0:
        let (local coordinate, local next_seed) = _fetch_relic_gate_coordinate(combat_id, next_seed)
        return (coordinate, next_seed)
    end

    return (coordinate, next_seed)
end

# recursively get relic gate struct array 
func _get_relic_gates{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, number: felt, data: RelicGate*):
    if number == 10:
        return ()
    end

    let (relic_gate) = FirstRelicCombat_relic_gates.read(combat_id, number)
    assert data[number - 1] = relic_gate
    _get_relic_gates(combat_id, number + 1, data)

    return ()
end

func _remove_prop_effect{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, prop_effect: PropEffect):
    let prop_effect_updated = PropEffect(0, 0, 0)
    FirstRelicCombat_koma_props_effect.write(combat_id, account, prop_effect.prop_creature_id, prop_effect_updated)
    let (len) = FirstRelicCombat_koma_props_effect_creature_id_len.read(combat_id, account)
    let (last_effect_prop_creature_id) = FirstRelicCombat_koma_props_effect_creature_id_by_index.read(combat_id, account, len - 1)
    FirstRelicCombat_koma_props_effect_creature_id_by_index.write(combat_id, account, prop_effect.index_in_koma_effects, last_effect_prop_creature_id)
    FirstRelicCombat_koma_props_effect_creature_id_len.write(combat_id, account, len - 1)

    return ()
end

func _use_prop_effect_attack_up{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(atk: felt, combat_id: felt, account: felt) -> (atk: felt):
    let (prop_effect_attack_up) = FirstRelicCombat_koma_props_effect.read(combat_id, account, PROP_CREATURE_ATTACK_UP_30P)
    if prop_effect_attack_up.prop_creature_id != 0:
        let (atk, _) = unsigned_div_rem(atk * 130, 100)
        _remove_prop_effect(combat_id, account, prop_effect_attack_up)
        return (atk)
    else:
        return (atk)
    end
end

func _use_prop_effect_damage_down{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(damage: felt, combat_id: felt, account: felt) -> (damage: felt):
    let (prop_effect_damage_down) = FirstRelicCombat_koma_props_effect.read(combat_id, account, PROP_CREATURE_DAMAGE_DOWN_30P)
    if prop_effect_damage_down.prop_creature_id != 0:
        let (damage, _) = unsigned_div_rem(damage * 7, 10)
        _remove_prop_effect(combat_id, account, prop_effect_damage_down)
        return (damage)
    else:
        return (damage)
    end
end

