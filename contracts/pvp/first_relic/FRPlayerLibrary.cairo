%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le_felt,
    assert_lt_felt,
    abs_value,
    sign,
    sqrt,
    unsigned_div_rem
)    

from starkware.starknet.common.syscalls import get_block_number, get_block_timestamp, get_tx_info

from contracts.pvp.first_relic.structs import (
    Koma,
    Combat,
    Coordinate,
    Movment,
    COMBAT_STATUS_REGISTERING,
    KOMA_STATUS_STATIC,
    KOMA_STATUS_DEAD,
    KOMA_STATUS_MINING,
    KOMA_STATUS_MOVING
)
from contracts.pvp.first_relic.constants import (
    CHEST_PER_PLAYER,
    ORE_PER_PLAYER,
    MAP_WIDTH,
    MAP_HEIGHT,
    KOMA_MOVING_SPEED,
    KOMA_ATK,
    KOMA_DEFENSE,
    WORKER_MINING_SPEED,
    get_outer_coordinate_ranges
)
from contracts.pvp.first_relic.storages import (
    FirstRelicCombat_combats,
    FirstRelicCombat_players_count,
    FirstRelicCombat_player_by_index,
    FirstRelicCombat_komas,
    FirstRelicCombat_komas_movments
)
from contracts.util.random import get_random_number_and_seed

func FirstRelicCombat_get_players_count{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (count: felt):
    let (count) = FirstRelicCombat_players_count.read(combat_id)
    return (count)
end

func FirstRelicCombat_get_players{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, index: felt, length: felt) -> (data_len: felt, data: felt*):
    alloc_locals

    assert_le_felt(0, index)
    assert_lt_felt(0, length)

    let (local data: felt*) = alloc()
    let (data_len, data) = _get_players(combat_id, index, length, 0, data)
    return (data_len, data)
end

func FirstRelicCombat_get_koma{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt) -> (koma: Koma):
    alloc_locals

    let (koma) = FirstRelicCombat_komas.read(combat_id, account)
    with_attr error_message("FirstRelicCombat: player not exist"):
        assert_not_zero(koma.status)
    end

    return (koma)
end

func FirstRelicCombat_get_komas{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, accounts_len: felt, accounts: felt*) -> (komas_len: felt, komas: Koma*):
    alloc_locals

    assert_lt_felt(0, accounts_len)
    let (local data: Koma*) = alloc()
    let (data_len, data) = _get_komas(combat_id, accounts_len, accounts, 0, data)
    return (data_len, data)
end

func FirstRelicCombat_get_komas_movments{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, accounts_len: felt, accounts: felt*) -> (movments_len: felt, movments: Movment*):
    alloc_locals

    assert_lt_felt(0, accounts_len)
    let (local data: Movment*) = alloc()
    let (data_len, data) = _get_komas_movments(combat_id, accounts_len, accounts, 0, data)
    return (data_len, data)
end

func FirstRelicCombat_init_player{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt) -> (next_seed: felt):
    let (combat) = FirstRelicCombat_combats.read(combat_id)
    with_attr error_message("FirstRelicCombat: combat not registering"):
        assert combat.status = COMBAT_STATUS_REGISTERING
    end

    let (koma) = FirstRelicCombat_komas.read(combat_id, account)
    with_attr error_message("FirstRelicCombat: account registered"):
        assert koma.status = 0
    end

    let (tx_info) = get_tx_info()
    let (block_number) = get_block_number()
    let (block_timestamp) = get_block_timestamp()
    let hash_ptr = pedersen_ptr
    with hash_ptr:
        let (seed) = hash2(tx_info.account_contract_address, block_timestamp)
    end
    let pedersen_ptr = hash_ptr
    let (coordinate, next_seed) = _fetch_outer_non_player_coordinate(combat_id, seed)
    let koma = Koma(
        account=account, coordinate=coordinate, status=KOMA_STATUS_STATIC, health=100, max_health=100, agility=7,
        move_speed=KOMA_MOVING_SPEED, props_weight=0, props_max_weight=1000, workers_count=3, mining_workers_count=0,
        drones_count=3, action_radius=5, element=0, ore_amount=0, atk=KOMA_ATK, defense=KOMA_DEFENSE, worker_mining_speed=WORKER_MINING_SPEED
    )


    let (count) = FirstRelicCombat_players_count.read(combat_id)
    FirstRelicCombat_players_count.write(combat_id, count + 1)
    FirstRelicCombat_player_by_index.write(combat_id, count, account)
    FirstRelicCombat_komas.write(combat_id, account, koma)

    return (next_seed)
end

func FirstRelicCombat_move{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, to: Coordinate):
    alloc_locals
    let (koma) = FirstRelicCombat_komas.read(combat_id, account)
    let (actual_status, actual_at) = FirstRelicCombat_get_koma_actual_coordinate(combat_id, account, koma)
    let (block_timestamp) = get_block_timestamp()
    with_attr error_message("FirstRelicCombat: coordinate invalid"):
        assert_not_zero(actual_at.x - to.x + actual_at.y - to.y)
        assert_le_felt(0, to.x)
        assert_le_felt(0, to.y)
        assert_le_felt(to.x, MAP_WIDTH)
        assert_le_felt(to.y, MAP_HEIGHT)
        # todo: first stage can not enter the second stage area
    end
    
    let new_koma = Koma(
        account, actual_at, KOMA_STATUS_MOVING, koma.health, koma.max_health, koma.agility, koma.move_speed,
        koma.props_weight, koma.props_max_weight, koma.workers_count, koma.mining_workers_count, koma.drones_count,
        koma.action_radius, koma.element, koma.ore_amount, koma.atk, koma.defense, koma.worker_mining_speed
    )
    FirstRelicCombat_komas.write(combat_id, account, new_koma)
    let (distance) = _get_distance(actual_at, to)
    let (time_need, _) = unsigned_div_rem(distance, koma.move_speed)
    let movement = Movment(new_koma.coordinate, to, block_timestamp, block_timestamp + time_need + 1)
    FirstRelicCombat_komas_movments.write(combat_id, account, movement)

    return ()
end

func _fetch_outer_non_player_coordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, seed: felt) -> (coordinate: Coordinate, next_seed: felt):

    let (ranges_len, ranges) = get_outer_coordinate_ranges()
    let (index, next_seed) = get_random_number_and_seed(seed, ranges_len)
    let range = ranges[index]
    
    let x_offset = range.x1 - range.x0
    let (x_random, next_seed) = get_random_number_and_seed(next_seed, x_offset)
    let x = x_random + range.x0

    let y_offset = range.y1 - range.y0
    let (y_random, next_seed) = get_random_number_and_seed(next_seed, y_offset)
    let y = y_random + range.y0
    
    let coordinate = Coordinate(x=x, y=y)

    return (coordinate, next_seed)
