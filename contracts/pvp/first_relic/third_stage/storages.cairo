%lang starknet

from contracts.pvp.first_relic.third_stage.structs import (
    Hero,
    Combat,
    Combat_meta,
    Boss_meta,
    Action,
)

@storage_var
func FR3rd_reward_token() -> (address : felt):
end

@storage_var
func FR3rd_combat(combat_id : felt) -> (Combat : Combat):
end

@storage_var
func FR3rd_combat_hero(combat_id : felt, hero_index : felt) -> (hero : Hero):
end

@storage_var
func FR3rd_action(combat_id : felt, round_id : felt, hero_index : felt) -> (action : Action):
end

@storage_var
func FR3rd_cur_boss_meta() -> (id : felt):
end

@storage_var
func FR3rd_boss_meta_len() -> (count : felt):
end

@storage_var
func FR3rd_boss_meta(index : felt) -> (boss_meta : Boss_meta):
end

@storage_var
func FR3rd_cur_combat_meta() -> (id : felt):
end

@storage_var
func FR3rd_combat_meta(meta_id : felt) -> (combat_meta : Combat_meta):
end

@storage_var
func FR3rd_combat_meta_len() -> (count : felt):
end
