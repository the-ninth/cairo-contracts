%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.pvp.first_relic.structs import (
    Chest,
    Combat,
    Coordinate,
    Koma,
    Movment,
    Ore,
    Prop,
    PropEffect,
    RelicGate,
)

// combat storages

@storage_var
func FirstRelicCombat_access_contract() -> (access_contract: felt) {
}

@storage_var
func FirstRelicCombat_register_fee(combat_id: felt) -> (total: Uint256) {
}

@storage_var
func FirstRelicCombat_combat_account_koma_tokens(combat_id: felt, account: felt) -> (
    koma_token_id: Uint256
) {
}

@storage_var
func FirstRelicCombat_combat_account_koma_creatures(combat_id: felt, account: felt) -> (
    koma_creature_id: felt
) {
}

@storage_var
func FirstRelicCombat_combat_counter() -> (count: felt) {
}

@storage_var
func FirstRelicCombat_combats(combat_id: felt) -> (combat: Combat) {
}

// chest storages

@storage_var
func FirstRelicCombat_chests(combat_id: felt, coordinate: Coordinate) -> (chest: Chest) {
}

@storage_var
func FirstRelicCombat_chest_coordinates_len(combat_id: felt) -> (len: felt) {
}

@storage_var
func FirstRelicCombat_chest_coordinate_by_index(combat_id: felt, index: felt) -> (
    coordinate: Coordinate
) {
}

// option based on 1
@storage_var
func FirstRelicCombat_chest_options(combat_id: felt, coordinate: Coordinate, option: felt) -> (
    prop_creature_id: felt
) {
}

// player and koma storages

@storage_var
func FirstRelicCombat_players_count(combat_id: felt) -> (count: felt) {
}

@storage_var
func FirstRelicCombat_player_by_index(combat_id: felt, index: felt) -> (account: felt) {
}

@storage_var
func FirstRelicCombat_komas(combat_id: felt, account: felt) -> (koma: Koma) {
}

@storage_var
func FirstRelicCombat_komas_movments(combat_id: felt, account: felt) -> (movment: Movment) {
}

// ore storages

@storage_var
func FirstRelicCombat_ores(combat_id: felt, coordinate: Coordinate) -> (ore: Ore) {
}

@storage_var
func FirstRelicCombat_ore_coordinates_len(combat_id: felt) -> (len: felt) {
}

@storage_var
func FirstRelicCombat_ore_coordinate_by_index(combat_id: felt, index: felt) -> (
    coordinate: Coordinate
) {
}

@storage_var
func FirstRelicCombat_koma_ore_coordinates_len(combat_id: felt, account: felt) -> (len: felt) {
}

@storage_var
func FirstRelicCombat_koma_ore_coordinates_by_index(
    combat_id: felt, account: felt, index: felt
) -> (coordinnate: Coordinate) {
}

// prop storages

@storage_var
func FirstRelicCombat_props_counter(combat_id: felt) -> (count: felt) {
}

@storage_var
func FirstRelicCombat_props(combat_id: felt, prop_id: felt) -> (prop: Prop) {
}

@storage_var
func FirstRelicCombat_props_owner(combat_id: felt, prop_id: felt) -> (owner: felt) {
}

@storage_var
func FirstRelicCombat_koma_props_len(combat_id: felt, account: felt) -> (len: felt) {
}

@storage_var
func FirstRelicCombat_koma_props_id_by_index(combat_id: felt, account: felt, index: felt) -> (
    prop_id: felt
) {
}

@storage_var
func FirstRelicCombat_koma_props_effect(combat_id: felt, account: felt, prop_creature_id: felt) -> (
    prop_effect: PropEffect
) {
}

@storage_var
func FirstRelicCombat_koma_props_effect_creature_id_len(combat_id: felt, account: felt) -> (
    len: felt
) {
}

@storage_var
func FirstRelicCombat_koma_props_effect_creature_id_by_index(
    combat_id: felt, account: felt, index: felt
) -> (prop_creature_id: felt) {
}

@storage_var
func FirstRelicCombat_koma_equipments(combat_id: felt, account: felt, equip_part: felt) -> (
    prop_id: felt
) {
}

// gates storages

// number based on 1
@storage_var
func FirstRelicCombat_relic_gates(combat_id: felt, number: felt) -> (relic_gate: RelicGate) {
}

@storage_var
func FirstRelicCombat_relic_gate_number_by_coordinate(combat_id: felt, coordinate: Coordinate) -> (
    number: felt
) {
}

@storage_var
func FirstRelicCombat_third_stage_players_count(combat_id: felt) -> (count: felt) {
}
