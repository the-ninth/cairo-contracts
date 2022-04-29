%lang starknet

from contracts.pvp.first_relic.structs import Chest, Combat, Coordinate, Koma, KomaMiningOre, Movment, Ore, Prop

# combat storages

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

# option based on 1
@storage_var
func chest_options(combat_id: felt, coordinate: Coordinate, option: felt) -> (prop_creature_id: felt):
end

# player and koma storages

@storage_var
func players_count(combat_id: felt) -> (count: felt):
end

@storage_var
func player_by_index(combat_id: felt, index: felt) -> (account: felt):
end

@storage_var
func komas(combat_id: felt, account: felt) -> (koma: Koma):
end

@storage_var
func komas_movments(combat_id: felt, account: felt) -> (movment: Movment):
end

# ore storages

@storage_var
func ores(combat_id: felt, coordinate: Coordinate) -> (ore: Ore):
end

@storage_var
func ore_coordinates_len(combat_id: felt) -> (len: felt):
end

@storage_var
func ore_coordinate_by_index(combat_id:felt, index: felt) -> (coordinate: Coordinate):
end

@storage_var
func koma_mining_ore_coordinates_len(combat_id: felt, account: felt) -> (len: felt):
end

@storage_var
func koma_mining_ore_coordinates_by_index(combat_id: felt, account: felt, index: felt) -> (coordinate: Coordinate):
end

@storage_var
func koma_mining_ores(combat_id: felt, account: felt, coordinate: Coordinate) -> (minging_ore: KomaMiningOre):
end

# prop storages

@storage_var
func props_counter(combat_id: felt) -> (count: felt):
end

@storage_var
func props(combat_id: felt, prop_id: felt) -> (prop: Prop):
end

@storage_var
func props_owner(combat_id: felt, prop_id: felt) -> (owner: felt):
end

@storage_var
func koma_props_len(combat_id: felt, account: felt) -> (len: felt):
end

@storage_var
func koma_props_id_by_index(combat_id: felt, account: felt, index: felt) -> (prop_id: felt):
end

@storage_var
func koma_equipments(combat_id: felt, account: felt, part: felt) -> (prop_id: felt):
end