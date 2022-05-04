%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import (
    is_in_range,
    is_le,
    is_le_felt,
    is_nn,
    is_nn_le,
    is_not_zero,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
    unsigned_div_rem,
    assert_lt,
    assert_nn_le,
    split_felt,
)
from starkware.cairo.common.hash import hash2
from contracts.util.random import get_random_number

from contracts.util.Uin256_felt_conv import _uint_to_felt, _felt_to_uint
from starkware.cairo.common.bool import TRUE, FALSE
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.pvp.first_relic.third_stage.base.structs import (
    Hero,
    Combat,
    Combat_meta,
    Boss_meta,
    Action,
)
from contracts.pvp.first_relic.third_stage.base.storages import (
    FR3rd_reward_token,
    FR3rd_combat_1st_address,
    FR3rd_combat,
    FR3rd_combat_hero,
    FR3rd_action,
    FR3rd_cur_boss_meta,
    FR3rd_boss_meta_len,
    FR3rd_boss_meta,
    FR3rd_cur_combat_meta,
    FR3rd_combat_meta,
    FR3rd_combat_meta_len,
    FR3rd_combat_prop_used,
    FR3rd_combat_prop_len,
)

from contracts.pvp.first_relic.third_stage.base.constants import (
    BOSS_INDEX,
    BOSS_ADDRESS,
    ACTION_TYPE_ATK,
    ACTION_TYPE_PROP,
    DEFAULT_NEXT_HERO_INDEX,
)

from contracts.pvp.first_relic.structs import (
    Chest,
    Coordinate,
    Koma,
    KomaMiningOre,
    Ore,
    ThirdStageAction,
    Movment,
    Prop,
)

from contracts.pvp.first_relic.third_stage.FR3rdPropLibrary import (
    FR3rd_use_prop,
    FR3rd_prop_atk,
    FR3rd_prop_damage,
    FR3rd_prop_health,
)
from contracts.pvp.first_relic.third_stage.FR3rdClearCombatLibrary import FR3rd_try_clear_combat

from contracts.pvp.first_relic.third_stage.base.FR3rdBaseLibrary import (
    FR3rd_base_check_hero_in_loop,
    FR3rd_base_get_koma,
    FR3rd_base_update_hero,
    FR3rd_base_update_combat,
    FR3rd_base_get_agility,
    FR3rd_base_get_defense,
    FR3rd_base_get_atk,
    FR3rd_base_random,
    FR3rd_base_update_action,
    FR3rd_base_sort_by_agility_loop,
    FR3rd_base_find_surviving_loop,
    FR3rd_base_is_round_end,
)

#
# getters
#
# get combat info by index
func _get_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (combat : Combat):
    alloc_locals
    let (combat) = FR3rd_combat.read(combat_id)
    # todo
    # with_attr error_message("_get_combat: combat error"):
    #     assert_not_zero(combat.timestamp)
    # end
    return (combat=combat)
end

# get combat heros info
func FR3rd_get_heros{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (heros_len : felt, heros : Hero*):
    alloc_locals
    let (combat) = FR3rd_combat.read(combat_id)
    let (local heros : Hero*) = alloc()
    FR3rd_get_heros_loop(
        combat_id=combat_id, cur_index=0, heros=heros, left=combat.cur_hero_count + 1
    )
    return (heros_len=combat.cur_hero_count + 1, heros=heros)
end

func FR3rd_get_heros_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, cur_index : felt, heros : Hero*, left
) -> ():
    alloc_locals
    if left == 0:
        return ()
    end
    let (local hero) = FR3rd_combat_hero.read(combat_id, cur_index)
    assert [heros] = hero
    FR3rd_get_heros_loop(combat_id, cur_index=cur_index + 1, heros=heros + Hero.SIZE, left=left - 1)
    return ()
end

func FR3rd_get_actions_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, round_id : felt, cur_index : felt, actions : Action*, left
) -> (len : felt):
    alloc_locals
    if left == 0:
        return (0)
    end
    if cur_index == DEFAULT_NEXT_HERO_INDEX:
        return (0)
    end
    let (local hero) = FR3rd_combat_hero.read(combat_id, cur_index)
    let (local action) = FR3rd_action.read(combat_id, round_id, cur_index)
    assert [actions] = action
    let (len) = FR3rd_get_actions_loop(
        combat_id=combat_id,
        round_id=round_id,
        cur_index=hero.agility_next_hero,
        actions=actions + Action.SIZE,
        left=left - 1,
    )
    return (len + 1)
end

