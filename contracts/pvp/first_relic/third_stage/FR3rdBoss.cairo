%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership,
)

from openzeppelin.upgrades.library import Proxy_initializer
from contracts.pvp.first_relic.third_stage.structs import (
    Hero,
    Combat,
    Combat_meta,
    Boss_meta,
    Action,
)
from contracts.pvp.first_relic.third_stage.FR3rdBossLibrary import (
    FR3rd_get_combat_info,
    FR3rd_join,
    FR3rd_submit_action,
)

from contracts.pvp.first_relic.third_stage.FR3rdManagerLibrary import (
    FR3rd_get_reward_token_address,
    FR3rd_set_reward_token_address,
    FR3rd_add_boss_meta,
    FR3rd_get_boss_meta,
    FR3rd_get_cur_boss_meta,
    FR3rd_set_cur_boss_meta,
    FR3rd_add_combat_meta,
    FR3rd_get_combat_meta,
    FR3rd_get_cur_combat_meta,
    FR3rd_set_cur_combat_meta,
)

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    return ()
end

# init
@external
func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt):
    Ownable_initializer(owner)
    Proxy_initializer(owner)
    return ()
end

#
# Getters
#

# manager
@view
func getRewardTokenAddress{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    address : felt
):
    let (address : felt) = FR3rd_get_reward_token_address()
    return (address=address)
end

@view
func getBossMeta{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(id : felt) -> (
    boss_meta : Boss_meta
):
    let (boss_meta : Boss_meta) = FR3rd_get_boss_meta(id)
    return (boss_meta=boss_meta)
end

@view
func getCurBossMetaId{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    id : felt
):
    let (id : felt) = FR3rd_get_cur_boss_meta()
    return (id=id)
end

@view
func getCombatMeta{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    id : felt
) -> (combat_meta : Combat_meta):
    let (combat_meta : Combat_meta) = FR3rd_get_combat_meta(id)
    return (combat_meta=combat_meta)
end

@view
func getCurCombatMetaId{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    id : felt
):
    let (id : felt) = FR3rd_get_cur_combat_meta()
    return (id=id)
end

@view
func getCombatInfoById{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    bf_index : felt
) -> (
    heros_len : felt,
    heros : Hero*,
    actions_len : felt,
    actions : Action*,
    combat : Combat,
    boss_meta : Boss_meta,
    combat_meta : Combat_meta,
):
    let (heros_len : felt, heros : Hero*, actions_len : felt, actions : Action*, combat : Combat,
        boss_meta : Boss_meta, combat_meta : Combat_meta) = FR3rd_get_combat_info(bf_index)
    return (
        heros_len=heros_len,
        heros=heros,
        actions_len=actions_len,
        actions=actions,
        combat=combat,
        boss_meta=boss_meta,
        combat_meta=combat_meta,
    )
end

#
# Externals
#

# manager

@external
func setRewardTokenAddress{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    address : felt
) -> ():
    Ownable_only_owner()
    FR3rd_set_reward_token_address(address)
    return ()
end

@external
func addBossMeta{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    health : felt, defense : felt, agility : felt
) -> ():
    Ownable_only_owner()
    FR3rd_add_boss_meta(health, defense, agility)
    return ()
end

@external
func addCombatMeta{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    total_reward : felt, max_round_time : felt, max_round : felt, max_hero : felt
) -> ():
    Ownable_only_owner()
    FR3rd_add_combat_meta(total_reward, max_round_time, max_round, max_hero)
    return ()
end

@external
func transferOwnership{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    new_owner : felt
) -> (new_owner : felt):
    Ownable_transfer_ownership(new_owner)
    return (new_owner=new_owner)
end

@external
func join{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    combat_id : felt, address : felt
):
    FR3rd_join(combat_id, address)
    return ()
end

@external
func action{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    bf_index : felt, round_id : felt, hero_index : felt, type : felt, target : felt
):
    FR3rd_submit_action(bf_index, round_id, hero_index, type, target)
    return ()
end
