%lang starknet

from starkware.cairo.common.registers import get_label_location

from contracts.pvp.first_relic.structs import Coordinate, CoordinateRange

const REGISTER_FEE = 5000000000000000000;
const MANAGEMENT_FEE_RATE = 50;

const MAP_WIDTH = 40;
const MAP_HEIGHT = 25;
const MAP_INNER_AREA_WIDTH = 10;
const MAP_INNER_AREA_HEIGHT = 10;
const CHEST_PER_PLAYER = 3;
const ORE_PER_PLAYER = 3;
const PREPARE_TIME = 60;  // how much time for preparation time
const FIRST_STAGE_DURATION = 900;
const SECOND_STAGE_DURATION = 300;
const ORE_STRUCTURE_HP_PER_WORKER = 100;
const ORE_STRUCTURE_DEFENSE = 7;

const KOMA_MOVING_SPEED = 20;
const KOMA_ATK = 7;
const KOMA_DEFENSE = 15;
const WORKER_MINING_SPEED = 200;
const KOMA_MAX_PROP_WEIGHT = 100;

const BOT_TYPE_WORKER = 1;
const BOT_TYPE_DRONE = 2;

const CHEST_SELECTION = 3;

const PROP_TYPE_USEABLE = 1;
const PROP_TYPE_UNUSEABLE = 2;
const PROP_TYPE_EQUIPMENT = 3;

const PROP_WEIGHT_EQUIPMENTS = 30;
const PROP_WEIGHT_OTHERS = 20;

// useable props
const PROP_CREATURE_SHIELD = 100000001;
const PROP_CREATURE_ATTACK_UP_30P = 100000002;
const PROP_CREATURE_DAMAGE_DOWN_30P = 100000003;
const PROP_CREATURE_HEALTH_KIT = 100000004;
const PROP_CREATURE_MAX_HEALTH_UP_10 = 100000005;

// unuseable props
const PROP_CREATURE_STAGE2_KEY1 = 200000001;
const PROP_CREATURE_STAGE2_KEY2 = 200000002;
const PROP_CREATURE_STAGE2_KEY3 = 200000003;
const PROP_CREATURE_STAGE2_KEY4 = 200000004;
const PROP_CREATURE_STAGE2_KEY5 = 200000005;
const PROP_CREATURE_STAGE2_KEY6 = 200000006;
const PROP_CREATURE_STAGE2_KEY7 = 200000007;
const PROP_CREATURE_STAGE2_KEY8 = 200000008;
const PROP_CREATURE_STAGE2_KEY9 = 200000009;

// equipments
const PROP_CREATURE_ENGINE = 310000001;
const PROP_CREATURE_SHOE = 320000001;
const PROP_CREATURE_LASER_GUN = 330000001;
const PROP_CREATURE_DRILL = 330000002;
const PROP_CREATURE_ARMOR = 340000001;

const PROP_EQUIPMENT_PART_ENGINE = 1;
const PROP_EQUIPMENT_PART_SHOE = 2;
const PROP_EQUIPMENT_PART_WEAPON = 3;
const PROP_EQUIPMENT_PART_ARMOR = 4;

func get_props_pool() -> (props_pool_len: felt, props_pool: felt*) {
    let (pool_address) = get_label_location(props_pool);

    return (19, cast(pool_address, felt*));

    props_pool:
    dw PROP_CREATURE_SHIELD;
    dw PROP_CREATURE_ATTACK_UP_30P;
    dw PROP_CREATURE_DAMAGE_DOWN_30P;
    dw PROP_CREATURE_HEALTH_KIT;
    dw PROP_CREATURE_MAX_HEALTH_UP_10;
    dw PROP_CREATURE_STAGE2_KEY1;
    dw PROP_CREATURE_STAGE2_KEY2;
    dw PROP_CREATURE_STAGE2_KEY3;
    dw PROP_CREATURE_STAGE2_KEY4;
    dw PROP_CREATURE_STAGE2_KEY5;
    dw PROP_CREATURE_STAGE2_KEY6;
    dw PROP_CREATURE_STAGE2_KEY7;
    dw PROP_CREATURE_STAGE2_KEY8;
    dw PROP_CREATURE_STAGE2_KEY9;
    dw PROP_CREATURE_ENGINE;
    dw PROP_CREATURE_SHOE;
    dw PROP_CREATURE_LASER_GUN;
    dw PROP_CREATURE_DRILL;
    dw PROP_CREATURE_ARMOR;
}

func get_equipments() -> (equipments_len: felt, equipments: felt*) {
    let (equipments_address) = get_label_location(equipments);

    return (5, cast(equipments_address, felt*));

    equipments:
    dw PROP_CREATURE_ENGINE;
    dw PROP_CREATURE_SHOE;
    dw PROP_CREATURE_LASER_GUN;
    dw PROP_CREATURE_DRILL;
    dw PROP_CREATURE_ARMOR;
}

