%lang starknet

from starkware.cairo.common.registers import get_label_location

const MAP_WIDTH = 20727
const MAP_HEIGHT = 11900
const MAP_INNER_AREA_WIDTH = 5000
const MAP_INNER_AREA_HEIGHT = 5000
const CHEST_PER_PLAYER = 3
const ORE_PER_PLAYER = 3
const MAX_PLAYERS = 2
const PREPARE_TIME = 300 # how much time for preparation time
const FIRST_STAGE_DURATION = 600
const SECOND_STAGE_DURATION = 600

const KOMA_MOVING_SPEED = 20
const KOMA_ATK = 7
const KOMA_DEFENSE = 15
const WORKER_MINING_SPEED = 200

const BOT_TYPE_WORKER = 1
const BOT_TYPE_DRONE = 2

const CHEST_SELECTION = 3

const PROP_TYPE_USEABLE = 1
const PROP_TYPE_UNUSEABLE = 2
const PROP_TYPE_EQUIPMENT = 3

# useable props
const PROP_CREATURE_SHIELD           = 100000001
const PROP_CREATURE_ATTACK_UP_30P    = 100000002
const PROP_CREATURE_DAMAGE_DOWN_30P  = 100000003
const PROP_CREATURE_HEALTH_KIT       = 100000004
const PROP_CREATURE_MAX_HEALTH_UP_10 = 100000005

# unuseable props
const PROP_CREATURE_STAGE2_KEY1 = 200000001
const PROP_CREATURE_STAGE2_KEY2 = 200000002
const PROP_CREATURE_STAGE2_KEY3 = 200000003
const PROP_CREATURE_STAGE2_KEY4 = 200000004
const PROP_CREATURE_STAGE2_KEY5 = 200000005
const PROP_CREATURE_STAGE2_KEY6 = 200000006
const PROP_CREATURE_STAGE2_KEY7 = 200000007
const PROP_CREATURE_STAGE2_KEY8 = 200000008
const PROP_CREATURE_STAGE2_KEY9 = 200000009

# equipments
const PROP_CREATURE_ENGINE    = 310000001
const PROP_CREATURE_SHOE      = 320000001
const PROP_CREATURE_LASER_GUN = 330000001
const PROP_CREATURE_DRILL     = 330000002
const PROP_CREATURE_ARMOR     = 340000001

const PROP_EQUIPMENT_PART_ENGINE = 1
const PROP_EQUIPMENT_PART_SHOE   = 2
const PROP_EQUIPMENT_PART_WEAPON = 3
const PROP_EQUIPMENT_PART_ARMOR  = 4

func get_props_pool() -> (props_pool_len: felt, props_pool: felt*):

    let (pool_address) = get_label_location(props_pool)

    return (19, cast(pool_address, felt*))

    props_pool:
    dw PROP_CREATURE_SHIELD
    dw PROP_CREATURE_ATTACK_UP_30P
    dw PROP_CREATURE_DAMAGE_DOWN_30P
    dw PROP_CREATURE_HEALTH_KIT
    dw PROP_CREATURE_MAX_HEALTH_UP_10
    dw PROP_CREATURE_STAGE2_KEY1
    dw PROP_CREATURE_STAGE2_KEY2
    dw PROP_CREATURE_STAGE2_KEY3
    dw PROP_CREATURE_STAGE2_KEY4
    dw PROP_CREATURE_STAGE2_KEY5
    dw PROP_CREATURE_STAGE2_KEY6
    dw PROP_CREATURE_STAGE2_KEY7
    dw PROP_CREATURE_STAGE2_KEY8
    dw PROP_CREATURE_STAGE2_KEY9
    dw PROP_CREATURE_ENGINE
    dw PROP_CREATURE_SHOE
    dw PROP_CREATURE_LASER_GUN
    dw PROP_CREATURE_DRILL
    dw PROP_CREATURE_ARMOR
end

func get_equipments() -> (equipments_len: felt, equipments: felt*):
    let (equipments_address) = get_label_location(equipments)

    return (5, cast(equipments_address, felt*))

    equipments:
    dw PROP_CREATURE_ENGINE
    dw PROP_CREATURE_SHOE
    dw PROP_CREATURE_LASER_GUN
    dw PROP_CREATURE_DRILL
    dw PROP_CREATURE_ARMOR
end

func get_relic_gate_key_ids() -> (key_ids_len: felt, key_ids: felt*):
    let (ids_address) = get_label_location(gate_ids)

    return (9, cast(ids_address, felt*))

    gate_ids:
    dw PROP_CREATURE_STAGE2_KEY1
    dw PROP_CREATURE_STAGE2_KEY2
    dw PROP_CREATURE_STAGE2_KEY3
    dw PROP_CREATURE_STAGE2_KEY4
    dw PROP_CREATURE_STAGE2_KEY5
    dw PROP_CREATURE_STAGE2_KEY6
    dw PROP_CREATURE_STAGE2_KEY7
    dw PROP_CREATURE_STAGE2_KEY8
    dw PROP_CREATURE_STAGE2_KEY9
end