%lang starknet

const COMBAT_STATUS_NON_EXIST = 0;
const COMBAT_STATUS_REGISTERING = 1;
const COMBAT_STATUS_PREPARING = 2;
const COMBAT_STATUS_FIRST_STAGE = 3;
const COMBAT_STATUS_SECOND_STAGE = 4;
const COMBAT_STATUS_THIRD_STAGE = 5;
const COMBAT_STATUS_END = 6;

const KOMA_STATUS_STATIC = 1;
const KOMA_STATUS_MOVING = 2;
const KOMA_STATUS_MINING = 3;
const KOMA_STATUS_THIRD_STAGE = 4;
const KOMA_STATUS_DEAD = 5;

struct Combat {
    prepare_time: felt,
    first_stage_time: felt,
    second_stage_time: felt,
    third_stage_time: felt,
    end_time: felt,
    expire_time: felt,
    max_players: felt,
    status: felt,
}

struct Coordinate {
    x: felt,
    y: felt,
}

struct Koma {
    account: felt,
    coordinate: Coordinate,
    status: felt,
    health: felt,
    max_health: felt,
    agility: felt,
    move_speed: felt,
    props_weight: felt,
    props_max_weight: felt,
    workers_count: felt,
    mining_workers_count: felt,
    drones_count: felt,
    action_radius: felt,
    element: felt,
    ore_amount: felt,
    atk: felt,
    defense: felt,
    worker_mining_speed: felt,
}

struct KomaEquip {
    weapon: felt,
    armor: felt,
    agility: felt,
    speed: felt,
}

struct Chest {
    coordinate: Coordinate,
    opener: felt,
    option_selected: felt,  // based on 1
    id: felt,
}

struct Prop {
    prop_id: felt,
    prop_creature_id: felt,
    used_timetamp: felt,
    index_in_koma_props: felt,
}

struct PropEffect {
    prop_creature_id: felt,
    index_in_koma_effects: felt,
    used_timetamp: felt,
}

struct Ore {
    coordinate: Coordinate,
    total_supply: felt,
    current_supply: felt,
    collectable_supply: felt,
    mining_account: felt,
    mining_workers_count: felt,
    mining_speed: felt,  // how much ore mined per second by all workers on this ore
    structure_hp: felt,
    structure_max_hp: felt,
    start_time: felt,
    empty_time: felt,
}

struct Boss {
    health: felt,
    defense: felt,
    agility: felt,
    multi_targets: felt,
    element: felt,
}

struct ThirdStageAction {
    type: felt,
    target: felt,  // 0 for boss, others for players
    round: felt,
    salt: felt,
}

struct Movment {
    from_: Coordinate,
    to: Coordinate,
    start_time: felt,  // timestamp starting to move
    reach_time: felt,  // timestamp reaching the target location
}

struct KomaEquipments {
    account: felt,
    engine: Prop,
    shoe: Prop,
    weapon: Prop,
    armor: Prop,
}

struct RelicGate {
    coordinate: Coordinate,
    number: felt,
    require_creature_id: felt,
    account: felt,
}

struct CoordinateRange {
    x0: felt,
    x1: felt,
    y0: felt,
    y1: felt,
}