func get_relic_gate_key_ids() -> (key_ids_len: felt, key_ids: felt*) {
    let (ids_address) = get_label_location(gate_ids);

    return (9, cast(ids_address, felt*));

    gate_ids:
    dw PROP_CREATURE_STAGE2_KEY1;
    dw PROP_CREATURE_STAGE2_KEY2;
    dw PROP_CREATURE_STAGE2_KEY3;
    dw PROP_CREATURE_STAGE2_KEY4;
    dw PROP_CREATURE_STAGE2_KEY5;
    dw PROP_CREATURE_STAGE2_KEY6;
    dw PROP_CREATURE_STAGE2_KEY7;
    dw PROP_CREATURE_STAGE2_KEY8;
    dw PROP_CREATURE_STAGE2_KEY9;
}

func get_outer_coordinate_ranges() -> (ranges_len: felt, ranges: CoordinateRange*) {
    let (ranges_address) = get_label_location(coordinate_ranges);

    return (8, cast(ranges_address, CoordinateRange*));

    coordinate_ranges:
    // left * 3
    dw 0;
    dw 8113;
    dw 0;
    dw 11900;
    dw 0;
    dw 8113;
    dw 0;
    dw 11900;
    dw 0;
    dw 8113;
    dw 0;
    dw 11900;
    // bottom
    dw 8113;
    dw 12613;
    dw 0;
    dw 4450;
    // top
    dw 8113;
    dw 12613;
    dw 7450;
    dw 11900;
    // right * 3
    dw 12613;
    dw 20727;
    dw 0;
    dw 11900;
    dw 12613;
    dw 20727;
    dw 0;
    dw 11900;
    dw 12613;
    dw 20727;
    dw 0;
    dw 11900;
}

