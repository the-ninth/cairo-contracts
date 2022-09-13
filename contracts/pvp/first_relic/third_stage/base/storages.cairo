%lang starknet

from contracts.pvp.first_relic.third_stage.base.structs import (
    Hero,
    Combat,
    Combat_meta,
    Boss_meta,
    Action,
)

@storage_var
func FR3rd_reward_token() -> (address: felt) {
}

@storage_var
func FR3rd_combat_1st_address() -> (address: felt) {
}

@storage_var
func FR3rd_combat(combat_id: felt) -> (Combat: Combat) {
}

@storage_var
func FR3rd_combat_hero(combat_id: felt, hero_index: felt) -> (hero: Hero) {
}

@storage_var
func FR3rd_action(combat_id: felt, round_id: felt, hero_index: felt) -> (action: Action) {
}

@storage_var
func FR3rd_cur_boss_meta() -> (id: felt) {
}

@storage_var
func FR3rd_boss_meta_len() -> (count: felt) {
}

@storage_var
func FR3rd_boss_meta(index: felt) -> (boss_meta: Boss_meta) {
}

@storage_var
func FR3rd_cur_combat_meta() -> (id: felt) {
}

@storage_var
func FR3rd_combat_meta(meta_id: felt) -> (combat_meta: Combat_meta) {
}

@storage_var
func FR3rd_combat_meta_len() -> (count: felt) {
}

@storage_var
func FR3rd_combat_prop_used(combat_id: felt, prop_id: felt) -> (used: felt) {
}

@storage_var
func FR3rd_combat_prop_len(combat_id: felt, accound: felt, type: felt) -> (len: felt) {
}
