%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le_felt,
    assert_lt_felt,
    unsigned_div_rem,
)

from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.pvp.first_relic.constants import (
    get_props_pool,
    PROP_CREATURE_SHIELD,
    PROP_TYPE_EQUIPMENT,
    PROP_EQUIPMENT_PART_ENGINE,
    PROP_EQUIPMENT_PART_SHOE,
    PROP_EQUIPMENT_PART_WEAPON,
    PROP_EQUIPMENT_PART_ARMOR,
    PROP_CREATURE_HEALTH_KIT,
    PROP_CREATURE_MAX_HEALTH_UP_10,
    PROP_CREATURE_ENGINE,
    PROP_CREATURE_SHOE,
    PROP_CREATURE_LASER_GUN,
    PROP_CREATURE_DRILL,
    PROP_CREATURE_ARMOR,
    PROP_WEIGHT_EQUIPMENTS,
    PROP_WEIGHT_OTHERS,
)
from contracts.pvp.first_relic.structs import (
    Chest,
    Coordinate,
    Koma,
    Prop,
    PropEffect,
    KomaEquipments,
)
from contracts.pvp.first_relic.storages import (
    FirstRelicCombat_chests,
    FirstRelicCombat_chest_options,
    FirstRelicCombat_komas,
    FirstRelicCombat_koma_props_len,
    FirstRelicCombat_koma_props_id_by_index,
    FirstRelicCombat_koma_props_effect,
    FirstRelicCombat_koma_props_effect_creature_id_len,
    FirstRelicCombat_koma_props_effect_creature_id_by_index,
    FirstRelicCombat_props,
    FirstRelicCombat_props_counter,
    FirstRelicCombat_props_owner,
    FirstRelicCombat_koma_equipments,
)
from contracts.pvp.first_relic.FRPlayerLibrary import FirstRelicCombat_get_koma_actual_coordinate
from contracts.util.math import max, min, in_on_layer
from contracts.util.array import felt_in_array
from contracts.util.random import get_random_number_and_seed

func FirstRelicCombat_open_chest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, target: Coordinate
) {
    alloc_locals;

    let (chest) = FirstRelicCombat_chests.read(combat_id, target);
    with_attr error_message("FirstRelicCombat: invalid chest") {
        assert_not_zero(chest.id);
    }

    with_attr error_message("FirstRelicCombat: chest opened") {
        assert chest.opener = 0;
    }

    // write options to storage
    let (props_pool_len, props_pool) = get_props_pool();
    let (block_timestamp) = get_block_timestamp();
    let (local options: felt*) = alloc();
    _generate_chest_options(block_timestamp * account, 0, options, props_pool_len);
    // let (index1, next_seed) = get_random_number_and_seed(, props_pool_len)
    // let (index2, next_seed) = get_random_number_and_seed(next_seed, props_pool_len)
    // let (index3, _) = get_random_number_and_seed(next_seed, props_pool_len)
    FirstRelicCombat_chest_options.write(combat_id, target, 1, props_pool[options[0]]);
    FirstRelicCombat_chest_options.write(combat_id, target, 2, props_pool[options[1]]);
    FirstRelicCombat_chest_options.write(combat_id, target, 3, props_pool[options[2]]);
    let chest_updated = Chest(coordinate=target, opener=account, option_selected=0, id=chest.id);
    FirstRelicCombat_chests.write(combat_id, target, chest_updated);

    return ();
}