func get_valid_coordinates() -> (data_len: felt, data: Coordinate*) {
    let (coordinates_address) = get_label_location(coordinates);

    return (483, cast(coordinates_address, Coordinate*));

    coordinates:
    dw 0;
    dw 0;
    dw 0;
    dw 1;
    dw 0;
    dw 3;
    dw 0;
    dw 4;
    dw 0;
    dw 6;
    dw 0;
    dw 7;
    dw 0;
    dw 8;
    dw 0;
    dw 9;
    dw 0;
    dw 10;
    dw 0;
    dw 11;
    dw 0;
    dw 13;
    dw 0;
    dw 14;
    dw 0;
    dw 15;
    dw 0;
    dw 16;
    dw 0;
    dw 22;
    dw 0;
    dw 24;
    dw 1;
    dw 0;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 1;
    dw 4;
    dw 1;
    dw 6;
    dw 1;
    dw 7;
    dw 1;
    dw 8;
    dw 1;
    dw 10;
    dw 1;
    dw 11;
    dw 1;
    dw 13;
    dw 1;
    dw 14;
    dw 1;
    dw 16;
    dw 1;
    dw 22;
    dw 1;
    dw 24;
    dw 2;
    dw 0;
    dw 2;
    dw 1;
    dw 2;
    dw 3;
    dw 2;
    dw 4;
    dw 2;
    dw 10;
    dw 2;
    dw 11;
    dw 2;
    dw 16;
    dw 2;
    dw 22;
    dw 2;
    dw 24;
    dw 3;
    dw 0;
    dw 3;
    dw 1;
    dw 3;
    dw 2;
    dw 3;
    dw 3;
    dw 3;
    dw 4;
    dw 3;
    dw 7;
    dw 3;
    dw 8;
    dw 3;
    dw 11;
    dw 3;
    dw 14;
    dw 3;
    dw 16;
    dw 3;
    dw 18;
    dw 3;
    dw 19;
    dw 3;
    dw 20;
    dw 3;
    dw 21;
    dw 3;
    dw 22;
    dw 3;
    dw 24;
    dw 4;
    dw 0;
    dw 4;
    dw 1;
    dw 4;
    dw 3;
    dw 4;
    dw 4;
    dw 4;
    dw 7;
    dw 4;
    dw 8;
    dw 4;
    dw 11;
    dw 4;
    dw 14;
    dw 4;
    dw 16;
    dw 4;
    dw 17;
    dw 4;
    dw 18;
    dw 4;
    dw 19;
    dw 4;
    dw 20;
    dw 4;
    dw 21;
    dw 4;
    dw 22;
    dw 4;
    dw 24;
    dw 5;
    dw 0;
    dw 5;
    dw 1;
    dw 5;
    dw 3;
    dw 5;
    dw 4;
    dw 5;
    dw 5;
    dw 5;
    dw 6;
    dw 5;
    dw 7;
    dw 5;
    dw 8;
    dw 5;
    dw 11;
    dw 5;
    dw 14;
    dw 5;
    dw 16;
    dw 5;
    dw 18;
    dw 5;
    dw 19;
    dw 5;
    dw 22;
    dw 5;
    dw 24;
    dw 6;
    dw 0;
    dw 6;
    dw 1;
    dw 6;
    dw 3;
    dw 6;
    dw 5;
    dw 6;
    dw 6;
    dw 6;
    dw 8;
    dw 6;
    dw 11;
    dw 6;
    dw 13;
    dw 6;
    dw 14;
    dw 6;
    dw 18;
    dw 6;
    dw 19;
    dw 6;
    dw 22;
    dw 6;
    dw 24;
    dw 7;
    dw 0;
    dw 7;
    dw 1;
    dw 7;
    dw 8;
    dw 7;
    dw 10;
    dw 7;
    dw 11;
    dw 7;
    dw 13;
    dw 7;
    dw 14;
    dw 7;
    dw 18;
    dw 7;
    dw 19;
    dw 7;
    dw 22;
    dw 7;
    dw 24;
    dw 8;
    dw 0;
    dw 8;
    dw 1;
    dw 8;
    dw 2;
    dw 8;
    dw 3;
    dw 8;
    dw 8;
    dw 8;
    dw 9;
    dw 8;
    dw 10;
    dw 8;
    dw 11;
    dw 8;
    dw 13;
    dw 8;
    dw 16;
    dw 8;
    dw 18;
    dw 8;
    dw 22;
    dw 8;
    dw 23;
    dw 8;
    dw 24;
    dw 9;
    dw 0;
    dw 9;
    dw 1;
    dw 9;
    dw 2;
    dw 9;
    dw 3;
    dw 9;
    dw 8;
    dw 9;
    dw 9;
    dw 9;
    dw 10;
    dw 9;
    dw 11;
    dw 9;
    dw 12;
    dw 9;
    dw 13;
    dw 9;
    dw 14;
    dw 9;
    dw 16;
    dw 9;
    dw 18;
    dw 9;
    dw 19;
    dw 9;
    dw 22;
    dw 9;
    dw 24;
    dw 10;
    dw 0;
    dw 10;
    dw 1;
    dw 10;
    dw 2;
    dw 10;
    dw 3;
    dw 10;
    dw 9;
    dw 10;
    dw 11;
    dw 10;
    dw 12;
    dw 10;
    dw 14;
    dw 10;
    dw 15;
    dw 10;
    dw 16;
    dw 10;
    dw 18;
    dw 10;
    dw 19;
    dw 10;
    dw 21;
    dw 10;
    dw 22;
    dw 11;
    dw 0;
    dw 11;
    dw 1;
    dw 11;
    dw 2;
    dw 11;
    dw 3;
    dw 11;
    dw 12;
    dw 11;
    dw 16;
    dw 11;
    dw 18;
    dw 11;
    dw 19;
    dw 11;
    dw 24;
    dw 12;
    dw 0;
    dw 12;
    dw 1;
    dw 12;
    dw 2;
    dw 12;
    dw 3;
    dw 12;
    dw 12;
    dw 12;
    dw 16;
    dw 12;
    dw 17;
    dw 12;
    dw 18;
    dw 12;
    dw 19;
    dw 12;
    dw 24;
    dw 13;
    dw 0;
    dw 13;
    dw 2;
    dw 13;
    dw 3;
    dw 13;
    dw 16;
    dw 13;
    dw 17;
    dw 13;
    dw 18;
    dw 13;
    dw 19;
    dw 13;
    dw 20;
    dw 13;
    dw 21;
    dw 13;
    dw 22;
    dw 13;
    dw 24;
    dw 14;
    dw 0;
    dw 14;
    dw 11;
    dw 14;
    dw 12;
    dw 14;
    dw 15;
    dw 14;
    dw 16;
    dw 14;
    dw 18;
    dw 14;
    dw 19;
    dw 14;
    dw 20;
    dw 14;
    dw 22;
    dw 14;
    dw 23;
    dw 14;
    dw 24;
    dw 15;
    dw 0;
    dw 15;
    dw 11;
    dw 15;
    dw 12;
    dw 15;
    dw 14;
    dw 15;
    dw 15;
    dw 15;
    dw 16;
    dw 15;
    dw 23;
    dw 15;
    dw 24;
    dw 16;
    dw 0;
    dw 16;
    dw 11;
    dw 16;
    dw 12;
    dw 16;
    dw 14;
    dw 16;
    dw 16;
    dw 16;
    dw 22;
    dw 16;
    dw 23;
    dw 16;
    dw 24;
    dw 17;
    dw 12;
    dw 17;
    dw 13;
    dw 17;
    dw 14;
    dw 17;
    dw 16;
    dw 17;
    dw 18;
    dw 17;
    dw 19;
    dw 17;
    dw 20;
    dw 17;
    dw 22;
    dw 17;
    dw 23;
    dw 17;
    dw 24;
    dw 18;
    dw 2;
    dw 18;
    dw 3;
    dw 18;
    dw 18;
    dw 18;
    dw 19;
    dw 18;
    dw 20;
    dw 18;
    dw 21;
    dw 18;
    dw 22;
    dw 19;
    dw 2;
    dw 19;
    dw 3;
    dw 19;
    dw 18;
    dw 19;
    dw 19;
    dw 19;
    dw 22;
    dw 20;
    dw 2;
    dw 20;
    dw 3;
    dw 20;
    dw 5;
    dw 20;
    dw 11;
    dw 20;
    dw 22;
    dw 21;
    dw 2;
    dw 21;
    dw 3;
    dw 21;
    dw 4;
    dw 21;
    dw 5;
    dw 21;
    dw 11;
    dw 21;
    dw 22;
    dw 22;
    dw 0;
    dw 22;
    dw 1;
    dw 22;
    dw 2;
    dw 22;
    dw 4;
    dw 22;
    dw 5;
    dw 22;
    dw 8;
    dw 22;
    dw 11;
    dw 22;
    dw 17;
    dw 22;
    dw 18;
    dw 22;
    dw 19;
    dw 22;
    dw 21;
    dw 22;
    dw 22;
    dw 22;
    dw 24;
    dw 23;
    dw 0;
    dw 23;
    dw 1;
    dw 23;
    dw 2;
    dw 23;
    dw 4;
    dw 23;
    dw 5;
    dw 23;
    dw 8;
    dw 23;
    dw 9;
    dw 23;
    dw 11;
    dw 23;
    dw 12;
    dw 23;
    dw 17;
    dw 23;
    dw 18;
    dw 23;
    dw 19;
    dw 23;
    dw 21;
    dw 23;
    dw 22;
    dw 23;
    dw 24;
    dw 24;
    dw 4;
    dw 24;
    dw 5;
    dw 24;
    dw 9;
    dw 24;
    dw 11;
    dw 24;
    dw 12;
    dw 24;
    dw 17;
    dw 24;
    dw 18;
    dw 24;
    dw 19;
    dw 24;
    dw 21;
    dw 24;
    dw 22;
    dw 24;
    dw 23;
    dw 24;
    dw 24;
    dw 25;
    dw 0;
    dw 25;
    dw 1;
    dw 25;
    dw 2;
    dw 25;
    dw 3;
    dw 25;
    dw 4;
    dw 25;
    dw 5;
    dw 25;
    dw 9;
    dw 25;
    dw 11;
    dw 25;
    dw 19;
    dw 25;
    dw 21;
    dw 25;
    dw 22;
    dw 25;
    dw 23;
    dw 25;
    dw 24;
    dw 26;
    dw 0;
    dw 26;
    dw 1;
    dw 26;
    dw 3;
    dw 26;
    dw 4;
    dw 26;
    dw 5;
    dw 26;
    dw 6;
    dw 26;
    dw 9;
    dw 26;
    dw 11;
    dw 26;
    dw 12;
    dw 26;
    dw 15;
    dw 26;
    dw 19;
    dw 26;
    dw 24;
    dw 27;
    dw 0;
    dw 27;
    dw 1;
    dw 27;
    dw 5;
    dw 27;
    dw 6;
    dw 27;
    dw 8;
    dw 27;
    dw 9;
    dw 27;
    dw 10;
    dw 27;
    dw 11;
    dw 27;
    dw 12;
    dw 27;
    dw 15;
    dw 27;
    dw 17;
    dw 27;
    dw 18;
    dw 27;
    dw 19;
    dw 27;
    dw 24;
    dw 28;
    dw 0;
    dw 28;
    dw 1;
    dw 28;
    dw 5;
    dw 28;
    dw 6;
    dw 28;
    dw 7;
    dw 28;
    dw 8;
    dw 28;
    dw 9;
    dw 28;
    dw 11;
    dw 28;
    dw 15;
    dw 28;
    dw 17;
    dw 28;
    dw 18;
    dw 28;
    dw 19;
    dw 28;
    dw 21;
    dw 28;
    dw 22;
    dw 28;
    dw 23;
    dw 28;
    dw 24;
    dw 29;
    dw 0;
    dw 29;
    dw 1;
    dw 29;
    dw 5;
    dw 29;
    dw 6;
    dw 29;
    dw 7;
    dw 29;
    dw 9;
    dw 29;
    dw 11;
    dw 29;
    dw 12;
    dw 29;
    dw 14;
    dw 29;
    dw 15;
    dw 29;
    dw 16;
    dw 29;
    dw 17;
    dw 29;
    dw 18;
    dw 29;
    dw 19;
    dw 29;
    dw 20;
    dw 29;
    dw 21;
    dw 29;
    dw 22;
    dw 29;
    dw 24;
    dw 30;
    dw 0;
    dw 30;
    dw 1;
    dw 30;
    dw 6;
    dw 30;
    dw 7;
    dw 30;
    dw 9;
    dw 30;
    dw 11;
    dw 30;
    dw 12;
    dw 30;
    dw 13;
    dw 30;
    dw 14;
    dw 30;
    dw 17;
    dw 30;
    dw 20;
    dw 30;
    dw 21;
    dw 30;
    dw 22;
    dw 30;
    dw 24;
    dw 31;
    dw 0;
    dw 31;
    dw 1;
    dw 31;
    dw 6;
    dw 31;
    dw 7;
    dw 31;
    dw 9;
    dw 31;
    dw 11;
    dw 31;
    dw 13;
    dw 31;
    dw 14;
    dw 31;
    dw 17;
    dw 31;
    dw 20;
    dw 31;
    dw 21;
    dw 31;
    dw 22;
    dw 31;
    dw 24;
    dw 32;
    dw 0;
    dw 32;
    dw 1;
    dw 32;
    dw 5;
    dw 32;
    dw 6;
    dw 32;
    dw 7;
    dw 32;
    dw 9;
    dw 32;
    dw 11;
    dw 32;
    dw 17;
    dw 32;
    dw 22;
    dw 33;
    dw 5;
    dw 33;
    dw 7;
    dw 33;
    dw 9;
    dw 33;
    dw 11;
    dw 33;
    dw 22;
    dw 33;
    dw 24;
    dw 34;
    dw 0;
    dw 34;
    dw 1;
    dw 34;
    dw 3;
    dw 34;
    dw 4;
    dw 34;
    dw 5;
    dw 34;
    dw 9;
    dw 34;
    dw 11;
    dw 34;
    dw 12;
    dw 34;
    dw 13;
    dw 34;
    dw 14;
    dw 34;
    dw 16;
    dw 34;
    dw 17;
    dw 34;
    dw 19;
    dw 34;
    dw 20;
    dw 34;
    dw 21;
    dw 34;
    dw 22;
    dw 34;
    dw 24;
    dw 35;
    dw 0;
    dw 35;
    dw 1;
    dw 35;
    dw 2;
    dw 35;
    dw 3;
    dw 35;
    dw 4;
    dw 35;
    dw 5;
    dw 35;
    dw 9;
    dw 35;
    dw 11;
    dw 35;
    dw 12;
    dw 35;
    dw 14;
    dw 35;
    dw 16;
    dw 35;
    dw 17;
    dw 35;
    dw 19;
    dw 35;
    dw 21;
    dw 35;
    dw 22;
    dw 35;
    dw 24;
    dw 36;
    dw 0;
    dw 36;
    dw 1;
    dw 36;
    dw 2;
    dw 36;
    dw 3;
    dw 36;
    dw 4;
    dw 36;
    dw 5;
    dw 36;
    dw 11;
    dw 36;
    dw 12;
    dw 36;
    dw 14;
    dw 36;
    dw 15;
    dw 36;
    dw 16;
    dw 36;
    dw 17;
    dw 36;
    dw 18;
    dw 36;
    dw 19;
    dw 36;
    dw 21;
    dw 36;
    dw 22;
    dw 36;
    dw 24;
    dw 37;
    dw 0;
    dw 37;
    dw 2;
    dw 37;
    dw 3;
    dw 37;
    dw 4;
    dw 37;
    dw 5;
    dw 37;
    dw 11;
    dw 37;
    dw 15;
    dw 37;
    dw 16;
    dw 37;
    dw 18;
    dw 37;
    dw 19;
    dw 37;
    dw 20;
    dw 37;
    dw 21;
    dw 37;
    dw 22;
    dw 37;
    dw 24;
    dw 38;
    dw 0;
    dw 38;
    dw 2;
    dw 38;
    dw 3;
    dw 38;
    dw 4;
    dw 38;
    dw 5;
    dw 38;
    dw 11;
    dw 38;
    dw 12;
    dw 38;
    dw 15;
    dw 38;
    dw 16;
    dw 38;
    dw 22;
    dw 38;
    dw 24;
    dw 39;
    dw 4;
    dw 39;
    dw 5;
    dw 39;
    dw 11;
    dw 39;
    dw 12;
    dw 39;
    dw 15;
    dw 39;
    dw 16;
    dw 39;
    dw 22;
    dw 39;
    dw 23;
    dw 39;
    dw 24;
}

