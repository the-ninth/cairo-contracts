%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_not_zero, assert_le_felt, assert_lt_felt

from starkware.starknet.common.syscalls import get_block_number, get_block_timestamp, get_tx_info

from contracts.pvp.first_relic.structs import Koma, Combat, Coordinate, COMBAT_STATUS_REGISTERING, KOMA_STATUS_STATIC
from contracts.pvp.first_relic.FRCombatLibrary import (
    FirstRelicCombat_get_combat,
    _init_chests,
    _init_ores
)
from contracts.pvp.first_relic.constants import (
    CHEST_PER_PLAYER,
    ORE_PER_PLAYER,
    MAP_WIDTH,
    MAP_HEIGHT
)
from contracts.util.random import get_random_number_and_seed

@storage_var
func players_count(combat_id: felt) -> (count: felt):
end

@storage_var
func player_by_index(combat_id: felt, index: felt) -> (account: felt):
end

@storage_var
func komas(combat_id: felt, account: felt) -> (koma: Koma):
end



func FirstRelicCombat_get_players_count{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (count: felt):
    let (count) = players_count.read(combat_id)
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

    let (koma) = komas.read(combat_id, account)
    with_attr error_message("player not exist"):
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

func FirstRelicCombat_init_player{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt):
    let (combat) = FirstRelicCombat_get_combat(combat_id)
    with_attr error_message("FirstRelicCombat: combat not registering"):
        assert combat.status = COMBAT_STATUS_REGISTERING
    end

    let (koma) = komas.read(combat_id, account)
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
        coordinate=coordinate, status=KOMA_STATUS_STATIC, health=100, max_health=100, agility=7, move_speed=2, 
        props_weight=0, props_max_weight=1000, workers_count=3, working_workers_count=0,
        drones_count=3, action_radius=5, ore_amount=0, element=0
    )


    let (count) = players_count.read(combat_id)
    players_count.write(combat_id, count + 1)
    player_by_index.write(combat_id, count, account)
    komas.write(combat_id, account, koma)

    # generate chests and ores
    let (next_seed) = _init_chests(combat_id, CHEST_PER_PLAYER, next_seed)
    _init_ores(combat_id, ORE_PER_PLAYER, next_seed)
    return ()
end

func _fetch_outer_non_player_coordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, seed: felt) -> (coordinate: Coordinate, next_seed: felt):
    
    let (x, next_seed) = get_random_number_and_seed(seed, MAP_WIDTH)
    let (y, next_seed) = get_random_number_and_seed(next_seed, MAP_HEIGHT)
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

    let (count) = players_count.read(combat_id)
    if index == count:
        return (data_len, data)
    end

    let (account) = player_by_index.read(combat_id, index)
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
    let (koma) = komas.read(combat_id, account)
    with_attr error_message("player not exist"):
        assert_not_zero(koma.status)
    end

    assert data[data_len] = koma

    return _get_komas(combat_id, accounts_len - 1, accounts + 1, data_len + 1, data)
end