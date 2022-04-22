%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_le_felt, assert_lt_felt

from starkware.starknet.common.syscalls import get_caller_address, get_block_number

from contracts.pvp.first_relic.structs import Combat, COMBAT_STATUS_REGISTERING, Chest, Ore, Coordinate
from contracts.util.random import get_random_number_and_seed


const MAP_WIDTH = 300
const MAP_HEIGHT = 200
const MAP_INNER_AREA_WIDTH = 150
const MAP_INNER_AREA_HEIGHT = 100
const CHEST_PER_PLAYER = 3
const ORE_PER_PLAYER = 3


@storage_var
func combat_counter() -> (count: felt):
end

@storage_var
func combats(combat_id: felt) -> (combat: Combat):
end

# chest storages

@storage_var
func chests(combat_id: felt, coordinate: Coordinate) -> (chest: Chest):
end

@storage_var
func chest_coordinates_len(combat_id: felt) -> (len: felt):
end

@storage_var
func chest_coordinate_by_index(combat_id: felt, index: felt) -> (coordinate: Coordinate):
end

# ore storages

@storage_var
func ores(coordinate: Coordinate) -> (ore: Ore):
end

@storage_var
func ore_coordinates_len() -> (len: felt):
end

@storage_var
func ore_coordinate_by_index(index: felt) -> (coordinate: Coordinate):
end

func FirstRelicCombat_get_combat_count{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (count: felt):
    let (count) = combat_counter.read()
    return (count)
end

func FirstRelicCombat_get_combat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (combat: Combat):
    let (combat) = combats.read(combat_id)
    return (combat)
end

func FirstRelicCombat_get_chest_count{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (count: felt):
    let (count) = chest_coordinates_len.read(combat_id)
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
    let (chest) = chests.read(combat_id, coordinate)
    return (chest)
end

func FirstRelicCombat_new_combat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (combat_id: felt):
    let (count) = combat_counter.read()
    let combat_id = count + 1
    let combat = Combat(start_time=0, end_time=0, expire_time=0, status=COMBAT_STATUS_REGISTERING)
    combats.write(combat_id, combat)
    return (combat_id)
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
    let chest = Chest(coordinate=coordinate, chest_type=1)
    let (chest_len) = chest_coordinates_len.read(combat_id)
    chests.write(combat_id, coordinate, chest)
    chest_coordinate_by_index.write(combat_id, chest_len, coordinate)
    chest_coordinates_len.write(combat_id, chest_len + 1)

    let (next_seed) = _init_chests(combat_id, chests_count - 1, next_seed)

    return (next_seed)
end

func _init_ores{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, ores_count: felt, seed: felt) -> (next_seed: felt):
    if ores_count == 0:
        return ()
    end
    let (coordinate, next_seed) = _fetch_outer_empty_coordinate(combat_id, seed)
    let ore = Ore(total_supply=1000, mined_supply=0, mining_workers_count=0)
    let (ore_len) = ore_coordinates_len.read(combat_id)
    ores.write(combat_id, coordinate, ore)
    ore_coordinate_by_index.write(combat_id, ore_len, coordinate)
    ore_coordinates_len.write(combat_id, ore_len + 1)

    _init_ores(combat_id, ores_count - 1, next_seed)

    return ()
end

# fetch a empty coordinate randomly
func _fetch_outer_empty_coordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, seed: felt) -> (coordinate: Coordinate, next_seed: felt):
    
    let (x, next_seed) = get_random_number_and_seed(seed, MAP_WIDTH)
    let (y, next_seed) = get_random_number_and_seed(next_seed, MAP_WIDTH)

    return (Coordinate(x,y), next_seed)
end

func _get_chests{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, index: felt, length: felt, data_len: felt, data: Chest*) -> (data_len: felt, data: Chest*):
    if length == 0:
        return (data_len, data)
    end

    let (chests_count) = chest_coordinates_len.read(combat_id)
    if index == chests_count - 1:
        return (data_len, data)
    end

    let (coordinate) = chest_coordinate_by_index.read(combat_id, index)
    let (chest) = chests.read(combat_id, coordinate)
    assert data[data_len] = chest

    return _get_chests(combat_id, index+1, length-1, data_len+1, data)
end