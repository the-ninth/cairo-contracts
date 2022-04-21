%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc

from starkware.starknet.common.syscalls import get_caller_address, get_block_number

from contracts.pvp.first_relic.structs import Combat, Chest, Ore, Coordinate
from contracts.util.random import get_random_number_and_seed



const MAX_PLAYERS = 10
const MAP_WIDTH = 300
const MAP_HEIGHT = 200
const MAP_INNER_AREA_WIDTH = 150
const MAP_INNER_AREA_HEIGHT = 100
const MAP_MAX_CHESTS = 50

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

func FirstRelicCombat_get_chest_count{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (len: felt):
    let (count) = chest_coordinates_len.read(combat_id)
    return (count)
end

func FirstRelicCombat_get_chests{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, offset: felt, length: felt) -> (data_len: felt, data: Chest*):
    let (data: Chest*) = alloc()
    return (0, data)
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
    let combat = Combat(max_players=MAX_PLAYERS, start_time=0, end_time=0, expire_time=0, status=0)
    combats.write(combat_id, combat)
    return (combat_id)
end

func FirstRelicCombat_init_combat_by_random{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, random: felt):
    let (combat) = combats.read(combat_id)
    with_attr error_message("FirstRelicCombat: combat initialized"):
        assert combat.status = 0
    end
    # todo: setup chests and ore randomly
    let (block_number) = get_block_number()
    let (caller) = get_caller_address()
    _init_chests(combat_id, MAP_MAX_CHESTS, block_number + caller)
    return ()
end

func _init_chests{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, chests_count: felt, seed: felt):
    if chests_count == 0:
        return ()
    end
    let (coordinate, next_seed) = _fetch_outer_empty_coordinate(combat_id, seed)
    let chest = Chest(coordinate=coordinate, chest_type=1)
    let (chest_len) = chest_coordinates_len.read(combat_id)
    chests.write(combat_id, coordinate, chest)
    chest_coordinate_by_index.write(combat_id, chest_len, coordinate)
    chest_coordinates_len.write(combat_id, chest_len + 1)

    _init_chests(combat_id, chests_count - 1, next_seed)

    return ()
end

# fetch a empty coordinate randomly
func _fetch_outer_empty_coordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, seed: felt) -> (coordinate: Coordinate, next_seed: felt):
    # todo: 
    let (x, next_seed) = get_random_number_and_seed(seed, MAP_WIDTH)
    let (y, next_seed) = get_random_number_and_seed(next_seed, MAP_WIDTH)
    return (Coordinate(x,y), next_seed)
end