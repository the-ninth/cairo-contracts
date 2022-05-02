%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from contracts.pvp.first_relic.third_stage.structs import Combat_meta, Boss_meta
from contracts.pvp.first_relic.third_stage.storages import (
    FR3rd_reward_token,
    FR3rd_cur_boss_meta,
    FR3rd_boss_meta_len,
    FR3rd_boss_meta,
    FR3rd_cur_combat_meta,
    FR3rd_combat_meta,
    FR3rd_combat_meta_len,
)

# reward token
func FR3rd_get_reward_token_address{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (address : felt):
    let (address) = FR3rd_reward_token.read()
    return (address=address)
end

func FR3rd_set_reward_token_address{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(address : felt) -> ():
    FR3rd_reward_token.write(address)
    return ()
end

# boss meta
func FR3rd_add_boss_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    health : felt, defense : felt, agility : felt
) -> ():
    alloc_locals
    local boss_meta : Boss_meta
    assert boss_meta.health = health
    assert boss_meta.defense = defense
    assert boss_meta.agility = agility
    let (len) = FR3rd_boss_meta_len.read()
    FR3rd_boss_meta.write(len, boss_meta)
    FR3rd_boss_meta_len.write(len + 1)
    return ()
end

func FR3rd_get_boss_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    index : felt
) -> (meta : Boss_meta):
    let (meta) = FR3rd_boss_meta.read(index)
    return (meta)
end

func FR3rd_get_cur_boss_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (id : felt):
    let (id) = FR3rd_cur_boss_meta.read()
    return (id=id)
end

func FR3rd_set_cur_boss_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : felt
) -> ():
    FR3rd_cur_boss_meta.write(id)
    return ()
end

# combat meta
func FR3rd_add_combat_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    total_reward : felt, max_round_time : felt, max_round : felt, max_hero : felt
) -> ():
    alloc_locals
    let (len) = FR3rd_combat_meta_len.read()
    local combat_meta : Combat_meta
    assert combat_meta.total_reward = total_reward
    assert combat_meta.max_round_time = max_round_time
    assert combat_meta.max_round = max_round
    assert combat_meta.max_hero = max_hero
    FR3rd_combat_meta.write(len, combat_meta)
    FR3rd_combat_meta_len.write(len + 1)
    return ()
end

func FR3rd_get_combat_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    index : felt
) -> (meta : Combat_meta):
    let (meta) = FR3rd_combat_meta.read(index)
    return (meta)
end

func FR3rd_get_cur_combat_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (id : felt):
    let (id) = FR3rd_cur_combat_meta.read()
    return (id=id)
end

func FR3rd_set_cur_combat_meta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : felt
) -> ():
    FR3rd_cur_combat_meta.write(id)
    return ()
end