func get_outer_coordinates() -> (data_len: felt, data: Coordinate*) {
    let (coordinates_address) = get_label_location(outer_coordinates);

    return (338, cast(coordinates_address, Coordinate*));

    outer_coordinates:
    dw 0;
    dw 0;
    dw 0;
    dw 1;
    dw 0;
    dw 3;
    dw 0;
    dw 4;
    dw 0;
    dw 6;
    dw 0;
    dw 7;
    dw 0;
    dw 8;
    dw 0;
    dw 9;
    dw 0;
    dw 10;
    dw 0;
    dw 11;
    dw 0;
    dw 13;
    dw 0;
    dw 14;
    dw 0;
    dw 15;
    dw 0;
    dw 16;
    dw 1;
    dw 0;
    dw 1;
    dw 1;
    dw 1;
    dw 3;
    dw 1;
    dw 4;
    dw 1;
    dw 6;
    dw 1;
    dw 7;
    dw 1;
    dw 8;
    dw 1;
    dw 10;
    dw 1;
    dw 11;
    dw 1;
    dw 13;
    dw 1;
    dw 14;
    dw 1;
    dw 16;
    dw 2;
    dw 0;
    dw 2;
    dw 1;
    dw 2;
    dw 3;
    dw 2;
    dw 4;
    dw 2;
    dw 10;
    dw 2;
    dw 11;
    dw 2;
    dw 16;
    dw 3;
    dw 0;
    dw 3;
    dw 1;
    dw 3;
    dw 2;
    dw 3;
    dw 3;
    dw 3;
    dw 4;
    dw 3;
    dw 7;
    dw 3;
    dw 8;
    dw 3;
    dw 11;
    dw 3;
    dw 14;
    dw 3;
    dw 16;
    dw 3;
    dw 18;
    dw 3;
    dw 19;
    dw 4;
    dw 0;
    dw 4;
    dw 1;
    dw 4;
    dw 3;
    dw 4;
    dw 4;
    dw 4;
    dw 7;
    dw 4;
    dw 8;
    dw 4;
    dw 11;
    dw 4;
    dw 14;
    dw 4;
    dw 16;
    dw 4;
    dw 17;
    dw 4;
    dw 18;
    dw 4;
    dw 19;
    dw 5;
    dw 0;
    dw 5;
    dw 1;
    dw 5;
    dw 3;
    dw 5;
    dw 4;
    dw 5;
    dw 5;
    dw 5;
    dw 6;
    dw 5;
    dw 7;
    dw 5;
    dw 8;
    dw 5;
    dw 11;
    dw 5;
    dw 14;
    dw 5;
    dw 16;
    dw 5;
    dw 18;
    dw 5;
    dw 19;
    dw 6;
    dw 0;
    dw 6;
    dw 1;
    dw 6;
    dw 3;
    dw 6;
    dw 5;
    dw 6;
    dw 6;
    dw 6;
    dw 8;
    dw 6;
    dw 11;
    dw 6;
    dw 13;
    dw 6;
    dw 14;
    dw 6;
    dw 18;
    dw 6;
    dw 19;
    dw 7;
    dw 0;
    dw 7;
    dw 1;
    dw 7;
    dw 8;
    dw 7;
    dw 10;
    dw 7;
    dw 11;
    dw 7;
    dw 13;
    dw 7;
    dw 14;
    dw 7;
    dw 18;
    dw 7;
    dw 19;
    dw 8;
    dw 0;
    dw 8;
    dw 1;
    dw 8;
    dw 2;
    dw 8;
    dw 3;
    dw 8;
    dw 8;
    dw 8;
    dw 9;
    dw 8;
    dw 10;
    dw 8;
    dw 11;
    dw 8;
    dw 13;
    dw 8;
    dw 16;
    dw 8;
    dw 18;
    dw 9;
    dw 0;
    dw 9;
    dw 1;
    dw 9;
    dw 2;
    dw 9;
    dw 3;
    dw 9;
    dw 8;
    dw 9;
    dw 9;
    dw 9;
    dw 10;
    dw 9;
    dw 11;
    dw 9;
    dw 12;
    dw 9;
    dw 13;
    dw 9;
    dw 14;
    dw 9;
    dw 16;
    dw 9;
    dw 18;
    dw 9;
    dw 19;
    dw 10;
    dw 0;
    dw 10;
    dw 1;
    dw 10;
    dw 2;
    dw 10;
    dw 3;
    dw 10;
    dw 9;
    dw 10;
    dw 11;
    dw 10;
    dw 12;
    dw 10;
    dw 14;
    dw 10;
    dw 15;
    dw 10;
    dw 16;
    dw 10;
    dw 18;
    dw 10;
    dw 19;
    dw 11;
    dw 0;
    dw 11;
    dw 1;
    dw 11;
    dw 2;
    dw 11;
    dw 3;
    dw 11;
    dw 12;
    dw 11;
    dw 16;
    dw 11;
    dw 18;
    dw 11;
    dw 19;
    dw 12;
    dw 0;
    dw 12;
    dw 1;
    dw 12;
    dw 2;
    dw 12;
    dw 3;
    dw 12;
    dw 12;
    dw 12;
    dw 16;
    dw 12;
    dw 17;
    dw 12;
    dw 18;
    dw 12;
    dw 19;
    dw 13;
    dw 0;
    dw 13;
    dw 2;
    dw 13;
    dw 3;
    dw 13;
    dw 16;
    dw 13;
    dw 17;
    dw 13;
    dw 18;
    dw 13;
    dw 19;
    dw 14;
    dw 0;
    dw 14;
    dw 11;
    dw 14;
    dw 12;
    dw 14;
    dw 15;
    dw 14;
    dw 16;
    dw 14;
    dw 18;
    dw 14;
    dw 19;
    dw 15;
    dw 0;
    dw 15;
    dw 14;
    dw 15;
    dw 15;
    dw 15;
    dw 16;
    dw 16;
    dw 0;
    dw 16;
    dw 14;
    dw 16;
    dw 16;
    dw 17;
    dw 14;
    dw 17;
    dw 16;
    dw 17;
    dw 18;
    dw 17;
    dw 19;
    dw 18;
    dw 2;
    dw 18;
    dw 3;
    dw 18;
    dw 18;
    dw 18;
    dw 19;
    dw 19;
    dw 2;
    dw 19;
    dw 3;
    dw 19;
    dw 18;
    dw 19;
    dw 19;
    dw 20;
    dw 2;
    dw 20;
    dw 3;
    dw 20;
    dw 5;
    dw 21;
    dw 2;
    dw 21;
    dw 3;
    dw 21;
    dw 4;
    dw 21;
    dw 5;
    dw 22;
    dw 0;
    dw 22;
    dw 1;
    dw 22;
    dw 2;
    dw 22;
    dw 4;
    dw 22;
    dw 5;
    dw 22;
    dw 17;
    dw 22;
    dw 18;
    dw 22;
    dw 19;
    dw 23;
    dw 0;
    dw 23;
    dw 1;
    dw 23;
    dw 2;
    dw 23;
    dw 4;
    dw 23;
    dw 5;
    dw 23;
    dw 17;
    dw 23;
    dw 18;
    dw 23;
    dw 19;
    dw 24;
    dw 4;
    dw 24;
    dw 5;
    dw 24;
    dw 17;
    dw 24;
    dw 18;
    dw 24;
    dw 19;
    dw 25;
    dw 0;
    dw 25;
    dw 1;
    dw 25;
    dw 2;
    dw 25;
    dw 3;
    dw 25;
    dw 4;
    dw 25;
    dw 5;
    dw 25;
    dw 19;
    dw 26;
    dw 0;
    dw 26;
    dw 1;
    dw 26;
    dw 3;
    dw 26;
    dw 4;
    dw 26;
    dw 5;
    dw 26;
    dw 15;
    dw 26;
    dw 19;
    dw 27;
    dw 0;
    dw 27;
    dw 1;
    dw 27;
    dw 5;
    dw 27;
    dw 15;
    dw 27;
    dw 17;
    dw 27;
    dw 18;
    dw 27;
    dw 19;
    dw 28;
    dw 0;
    dw 28;
    dw 1;
    dw 28;
    dw 5;
    dw 28;
    dw 15;
    dw 28;
    dw 17;
    dw 28;
    dw 18;
    dw 28;
    dw 19;
    dw 29;
    dw 0;
    dw 29;
    dw 1;
    dw 29;
    dw 5;
    dw 29;
    dw 14;
    dw 29;
    dw 15;
    dw 29;
    dw 16;
    dw 29;
    dw 17;
    dw 29;
    dw 18;
    dw 29;
    dw 19;
    dw 30;
    dw 0;
    dw 30;
    dw 1;
    dw 30;
    dw 6;
    dw 30;
    dw 7;
    dw 30;
    dw 9;
    dw 30;
    dw 11;
    dw 30;
    dw 12;
    dw 30;
    dw 13;
    dw 30;
    dw 14;
    dw 30;
    dw 17;
    dw 31;
    dw 0;
    dw 31;
    dw 1;
    dw 31;
    dw 6;
    dw 31;
    dw 7;
    dw 31;
    dw 9;
    dw 31;
    dw 11;
    dw 31;
    dw 13;
    dw 31;
    dw 14;
    dw 31;
    dw 17;
    dw 32;
    dw 0;
    dw 32;
    dw 1;
    dw 32;
    dw 5;
    dw 32;
    dw 6;
    dw 32;
    dw 7;
    dw 32;
    dw 9;
    dw 32;
    dw 11;
    dw 32;
    dw 17;
    dw 33;
    dw 5;
    dw 33;
    dw 7;
    dw 33;
    dw 9;
    dw 33;
    dw 11;
    dw 34;
    dw 0;
    dw 34;
    dw 1;
    dw 34;
    dw 3;
    dw 34;
    dw 4;
    dw 34;
    dw 5;
    dw 34;
    dw 9;
    dw 34;
    dw 11;
    dw 34;
    dw 12;
    dw 34;
    dw 13;
    dw 34;
    dw 14;
    dw 34;
    dw 16;
    dw 34;
    dw 17;
    dw 34;
    dw 19;
    dw 35;
    dw 0;
    dw 35;
    dw 1;
    dw 35;
    dw 2;
    dw 35;
    dw 3;
    dw 35;
    dw 4;
    dw 35;
    dw 5;
    dw 35;
    dw 9;
    dw 35;
    dw 11;
    dw 35;
    dw 12;
    dw 35;
    dw 14;
    dw 35;
    dw 16;
    dw 35;
    dw 17;
    dw 35;
    dw 19;
    dw 36;
    dw 0;
    dw 36;
    dw 1;
    dw 36;
    dw 2;
    dw 36;
    dw 3;
    dw 36;
    dw 4;
    dw 36;
    dw 5;
    dw 36;
    dw 11;
    dw 36;
    dw 12;
    dw 36;
    dw 14;
    dw 36;
    dw 15;
    dw 36;
    dw 16;
    dw 36;
    dw 17;
    dw 36;
    dw 18;
    dw 36;
    dw 19;
    dw 37;
    dw 0;
    dw 37;
    dw 2;
    dw 37;
    dw 3;
    dw 37;
    dw 4;
    dw 37;
    dw 5;
    dw 37;
    dw 11;
    dw 37;
    dw 15;
    dw 37;
    dw 16;
    dw 37;
    dw 18;
    dw 37;
    dw 19;
    dw 38;
    dw 0;
    dw 38;
    dw 2;
    dw 38;
    dw 3;
    dw 38;
    dw 4;
    dw 38;
    dw 5;
    dw 38;
    dw 11;
    dw 38;
    dw 12;
    dw 38;
    dw 15;
    dw 38;
    dw 16;
    dw 39;
    dw 4;
    dw 39;
    dw 5;
    dw 39;
    dw 11;
    dw 39;
    dw 12;
    dw 39;
    dw 15;
    dw 39;
    dw 16;
}