# get combat all info by combat_id
func FR3rd_get_combat_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, hero_index : felt
) -> (
    heros_len : felt,
    heros : Hero*,
    actions_len : felt,
    actions : Action*,
    combat : Combat,
    boss_meta : Boss_meta,
    combat_meta : Combat_meta,
    need_end : felt,
    need_action : felt,
):
    alloc_locals
    let (combat) = _get_combat(combat_id)
    let (boss_meta) = FR3rd_boss_meta.read(combat.boss_id)
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    let (action) = FR3rd_action.read(combat_id, combat.round, hero_index)
    let (is_submit_action) = is_not_zero(action.type)
    let (is_round_end) = FR3rd_base_is_round_end(combat_id)
    let (local heros : Hero*) = alloc()
    FR3rd_get_heros_loop(
        combat_id=combat_id, cur_index=0, heros=heros, left=combat.init_hero_count + 1
    )
    let (local actions : Action*) = alloc()
    if combat.round == 0:
        return (
            heros_len=combat.init_hero_count + 1,
            heros=heros,
            actions_len=0,
            actions=actions,
            combat=combat,
            boss_meta=boss_meta,
            combat_meta=combat_meta,
            need_end=is_round_end,
            need_action=1 - is_submit_action,
        )
    else:
        let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
        let (actions_len) = FR3rd_get_actions_loop(
            combat_id=combat_id,
            round_id=combat.round - 1,
            cur_index=combat.agility_1st,
            actions=actions,
            left=combat.init_hero_count + 1,
        )
        return (
            heros_len=combat.init_hero_count + 1,
            heros=heros,
            actions_len=actions_len,
            actions=actions,
            combat=combat,
            boss_meta=boss_meta,
            combat_meta=combat_meta,
            need_end=is_round_end,
            need_action=1 - is_submit_action,
        )
    end
end

#
# # external
#

# hero join a new combat
func FR3rd_join{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, address : felt
) -> ():
    alloc_locals
    let (is_init) = _is_combat_init(combat_id)
    if is_init == FALSE:
        FR3rd_init_combat(combat_id)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    FR3rd_join_combat(combat_id, address)
    return ()
end

func FR3rd_join_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, address : felt
) -> ():
    alloc_locals
    let (combat) = FR3rd_combat.read(combat_id)
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    with_attr error_message("FR3rd_join: hero enough"):
        assert_lt(combat.init_hero_count, combat_meta.max_hero)
    end
    let (is_in) = FR3rd_base_check_hero_in_loop(
        sender=address, combat_id=combat_id, left=combat.init_hero_count
    )
    with_attr error_message("FR3rd_join: is in "):
        assert is_in = FALSE
    end
    let (koma) = FR3rd_base_get_koma(combat_id, address)

    # add hero
    local hero : Hero
    assert hero.address = address
    assert hero.health = koma.health
    assert hero.agility_next_hero = DEFAULT_NEXT_HERO_INDEX
    assert hero.damage_to_boss_next_hero = DEFAULT_NEXT_HERO_INDEX
    assert hero.bear_from_hero = 0
    assert hero.bear_from_boss = 0
    assert hero.damage_to_hero = 0
    assert hero.damage_to_boss = 0

    let new_hero_index = combat.init_hero_count + 1
    FR3rd_combat_hero.write(combat_id, new_hero_index, hero)
    #
    FR3rd_base_update_combat(
        combat_id=combat_id,
        round=combat.round,
        action_count=combat.action_count,
        agility_1st=combat.agility_1st,
        damage_to_boss_1st=combat.damage_to_boss_1st,
        cur_hero_count=combat.cur_hero_count + 1,
        init_hero_count=new_hero_index,
        last_round_time=combat.last_round_time,
        end_info=combat.end_info,
    )

    FR3rd_base_sort_by_agility_loop(
        combat_id=combat_id,
        agility=koma.agility,
        hero_index=new_hero_index,
        hero=hero,
        cur_hero_index=combat.agility_1st,
        pre_hero_index=0,
        left=new_hero_index,
    )
    return ()
end

# init combat and boss
func FR3rd_init_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> ():
    alloc_locals
    let (block_timestamp) = get_block_timestamp()
    let (meta_id) = FR3rd_cur_combat_meta.read()
    let (boss_id) = FR3rd_cur_boss_meta.read()
    let (combat_meta) = FR3rd_combat_meta.read(meta_id)

    local combat : Combat
    assert combat.combat_id = combat_id
    assert combat.meta_id = meta_id
    assert combat.boss_id = boss_id
    assert combat.round = 0
    assert combat.action_count = 0
    assert combat.init_hero_count = 0
    assert combat.cur_hero_count = 0
    assert combat.agility_1st = 0
    assert combat.damage_to_boss_1st = 1
    assert combat.start_time = block_timestamp
    assert combat.last_round_time = block_timestamp
    assert combat.end_info = 0
    FR3rd_combat.write(combat_id, combat)

    let (boss_meta) = FR3rd_boss_meta.read(boss_id)

    # add boss as hero
    local boss : Hero
    assert boss.address = 0
    assert boss.health = boss_meta.health
    assert boss.agility_next_hero = DEFAULT_NEXT_HERO_INDEX
    assert boss.damage_to_boss_next_hero = DEFAULT_NEXT_HERO_INDEX
    assert boss.bear_from_hero = 0
    assert boss.bear_from_boss = 0
    assert boss.damage_to_hero = 0
    assert boss.damage_to_boss = 0
    FR3rd_combat_hero.write(combat_id, BOSS_INDEX, boss)
    return ()
