%lang starknet

const COMBAT_STATUS_NON_EXIST = 0
const COMBAT_STATUS_REGISTERING = 1
const COMBAT_STATUS_STARTED = 2
const COMBAT_STATUS_ENDED = 3

const PLAYER_STATUS_STATIC = 0
const PLAYER_STATUS_MOVING = 1

const CHEST_TYPE_LIVE = 1
const CHEST_TYPE_EQUIP = 2
const CHEST_TYPE_CRYSTAL = 3

struct Combat:
    member max_players: felt
    member start_time: felt
    member end_time: felt
    member expire_time: felt
    member rect_size: felt
    member status: felt
end

struct Coordinate:
    member x: felt
    member y: felt
end

struct Koma:
    member coordinate: Coordinate
    member status: felt
    member health: felt
    member max_health: felt
    member agility: felt
    member move_speed: felt
    member props_weight: felt
    member props_max_weight: felt
    member workers_count: felt
    member working_workers_count: felt
    member drones_count: felt
    member action_radius: felt
    member ore_amount: felt
    member element: felt
end

struct KomaEquip:
    member weapon: felt
    member armor: felt
    member agility: felt
    member speed: felt
end

struct Chest:
    member chest_type: felt
end

struct Prop:
    member prop_id: felt
    member prop_category: felt
    member prop_creature_id: felt
    member prop_weight: felt
end

struct Ore:
    member total_supply: felt
    member mined_supply: felt
    member mining_account: felt
    member mining_workers_count: felt
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