func FirstRelicCombat_get_chest_options{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(combat_id: felt, target: Coordinate) -> (options_len: felt, options: felt*) {
    alloc_locals;

    let (chest) = FirstRelicCombat_chests.read(combat_id, target);
    with_attr error_message("FirstRelicCombat: chest not opened") {
        assert_not_zero(chest.opener);
    }

    let (local options: felt*) = alloc();
    let (option1) = FirstRelicCombat_chest_options.read(combat_id, target, 1);
    let (option2) = FirstRelicCombat_chest_options.read(combat_id, target, 2);
    let (option3) = FirstRelicCombat_chest_options.read(combat_id, target, 3);
    assert options[0] = option1;
    assert options[1] = option2;
    assert options[2] = option3;

    return (3, options);
}

func FirstRelicCombat_select_chest_option{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(combat_id: felt, account: felt, target: Coordinate, option: felt) {
    alloc_locals;

    let (chest) = FirstRelicCombat_chests.read(combat_id, target);
    with_attr error_message("FirstRelicCombat: invalid chest") {
        assert_not_zero(chest.id);
    }

    with_attr error_message("FirstRelicCombat: chest option selected") {
        assert chest.option_selected = 0;
    }

    let chest_updated = Chest(chest.coordinate, chest.opener, option, chest.id);
    let (selected_prop_creature_id) = FirstRelicCombat_chest_options.read(
        combat_id, target, option
    );
    with_attr error_message("FirstRelicCombat: invalid chest option") {
        assert_lt_felt(0, selected_prop_creature_id);
    }

    let (koma) = FirstRelicCombat_komas.read(combat_id, account);
    let (prop_weight) = _get_prop_weight(selected_prop_creature_id);
    let new_weight = koma.props_weight + prop_weight;
    with_attr error_message("FirstRelicCombat: excceed max weight") {
        assert_le_felt(new_weight, koma.props_max_weight);
    }

    let (_, koma_actual_at) = FirstRelicCombat_get_koma_actual_coordinate(combat_id, account, koma);
    let (in_range) = in_on_layer(koma_actual_at, chest.coordinate, koma.action_radius);
    with_attr error_message("FirstRelicCombat: action out of range") {
        assert in_range = TRUE;
    }

    let (props_count) = FirstRelicCombat_props_counter.read(combat_id);
    let prop_id = props_count + 1;
    let (len) = FirstRelicCombat_koma_props_len.read(combat_id, account);
    let prop = Prop(
        prop_id=prop_id,
        prop_creature_id=selected_prop_creature_id,
        used_timetamp=0,
        index_in_koma_props=len,
    );
    let koma_updated = Koma(
        koma.account,
        koma.coordinate,
        koma.status,
        koma.health,
        koma.max_health,
        koma.agility,
        koma.move_speed,
        new_weight,
        koma.props_max_weight,
        koma.workers_count,
        koma.mining_workers_count,
        koma.drones_count,
        koma.action_radius,
        koma.element,
        koma.ore_amount,
        koma.atk,
        koma.defense,
        koma.worker_mining_speed,
    );
    FirstRelicCombat_props.write(combat_id, prop_id, prop);
    FirstRelicCombat_props_owner.write(combat_id, prop_id, account);
    FirstRelicCombat_koma_props_id_by_index.write(combat_id, account, len, prop_id);
    FirstRelicCombat_props_counter.write(combat_id, prop_id);
    FirstRelicCombat_koma_props_len.write(combat_id, account, len + 1);
    FirstRelicCombat_komas.write(combat_id, account, koma_updated);

    return ();
}

func FirstRelicCombat_get_koma_props{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(combat_id: felt, account: felt) -> (data_len: felt, data: Prop*) {
    alloc_locals;

    let (len) = FirstRelicCombat_koma_props_len.read(combat_id, account);
    let (local data: Prop*) = alloc();
    _get_koma_props(combat_id, account, 0, len, data);

    return (len, data);
}

// recursively get props array
func _get_koma_props{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, index: felt, data_len: felt, data: Prop*
) {
    if (data_len == 0) {
        return ();
    }

    let (prop_id) = FirstRelicCombat_koma_props_id_by_index.read(combat_id, account, index);
    let (prop) = FirstRelicCombat_props.read(combat_id, prop_id);
    assert data[index] = prop;
    _get_koma_props(combat_id, account, index + 1, data_len - 1, data);

    return ();
}

func FirstRelicCombat_use_prop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, prop_id: felt
) {
    alloc_locals;

    let (prop) = FirstRelicCombat_props.read(combat_id, prop_id);
    with_attr error_message("FirstRelicCombat: prop invalid") {
        assert_not_zero(prop.prop_creature_id);
    }

    let (prop_owner) = FirstRelicCombat_props_owner.read(combat_id, prop_id);
    with_attr error_message("FirstRelicCombat: prop not owned") {
        assert account = prop_owner;
    }

    with_attr error_message("FirstRelicCombat: prop not owned") {
        assert prop.used_timetamp = 0;
    }

    let (block_timestamp) = get_block_timestamp();
    let prop_updated = Prop(prop.prop_id, prop.prop_creature_id, block_timestamp, 0);
    FirstRelicCombat_props.write(combat_id, prop_id, prop_updated);
    let (props_len) = FirstRelicCombat_koma_props_len.read(combat_id, account);
    if (props_len == 1) {
        FirstRelicCombat_koma_props_len.write(combat_id, account, 0);
    } else {
        let (last_prop_id) = FirstRelicCombat_koma_props_id_by_index.read(
            combat_id, account, props_len - 1
        );
        FirstRelicCombat_koma_props_id_by_index.write(
            combat_id, account, prop.index_in_koma_props, last_prop_id
        );
        FirstRelicCombat_koma_props_len.write(combat_id, account, props_len - 1);
    }

    if (prop.prop_creature_id == PROP_CREATURE_SHIELD) {
        _prop_effect_use(combat_id, account, PROP_CREATURE_SHIELD);
        return ();
    }

    if (prop.prop_creature_id == PROP_CREATURE_HEALTH_KIT) {
        _use_health_kit(combat_id, account);
        return ();
    }

    if (prop.prop_creature_id == PROP_CREATURE_MAX_HEALTH_UP_10) {
        _use_max_health_up_10(combat_id, account);
        return ();
    }

    with_attr error_message("FirstRelicCombat: prop is unuseable") {
        assert 0 = 1;
    }

    return ();
}

func FirstRelicCombat_equip_prop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, prop_id: felt
) {
    alloc_locals;

    let (prop) = FirstRelicCombat_props.read(combat_id, prop_id);
    let (equip_part) = _get_equip_part(prop.prop_creature_id);
    with_attr error_message("FirstRelicCombat: prop invalid") {
        assert_not_zero(prop.prop_creature_id);
    }

    let (prop_owner) = FirstRelicCombat_props_owner.read(combat_id, prop_id);
    with_attr error_message("FirstRelicCombat: prop not owned") {
        assert account = prop_owner;
    }

    with_attr error_message("FirstRelicCombat: prop used") {
        assert prop.used_timetamp = 0;
    }

    let (block_timestamp) = get_block_timestamp();
    let prop_updated = Prop(prop.prop_id, prop.prop_creature_id, block_timestamp, 0);
    FirstRelicCombat_props.write(combat_id, prop_id, prop_updated);
    let (props_len) = FirstRelicCombat_koma_props_len.read(combat_id, account);
    if (props_len == 1) {
        FirstRelicCombat_koma_props_len.write(combat_id, account, 0);
    } else {
        let (last_prop_id) = FirstRelicCombat_koma_props_id_by_index.read(
            combat_id, account, props_len - 1
        );
        FirstRelicCombat_koma_props_id_by_index.write(
            combat_id, account, prop.index_in_koma_props, last_prop_id
        );
        FirstRelicCombat_koma_props_len.write(combat_id, account, props_len - 1);
    }

    let (equiped_prop_id) = FirstRelicCombat_koma_equipments.read(combat_id, account, equip_part);
    if (equiped_prop_id != 0) {
        // put into prop bag
        let (equiped_prop) = FirstRelicCombat_props.read(combat_id, equiped_prop_id);
        let (props_len) = FirstRelicCombat_koma_props_len.read(combat_id, account);
        let equiped_prop_updated = Prop(
            equiped_prop.prop_id, equiped_prop.prop_creature_id, 0, props_len
        );
        FirstRelicCombat_props.write(combat_id, equiped_prop.prop_id, equiped_prop_updated);
        FirstRelicCombat_koma_props_id_by_index.write(
            combat_id, account, props_len, equiped_prop.prop_id
        );
        FirstRelicCombat_koma_props_len.write(combat_id, account, props_len + 1);
        FirstRelicCombat_koma_equipments.write(combat_id, account, equip_part, prop_id);
        _equip_off(combat_id, account, equiped_prop.prop_creature_id);
        _equip_on(combat_id, account, prop.prop_creature_id);
    } else {
        FirstRelicCombat_koma_equipments.write(combat_id, account, equip_part, prop_id);
        _equip_on(combat_id, account, prop.prop_creature_id);
    }

    return ();
}

func FirstRelicCombat_get_koma_equipments{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(combat_id: felt, account: felt) -> (equipments: KomaEquipments) {
    let (engine_prop_id) = FirstRelicCombat_koma_equipments.read(
        combat_id, account, PROP_EQUIPMENT_PART_ENGINE
    );
    let (engine) = FirstRelicCombat_props.read(combat_id, engine_prop_id);

    let (shoe_prop_id) = FirstRelicCombat_koma_equipments.read(
        combat_id, account, PROP_EQUIPMENT_PART_SHOE
    );
    let (shoe) = FirstRelicCombat_props.read(combat_id, shoe_prop_id);

    let (weapon_prop_id) = FirstRelicCombat_koma_equipments.read(
        combat_id, account, PROP_EQUIPMENT_PART_WEAPON
    );
    let (weapon) = FirstRelicCombat_props.read(combat_id, weapon_prop_id);

    let (armor_prop_id) = FirstRelicCombat_koma_equipments.read(
        combat_id, account, PROP_EQUIPMENT_PART_ARMOR
    );
    let (armor) = FirstRelicCombat_props.read(combat_id, armor_prop_id);

    let equipments = KomaEquipments(account, engine, shoe, weapon, armor);

    return (equipments,);
}

func FirstRelicCombat_get_koma_prop_effect_creature_ids{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(combat_id: felt, account: felt) -> (data_len: felt, data: felt*) {
    alloc_locals;

    let (len) = FirstRelicCombat_koma_props_effect_creature_id_len.read(combat_id, account);
    let (local data: felt*) = alloc();
    _get_koma_prop_effect_creature_ids(combat_id, account, 0, len, data);

    return (len, data);
}

func _get_prop_weight{range_check_ptr}(prop_creature_id: felt) -> (prop_weight: felt) {
    let (prop_type, r) = unsigned_div_rem(prop_creature_id, 10 ** 8);
    if (prop_type == PROP_TYPE_EQUIPMENT) {
        return (PROP_WEIGHT_EQUIPMENTS,);
    } else {
        return (PROP_WEIGHT_OTHERS,);
    }
}

func _get_equip_part{range_check_ptr}(prop_creature_id: felt) -> (equip_part: felt) {
    let (prop_type, r) = unsigned_div_rem(prop_creature_id, 10 ** 8);
    with_attr error_message("FirstRelicCombat: prop is not a equipment") {
        assert prop_type = PROP_TYPE_EQUIPMENT;
    }

    let (equip_part, _) = unsigned_div_rem(r, 10 ** 7);
    with_attr error_message("FirstRelicCombat: equipment part invalid") {
        assert_le_felt(1, equip_part);
        assert_le_felt(equip_part, 4);
    }

    return (equip_part,);
}

// for useable and have consistent effect props
func _prop_effect_use{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, prop_creature_id: felt
) {
    alloc_locals;

    let (prop_effect) = FirstRelicCombat_koma_props_effect.read(
        combat_id, account, prop_creature_id
    );
    let (len) = FirstRelicCombat_koma_props_effect_creature_id_len.read(combat_id, account);
    let (index) = max(prop_effect.index_in_koma_effects, len);
    let (block_timestamp) = get_block_timestamp();
    local new_len;
    if (prop_effect.prop_creature_id == 0) {
        new_len = len + 1;
    } else {
        new_len = len;
    }

    let prop_effect_updated = PropEffect(
        prop_creature_id=prop_creature_id,
        index_in_koma_effects=index,
        used_timetamp=block_timestamp,
    );
    FirstRelicCombat_koma_props_effect.write(
        combat_id, account, prop_creature_id, prop_effect_updated
    );
    FirstRelicCombat_koma_props_effect_creature_id_len.write(combat_id, account, new_len);
    FirstRelicCombat_koma_props_effect_creature_id_by_index.write(
        combat_id, account, index, prop_creature_id
    );

    return ();
}

func _use_health_kit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) {
    alloc_locals;

    let (koma) = FirstRelicCombat_komas.read(combat_id, account);
    let (now_health) = min(koma.health + 50, koma.max_health);
    let koma_updated = Koma(
        koma.account,
        koma.coordinate,
        koma.status,
        now_health,
        koma.max_health,
        koma.agility,
        koma.move_speed,
        koma.props_weight,
        koma.props_max_weight,
        koma.workers_count,
        koma.mining_workers_count,
        koma.drones_count,
        koma.action_radius,
        koma.element,
        koma.ore_amount,
        koma.atk,
        koma.defense,
        koma.worker_mining_speed,
    );
    FirstRelicCombat_komas.write(combat_id, account, koma_updated);

    return ();
}

func _use_max_health_up_10{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) {
    let (koma) = FirstRelicCombat_komas.read(combat_id, account);
    let koma_updated = Koma(
        koma.account,
        koma.coordinate,
        koma.status,
        koma.health,
        koma.max_health + 10,
        koma.agility,
        koma.move_speed,
        koma.props_weight,
        koma.props_max_weight,
        koma.workers_count,
        koma.mining_workers_count,
        koma.drones_count,
        koma.action_radius,
        koma.element,
        koma.ore_amount,
        koma.atk,
        koma.defense,
        koma.worker_mining_speed,
    );
    FirstRelicCombat_komas.write(combat_id, account, koma_updated);

    return ();
}

func _equip_on{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, prop_creature_id: felt
) {
    alloc_locals;

    let (koma) = FirstRelicCombat_komas.read(combat_id, account);
    let (local koma_updated: Koma*) = alloc();

    if (prop_creature_id == PROP_CREATURE_ENGINE) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed + 5, koma.props_weight - PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed
            );
    }

    if (prop_creature_id == PROP_CREATURE_SHOE) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility + 5, koma.move_speed, koma.props_weight - PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed
            );
    }

    if (prop_creature_id == PROP_CREATURE_LASER_GUN) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed, koma.props_weight - PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk + 5, koma.defense, koma.worker_mining_speed
            );
    }

    if (prop_creature_id == PROP_CREATURE_DRILL) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed, koma.props_weight - PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed + 100
            );
    }

    if (prop_creature_id == PROP_CREATURE_ARMOR) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed, koma.props_weight - PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk, koma.defense + 5, koma.worker_mining_speed
            );
    }

    FirstRelicCombat_komas.write(combat_id, account, koma_updated[0]);

    return ();
}