end

# internal

func _is_combat_init{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (is_init : felt):
    alloc_locals
    let (combat) = _get_combat(combat_id)
    if combat.init_hero_count == 0:
        return (FALSE)
    end
    return (TRUE)
end

func FR3rd_submit_action{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, round_id : felt, hero_index : felt, type : felt, target : felt
) -> ():
    alloc_locals
    # check hero in combat
    let (hero) = FR3rd_combat_hero.read(combat_id, hero_index)
    let (sender) = get_caller_address()
    with_attr error_message("FR3rd_action: hero_index error "):
        assert hero.address = sender
    end

    # check no action
    let (action) = FR3rd_action.read(combat_id, round_id, hero_index)
    with_attr error_message("FR3rd_action: already action "):
        assert action.type = 0
    end

    local new_action : Action
    assert new_action.hero_index = hero_index
    assert new_action.type = type
    assert new_action.target = target
    assert new_action.damage = 0
    FR3rd_action.write(combat_id, round_id, hero_index, new_action)

    let (combat) = FR3rd_combat.read(combat_id)
    FR3rd_base_update_combat(
        combat_id=combat_id,
        round=combat.round,
        action_count=combat.action_count + 1,
        agility_1st=combat.agility_1st,
        damage_to_boss_1st=combat.damage_to_boss_1st,
        cur_hero_count=combat.cur_hero_count,
        init_hero_count=combat.init_hero_count,
        last_round_time=combat.last_round_time,
        end_info=combat.end_info,
    )
    FR3rd_try_end_cur_round(combat_id)
    return ()
end

func FR3rd_try_end_cur_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> ():
    alloc_locals
    let (combat) = FR3rd_combat.read(combat_id)
    let (is_combat) = FR3rd_try_combat(combat_id)
    if is_combat == FALSE:
        return ()
    end
    # try clear
    let (is_end) = FR3rd_try_clear_combat(combat_id)
    if is_end == FALSE:
        # init next round
        let (block_timestamp) = get_block_timestamp()
        FR3rd_base_update_combat(
            combat_id=combat_id,
            round=combat.round + 1,
            action_count=0,
            agility_1st=combat.agility_1st,
            damage_to_boss_1st=combat.damage_to_boss_1st,
            cur_hero_count=combat.cur_hero_count,
            init_hero_count=combat.init_hero_count,
            last_round_time=block_timestamp,
            end_info=combat.end_info,
        )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    return ()
end


func FR3rd_get_survivings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (indexs_len:felt,indexs:felt*,target:felt):
    alloc_locals
    let (combat) = _get_combat(combat_id)
    let (local hero_indexs : felt*) = alloc()
    let (count) = FR3rd_base_find_surviving_loop(combat_id, hero_indexs, 1, combat.init_hero_count)
    if count == 0:
        return (0,hero_indexs,0) 
    end
    let (random) = FR3rd_base_random()
    let (r) = get_random_number(random, 1, count)
    return (count,hero_indexs,hero_indexs[r])

end

func FR3rd_try_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (is_combat:felt):
    alloc_locals
    let (combat) = _get_combat(combat_id)
    if combat.end_info != 0:
        return (FALSE)
    end
    # check status
    let (is_round_end) = FR3rd_base_is_round_end(combat_id)
    if combat.action_count != combat.cur_hero_count:
        if is_round_end == FALSE:
            return (FALSE)
        end
    end

    # boss action
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    let (local hero_indexs : felt*) = alloc()
    let (count) = FR3rd_base_find_surviving_loop(combat_id, hero_indexs, 1, combat.init_hero_count)
    let (random) = FR3rd_base_random()
    let (r) = get_random_number(random, 1, count)

    local boss_action : Action
    assert boss_action.hero_index = BOSS_INDEX
    assert boss_action.type = ACTION_TYPE_ATK
    assert boss_action.target = hero_indexs[r]
    assert boss_action.damage = 0
    FR3rd_action.write(combat_id, combat.round, BOSS_INDEX, boss_action)
    let (dead) = _combat_action_loop(
        combat_id, combat.round,combat.agility_1st,  combat.init_hero_count + 1
    )
    with_attr error_message("FR3rd_combat: dead error"):
        assert_le(dead, combat.cur_hero_count)
    end
    FR3rd_base_update_combat(
        combat_id=combat_id,
        round=combat.round,
        action_count=combat.action_count,
        agility_1st=combat.agility_1st,
        damage_to_boss_1st=combat.damage_to_boss_1st,
        cur_hero_count=combat.cur_hero_count - dead,
        init_hero_count=combat.init_hero_count,
        last_round_time=combat.last_round_time,
        end_info=combat.end_info,
    )
    return (TRUE)
end

func _combat_action_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, round_id : felt, current_hero_index : felt, left
) -> (dead):
    alloc_locals
    if left == 0:
        return (0)
    end
    let (action) = FR3rd_action.read(combat_id, round_id, current_hero_index)
    let (hero) = FR3rd_combat_hero.read(combat_id, current_hero_index)
    # dead or no action
    if hero.health * action.type != 0:
        let (cur_dead) = _combat_action_deal(combat_id, round_id, current_hero_index, hero, action)
        let (dead) = _combat_action_loop(
            combat_id, round_id, hero.agility_next_hero, left-1
        )
        return (cur_dead + dead)
    end
    let (dead) = _combat_action_loop(
        combat_id, round_id, hero.agility_next_hero, left-1
    )
    return (dead)
