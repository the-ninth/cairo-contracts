%lang starknet

const COMBAT_STATUS_NON_EXIST = 0
const COMBAT_STATUS_REGISTERING = 1
const COMBAT_STATUS_PREPARING = 2
const COMBAT_STATUS_FIRST_STAGE = 3
const COMBAT_STATUS_SECOND_STAGE = 4
const COMBAT_STATUS_THIRD_STAGE = 5
const COMBAT_STATUS_END = 6

const KOMA_STATUS_STATIC = 1
const KOMA_STATUS_MOVING = 2
const KOMA_STATUS_MINING = 3
const KOMA_STATUS_THIRD_STAGE = 4
const KOMA_STATUS_DEAD = 5

struct Combat:
    member prepare_time: felt
    member first_stage_time: felt
    member second_stage_time: felt
    member third_stage_time: felt
    member end_time: felt
    member expire_time: felt
    member status: felt
end

struct Coordinate:
    member x: felt
    member y: felt
end

struct Koma:
    member account: felt
    member coordinate: Coordinate
    member status: felt
    member health: felt
    member max_health: felt
    member agility: felt
    member move_speed: felt
    member props_weight: felt
    member props_max_weight: felt
    member workers_count: felt
    member mining_workers_count: felt
    member drones_count: felt
    member action_radius: felt
    member element: felt
    member ore_amount: felt
    member atk: felt
    member defense: felt
    member worker_mining_speed: felt
end

struct KomaEquip:
    member weapon: felt
    member armor: felt
    member agility: felt
    member speed: felt
end

struct Chest:
    member coordinate: Coordinate
    member opener: felt
    member option_selected: felt # based on 1
end

struct Prop:
    member prop_id: felt
    member prop_creature_id: felt
    member used_timetamp: felt
    member index_in_koma_props: felt
end

struct PropEffect:
    member prop_creature_id: felt
    member index_in_koma_effects: felt
    member used_timetamp: felt
end

struct Ore:
    member coordinate: Coordinate
    member total_supply: felt
    member mined_supply: felt
    member mining_workers_count: felt
    member start_time: felt
    member empty_time: felt
end

struct Boss:
    member health: felt
    member defense: felt
    member agility: felt
    member multi_targets: felt
    member element: felt
end

struct ThirdStageAction:
    member type: felt
    member target: felt # 0 for boss, others for players
    member round: felt
    member salt: felt
end

struct Movment:
    member from_: Coordinate
    member to: Coordinate
    member start_time: felt # timestamp starting to move
    member reach_time: felt # timestamp reaching the target location
end

struct KomaMiningOre:
    member coordinate: Coordinate
    member mining_workers_count: felt
    member start_time: felt
end

struct KomaEquipments:
    member account: felt
    member engine: Prop
    member shoe: Prop
    member weapon: Prop
    member armor: Prop
end

struct RelicGate:
    member coordinate: Coordinate
    member number: felt
    member require_creature_id: felt
    member account: felt
end

struct CoordinateRange:
    member x0: felt
    member x1: felt
    member y0: felt
    member y1: felt
end