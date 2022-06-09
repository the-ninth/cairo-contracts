%lang starknet

from contracts.pvp.first_relic.structs import (
    Chest,
    Combat,
    Coordinate,
    Koma,
    Movment,
    Ore,
    Prop,
    PropEffect,
    RelicGate
)

# combat storages

@storage_var
func FirstRelicCombat_combat_counter() -> (count: felt):
end

@storage_var
func FirstRelicCombat_combats(combat_id: felt) -> (combat: Combat):
end

# chest storages

@storage_var
func FirstRelicCombat_chests(combat_id: felt, coordinate: Coordinate) -> (chest: Chest):
end

@storage_var
func FirstRelicCombat_chest_coordinates_len(combat_id: felt) -> (len: felt):
end

@storage_var
func FirstRelicCombat_chest_coordinate_by_index(combat_id: felt, index: felt) -> (coordinate: Coordinate):
end

# option based on 1
@storage_var
func FirstRelicCombat_chest_options(combat_id: felt, coordinate: Coordinate, option: felt) -> (prop_creature_id: felt):
end

# player and koma storages

@storage_var
func FirstRelicCombat_players_count(combat_id: felt) -> (count: felt):
end

@storage_var
func FirstRelicCombat_player_by_index(combat_id: felt, index: felt) -> (account: felt):
end

@storage_var
func FirstRelicCombat_komas(combat_id: felt, account: felt) -> (koma: Koma):
end

@storage_var
func FirstRelicCombat_komas_movments(combat_id: felt, account: felt) -> (movment: Movment):
end

# ore storages

@storage_var
func FirstRelicCombat_ores(combat_id: felt, coordinate: Coordinate) -> (ore: Ore):
end

@storage_var
func FirstRelicCombat_ore_coordinates_len(combat_id: felt) -> (len: felt):
end

@storage_var
func FirstRelicCombat_ore_coordinate_by_index(combat_id:felt, index: felt) -> (coordinate: Coordinate):
end

@storage_var
func FirstRelicCombat_koma_ore_coordinates_len(combat_id: felt, account: felt) -> (len: felt):
end

@storage_var
func FirstRelicCombat_koma_ore_coordinates_by_index(combat_id: felt, account: felt, index: felt) -> (coordinnate: Coordinate):
end

# prop storages

@storage_var
func FirstRelicCombat_props_counter(combat_id: felt) -> (count: felt):
end

@storage_var
func FirstRelicCombat_props(combat_id: felt, prop_id: felt) -> (prop: Prop):
end

@storage_var
func FirstRelicCombat_props_owner(combat_id: felt, prop_id: felt) -> (owner: felt):
end

@storage_var
func FirstRelicCombat_koma_props_len(combat_id: felt, account: felt) -> (len: felt):
end

@storage_var
func FirstRelicCombat_koma_props_id_by_index(combat_id: felt, account: felt, index: felt) -> (prop_id: felt):
end

@storage_var
func FirstRelicCombat_koma_props_effect(combat_id: felt, account: felt, prop_creature_id: felt) -> (prop_effect: PropEffect):
end

@storage_var
func FirstRelicCombat_koma_props_effect_creature_id_len(combat_id: felt, account: felt) -> (len: felt):
end

@storage_var
func FirstRelicCombat_koma_props_effect_creature_id_by_index(combat_id: felt, account: felt, index: felt) -> (prop_creature_id: felt):
end

@storage_var
func FirstRelicCombat_koma_equipments(combat_id: felt, account: felt, equip_part: felt) -> (prop_id: felt):
end

# gates storages

# number based on 1
@storage_var
func FirstRelicCombat_relic_gates(combat_id: felt, number: felt) -> (relic_gate: RelicGate):
end

@storage_var
func FirstRelicCombat_relic_gate_number_by_coordinate(combat_id: felt, coordinate: Coordinate) -> (number: felt):
end

@storage_var
func FirstRelicCombat_third_stage_players_count(combat_id: felt) -> (count: felt):
end