func get_inner_coordinates() -> (data_len: felt, data: Coordinate*) {
    let (coordinates_address) = get_label_location(inner_coordinates);

    return (145, cast(coordinates_address, Coordinate*));

    inner_coordinates:
    dw 0;
    dw 22;
    dw 0;
    dw 24;
    dw 1;
    dw 22;
    dw 1;
    dw 24;
    dw 2;
    dw 22;
    dw 2;
    dw 24;
    dw 3;
    dw 20;
    dw 3;
    dw 21;
    dw 3;
    dw 22;
    dw 3;
    dw 24;
    dw 4;
    dw 20;
    dw 4;
    dw 21;
    dw 4;
    dw 22;
    dw 4;
    dw 24;
    dw 5;
    dw 22;
    dw 5;
    dw 24;
    dw 6;
    dw 22;
    dw 6;
    dw 24;
    dw 7;
    dw 22;
    dw 7;
    dw 24;
    dw 8;
    dw 22;
    dw 8;
    dw 23;
    dw 8;
    dw 24;
    dw 9;
    dw 22;
    dw 9;
    dw 24;
    dw 10;
    dw 21;
    dw 10;
    dw 22;
    dw 11;
    dw 24;
    dw 12;
    dw 24;
    dw 13;
    dw 20;
    dw 13;
    dw 21;
    dw 13;
    dw 22;
    dw 13;
    dw 24;
    dw 14;
    dw 20;
    dw 14;
    dw 22;
    dw 14;
    dw 23;
    dw 14;
    dw 24;
    dw 15;
    dw 11;
    dw 15;
    dw 12;
    dw 15;
    dw 23;
    dw 15;
    dw 24;
    dw 16;
    dw 11;
    dw 16;
    dw 12;
    dw 16;
    dw 22;
    dw 16;
    dw 23;
    dw 16;
    dw 24;
    dw 17;
    dw 12;
    dw 17;
    dw 13;
    dw 17;
    dw 20;
    dw 17;
    dw 22;
    dw 17;
    dw 23;
    dw 17;
    dw 24;
    dw 18;
    dw 20;
    dw 18;
    dw 21;
    dw 18;
    dw 22;
    dw 19;
    dw 22;
    dw 20;
    dw 11;
    dw 20;
    dw 22;
    dw 21;
    dw 11;
    dw 21;
    dw 22;
    dw 22;
    dw 8;
    dw 22;
    dw 11;
    dw 22;
    dw 21;
    dw 22;
    dw 22;
    dw 22;
    dw 24;
    dw 23;
    dw 8;
    dw 23;
    dw 9;
    dw 23;
    dw 11;
    dw 23;
    dw 12;
    dw 23;
    dw 21;
    dw 23;
    dw 22;
    dw 23;
    dw 24;
    dw 24;
    dw 9;
    dw 24;
    dw 11;
    dw 24;
    dw 12;
    dw 24;
    dw 21;
    dw 24;
    dw 22;
    dw 24;
    dw 23;
    dw 24;
    dw 24;
    dw 25;
    dw 9;
    dw 25;
    dw 11;
    dw 25;
    dw 21;
    dw 25;
    dw 22;
    dw 25;
    dw 23;
    dw 25;
    dw 24;
    dw 26;
    dw 6;
    dw 26;
    dw 9;
    dw 26;
    dw 11;
    dw 26;
    dw 12;
    dw 26;
    dw 24;
    dw 27;
    dw 6;
    dw 27;
    dw 8;
    dw 27;
    dw 9;
    dw 27;
    dw 10;
    dw 27;
    dw 11;
    dw 27;
    dw 12;
    dw 27;
    dw 24;
    dw 28;
    dw 6;
    dw 28;
    dw 7;
    dw 28;
    dw 8;
    dw 28;
    dw 9;
    dw 28;
    dw 11;
    dw 28;
    dw 21;
    dw 28;
    dw 22;
    dw 28;
    dw 23;
    dw 28;
    dw 24;
    dw 29;
    dw 6;
    dw 29;
    dw 7;
    dw 29;
    dw 9;
    dw 29;
    dw 11;
    dw 29;
    dw 12;
    dw 29;
    dw 20;
    dw 29;
    dw 21;
    dw 29;
    dw 22;
    dw 29;
    dw 24;
    dw 30;
    dw 20;
    dw 30;
    dw 21;
    dw 30;
    dw 22;
    dw 30;
    dw 24;
    dw 31;
    dw 20;
    dw 31;
    dw 21;
    dw 31;
    dw 22;
    dw 31;
    dw 24;
    dw 32;
    dw 22;
    dw 33;
    dw 22;
    dw 33;
    dw 24;
    dw 34;
    dw 20;
    dw 34;
    dw 21;
    dw 34;
    dw 22;
    dw 34;
    dw 24;
    dw 35;
    dw 21;
    dw 35;
    dw 22;
    dw 35;
    dw 24;
    dw 36;
    dw 21;
    dw 36;
    dw 22;
    dw 36;
    dw 24;
    dw 37;
    dw 20;
    dw 37;
    dw 21;
    dw 37;
    dw 22;
    dw 37;
    dw 24;
    dw 38;
    dw 22;
    dw 38;
    dw 24;
    dw 39;
    dw 22;
    dw 39;
    dw 23;
    dw 39;
    dw 24;
}