end

func _combat_action_deal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, round_id : felt, hero_index : felt, hero : Hero, action : Action
) -> (dead : felt):
    alloc_locals
    if action.type == ACTION_TYPE_PROP:
        FR3rd_use_prop(combat_id, action.target, hero.address)
        let (add_health) = FR3rd_prop_health(combat_id, hero.address)
        if add_health != 0:
            FR3rd_base_update_hero(
                combat_id,
                hero_index,
                hero.health + add_health,
                hero.bear_from_hero,
                hero.bear_from_boss,
                hero.damage_to_hero,
                hero.damage_to_boss,
                hero.agility_next_hero,
                hero.damage_to_boss_next_hero,
            )
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
        return (0)
    end

    let (opponent) = FR3rd_combat_hero.read(combat_id, action.target)
    if opponent.health == 0:
        return (0)
    end
    let (defense) = FR3rd_base_get_defense(combat_id, action.target, opponent.address)
    let (_atk) = FR3rd_base_get_atk(combat_id, hero_index, hero.address)
    let (atk) = FR3rd_prop_atk(combat_id, hero.address, _atk)
    let (_damage, r) = unsigned_div_rem(atk * atk, atk + defense)
    let (damage) = FR3rd_prop_damage(combat_id, opponent.address, _damage)
    FR3rd_base_update_action(combat_id, round_id, hero_index, action.damage + damage)

    if action.target == BOSS_INDEX:
        FR3rd_base_update_hero(
            combat_id,
            hero_index,
            hero.health,
            hero.bear_from_hero,
            hero.bear_from_boss,
            hero.damage_to_hero,
            hero.damage_to_boss + damage,
            hero.agility_next_hero,
            hero.damage_to_boss_next_hero,
        )
    else:
        FR3rd_base_update_hero(
            combat_id,
            hero_index,
            hero.health,
            hero.bear_from_hero,
            hero.bear_from_boss,
            hero.damage_to_hero + damage,
            hero.damage_to_boss,
            hero.agility_next_hero,
            hero.damage_to_boss_next_hero,
        )
    end
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    let (is_dead) = is_le_felt(opponent.health,damage)
    if is_dead == FALSE:
        if hero_index == BOSS_INDEX:
            FR3rd_base_update_hero(
                combat_id,
                action.target,
                opponent.health - damage,
                opponent.bear_from_hero,
                opponent.bear_from_boss + damage,
                opponent.damage_to_hero,
                opponent.damage_to_boss,
                opponent.agility_next_hero,
                opponent.damage_to_boss_next_hero,
            )
        else:
            FR3rd_base_update_hero(
                combat_id,
                action.target,
                opponent.health - damage,
                opponent.bear_from_hero + damage,
                opponent.bear_from_boss,
                opponent.damage_to_hero,
                opponent.damage_to_boss,
                opponent.agility_next_hero,
                opponent.damage_to_boss_next_hero,
            )
        end
    else:
        if hero_index == BOSS_INDEX:
            FR3rd_base_update_hero(
                combat_id,
                action.target,
                0,
                opponent.bear_from_hero,
                opponent.bear_from_boss + damage,
                opponent.damage_to_hero,
                opponent.damage_to_boss,
                opponent.agility_next_hero,
                opponent.damage_to_boss_next_hero,
            )
        else:
            FR3rd_base_update_hero(
                combat_id,
                action.target,
                0,
                opponent.bear_from_hero + damage,
                opponent.bear_from_boss,
                opponent.damage_to_hero,
                opponent.damage_to_boss,
                opponent.agility_next_hero,
                opponent.damage_to_boss_next_hero,
            )
        end
    end
    if is_dead == TRUE:
        if action.target != BOSS_INDEX:
            return (1)
        end
    end
    return (0)
end