end

# recursively get player struct array 
func _get_players{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, index: felt, length: felt, data_len: felt, data: felt*) -> (data_len: felt, data: felt*):
    if length == 0:
        return (data_len, data)
    end

    let (count) = FirstRelicCombat_players_count.read(combat_id)
    if index == count:
        return (data_len, data)
    end

    let (account) = FirstRelicCombat_player_by_index.read(combat_id, index)
    assert data[data_len] = account

    return _get_players(combat_id, index+1, length-1, data_len+1, data)
end

# recursively get koma struct array 
func _get_komas{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, accounts_len: felt, accounts: felt*, data_len: felt, data: Koma*) -> (data_len: felt, data: Koma*):
    if accounts_len == 0:
        return (data_len, data)
    end
    
    let account = accounts[0]
    let (koma) = FirstRelicCombat_komas.read(combat_id, account)
    with_attr error_message("player not exist"):
        assert_not_zero(koma.status)
    end

    assert data[data_len] = koma

    return _get_komas(combat_id, accounts_len - 1, accounts + 1, data_len + 1, data)
end

# recursively get komas movment struct array 
func _get_komas_movments{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, accounts_len: felt, accounts: felt*, data_len: felt, data: Movment*) -> (data_len: felt, data: Movment*):
    if accounts_len == 0:
        return (data_len, data)
    end
    
    let account = accounts[0]
    let (movment) = FirstRelicCombat_komas_movments.read(combat_id, account)

    assert data[data_len] = movment
    return _get_komas_movments(combat_id, accounts_len - 1, accounts + 1, data_len + 1, data)
end

func FirstRelicCombat_get_koma_actual_coordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, koma: Koma) -> (status: felt, coordinate: Coordinate):
    alloc_locals
    
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    if koma.status == KOMA_STATUS_MOVING:
        let (movment) = FirstRelicCombat_komas_movments.read(combat_id, account)
        let (block_timestamp) = get_block_timestamp()
        let (reached) = sign(block_timestamp - movment.reach_time)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        if reached == 1:
            # arrived
            return (KOMA_STATUS_STATIC, movment.to)
        end
        if reached == 0:
            # arrived
            return (KOMA_STATUS_STATIC, movment.to)
        end
        # still moving
        let time_passed = movment.reach_time - block_timestamp
        let max_time_needed = movment.reach_time - movment.start_time
        let (q, _) = unsigned_div_rem(time_passed*1000, max_time_needed)
        let (x_distance_max) = abs_value(koma.coordinate.x - movment.to.x)
        let (y_distance_max) = abs_value(koma.coordinate.y - movment.to.y)
        let (x_distance, _) = unsigned_div_rem(x_distance_max * q, 1000) # x moved
        let (y_distance, _) = unsigned_div_rem(y_distance_max * q, 1000) # y moved
        let (x_sign) = sign(koma.coordinate.x - movment.to.x)
        let (y_sign) = sign(koma.coordinate.y - movment.to.y)
        let new_x = koma.coordinate.x + x_distance * x_sign
        let new_y = koma.coordinate.y + y_distance * y_sign
        return (KOMA_STATUS_MOVING, Coordinate(new_x, new_y))
    end
    
    return (koma.status, koma.coordinate)
end

func _get_distance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(from_: Coordinate, to: Coordinate) -> (distance: felt):
    let (x_distance) = abs_value(from_.x - to.x)
    let (y_distance) = abs_value(from_.y - to.y)
    let (distance) = sqrt(x_distance * x_distance + y_distance * y_distance)
    return (distance)
end

#
# Modifiers
#