func _equip_off{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, prop_creature_id: felt
) {
    alloc_locals;

    let (koma) = FirstRelicCombat_komas.read(combat_id, account);
    let (local koma_updated: Koma*) = alloc();

    if (prop_creature_id == PROP_CREATURE_ENGINE) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed - 5, koma.props_weight + PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed
            );
    }

    if (prop_creature_id == PROP_CREATURE_SHOE) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility - 5, koma.move_speed, koma.props_weight + PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed
            );
    }

    if (prop_creature_id == PROP_CREATURE_LASER_GUN) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed, koma.props_weight + PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk - 5, koma.defense, koma.worker_mining_speed
            );
    }

    if (prop_creature_id == PROP_CREATURE_DRILL) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed, koma.props_weight + PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed - 100
            );
    }

    if (prop_creature_id == PROP_CREATURE_ARMOR) {
        assert koma_updated[0] = Koma(
            koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed, koma.props_weight + PROP_WEIGHT_EQUIPMENTS,
            koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count, koma.action_radius, koma.element,
            koma.ore_amount, koma.atk, koma.defense - 5, koma.worker_mining_speed
            );
    }

    FirstRelicCombat_komas.write(combat_id, account, koma_updated[0]);

    return ();
}

func _get_koma_prop_effect_creature_ids{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(combat_id: felt, account: felt, index: felt, len: felt, data: felt*) {
    if (index == len) {
        return ();
    }

    let (id) = FirstRelicCombat_koma_props_effect_creature_id_by_index.read(
        combat_id, account, index
    );
    assert data[index] = id;

    _get_koma_prop_effect_creature_ids(combat_id, account, index + 1, len, data);
    return ();
}

func _generate_chest_options{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    random_seed: felt, options_len: felt, options: felt*, props_pool_len: felt
) -> (next_seed: felt) {
    alloc_locals;

    if (options_len == 3) {
        return (random_seed,);
    }

    let (index, next_seed) = get_random_number_and_seed(random_seed, props_pool_len);
    let (res) = felt_in_array(index, options_len, options);
    if (res == TRUE) {
        return _generate_chest_options(next_seed, options_len, options, props_pool_len);
    }

    assert options[options_len] = index;
    return _generate_chest_options(next_seed, options_len + 1, options, props_pool_len);
}
