%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.pvp.first_relic.structs import Combat, Chest, Ore, Coordinate

const MAX_PLAYERS = 10

@storage_var
func combat_counter() -> (count: felt):
end

@storage_var
func combats(combat_id: felt) -> (combat: Combat):
end

# chest storages

@storage_var
func chests(coordinate: Coordinate) -> (chest: Chest):
end

@storage_var
func chest_coordinates_len() -> (len: felt):
end

@storage_var
func chest_coordinate_by_index(index: felt) -> (coordinate: Coordinate):
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

func _new_combat{
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

func _init_combat_by_random{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, random: felt):
    let (combat) = combats.read(combat_id)
    with_attr error_message("FirstRelicCombat: combat initialized"):
        assert combat.status = 0
    end
    # todo: setup chests and ore randomly
    return ()
end

# fetch a empty coordinate randomly
func _fetch_outer_empty_coordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(seed: felt) -> (next_seed: felt):
    # todo: 
    return (0)
end