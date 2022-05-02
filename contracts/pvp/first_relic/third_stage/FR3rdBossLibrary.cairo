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
from contracts.pvp.first_relic.third_stage.structs import (
    Hero,
    Combat,
    Combat_meta,
    Boss_meta,
    Action,
)
from contracts.pvp.first_relic.third_stage.storages import (
    FR3rd_reward_token,
    FR3rd_combat,
    FR3rd_combat_hero,
    FR3rd_action,
    FR3rd_cur_boss_meta,
    FR3rd_boss_meta_len,
    FR3rd_boss_meta,
    FR3rd_cur_combat_meta,
    FR3rd_combat_meta,
    FR3rd_combat_meta_len,
)

from contracts.pvp.first_relic.third_stage.constants import (
    BOSS_INDEX,
    BOSS_ADDRESS,
    ACTION_TYPE_ATK,
    ACTION_TYPE_PROP,
    DEFAULT_NEXT_HERO_INDEX,
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
    FR3rd_get_heros_loop(combat_id=combat_id, cur_index=0, heros=heros, left=combat.hero_count + 1)
    return (heros_len=combat.hero_count + 1, heros=heros)
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
        cur_index=hero.next_hero_index,
        actions=actions + Action.SIZE,
        left=left - 1,
    )
    return (len + 1)
end

# get combat all info by combat_id
func FR3rd_get_combat_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (
    heros_len : felt,
    heros : Hero*,
    actions_len : felt,
    actions : Action*,
    combat : Combat,
    boss_meta : Boss_meta,
    combat_meta : Combat_meta,
):
    alloc_locals
    let (combat) = _get_combat(combat_id)
    let (boss_meta) = FR3rd_boss_meta.read(combat.boss_id)
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    let (local heros : Hero*) = alloc()
    FR3rd_get_heros_loop(combat_id=combat_id, cur_index=0, heros=heros, left=combat.hero_count + 1)
    let (local actions : Action*) = alloc()
    if combat.round == 0:
        return (
            heros_len=combat.hero_count + 1,
            heros=heros,
            actions_len=0,
            actions=actions,
            combat=combat,
            boss_meta=boss_meta,
            combat_meta=combat_meta,
        )
    else:
        let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
        let (actions_len) = FR3rd_get_actions_loop(
            combat_id=combat_id,
            round_id=combat.round - 1,
            cur_index=combat.hero_1th,
            actions=actions,
            left=combat_meta.max_hero + 1,
        )
        return (
            heros_len=combat.hero_count + 1,
            heros=heros,
            actions_len=actions_len,
            actions=actions,
            combat=combat,
            boss_meta=boss_meta,
            combat_meta=combat_meta,
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
        assert_lt(combat.hero_count, combat_meta.max_hero)
    end
    let (is_in) = FR3rd_check_hero_in_loop(
        sender=address, combat_id=combat_id, left=combat.hero_count
    )
    with_attr error_message("FR3rd_join: is in "):
        assert is_in = FALSE
    end
    let (block_timestamp) = get_block_timestamp()
    # todo
    let (agility) = get_random_number(address, block_timestamp, 200)
    # let (random) = hash2{hash_ptr=pedersen_ptr}(sender, block_timestamp)
    # let (q, agility) = unsigned_div_rem(random, 100)

    # add hero
    local hero : Hero
    assert hero.address = address
    assert hero.health = 1000
    assert hero.defense = 200
    assert hero.agility = agility
    assert hero.next_hero_index = DEFAULT_NEXT_HERO_INDEX
    assert hero.bear_from_hero = 0
    assert hero.bear_from_boss = 0
    assert hero.damage_to_hero = 0
    assert hero.damage_to_boss = 0
    assert hero.robots = 6

    let new_hero_index = combat.hero_count + 1
    FR3rd_combat_hero.write(combat_id, new_hero_index, hero)
    #
    _update_combat(
        combat_id=combat_id,
        round=combat.round,
        action_count=combat.action_count,
        hero_1th=combat.hero_1th,
        hero_count=new_hero_index,
        last_combat_time=combat.last_combat_time,
        end_info=combat.end_info,
    )
    FR3rd_add_sort_loop(
        combat_id=combat_id,
        agility=agility,
        hero_index=new_hero_index,
        cur_hero_index=combat.hero_1th,
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
    assert combat.total_reward = combat_meta.total_reward
    assert combat.round = 0
    assert combat.action_count = 0
    assert combat.hero_count = 0
    assert combat.hero_1th = 0
    assert combat.start_time = block_timestamp
    assert combat.last_combat_time = block_timestamp
    assert combat.end_info = 0
    FR3rd_combat.write(combat_id, combat)

    let (boss_meta) = FR3rd_boss_meta.read(boss_id)

    # add boss as hero
    local boss : Hero
    assert boss.address = 0
    assert boss.health = boss_meta.health
    assert boss.defense = boss_meta.defense
    assert boss.agility = boss_meta.agility
    assert boss.robots = 6
    assert boss.next_hero_index = DEFAULT_NEXT_HERO_INDEX
    assert boss.bear_from_hero = 0
    assert boss.bear_from_boss = 0
    assert boss.damage_to_hero = 0
    assert boss.damage_to_boss = 0
    FR3rd_combat_hero.write(combat_id, BOSS_INDEX, boss)
    return ()
end

func FR3rd_check_hero_in_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    sender : felt, combat_id : felt, left
) -> (is_in : felt):
    alloc_locals
    if left == 0:
        return (FALSE)
    end
    let (hero) = FR3rd_combat_hero.read(combat_id, left)
    if hero.address == sender:
        return (TRUE)
    end
    return FR3rd_check_hero_in_loop(sender=sender, combat_id=combat_id, left=left - 1)
end

func FR3rd_add_sort_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt,
    agility : felt,
    hero_index : felt,
    cur_hero_index : felt,
    pre_hero_index : felt,
    left,
) -> ():
    alloc_locals

    # hero is the last
    if left == 0:
        let (hero) = FR3rd_combat_hero.read(combat_id, pre_hero_index)
        _update_hero(
            combat_id,
            pre_hero_index,
            hero.health,
            hero_index,
            hero.bear_from_hero,
            hero.bear_from_boss,
            hero.damage_to_hero,
            hero.damage_to_boss,
        )
        return ()
    end

    let (hero) = FR3rd_combat_hero.read(combat_id, cur_hero_index)
    let (is_le) = is_le_felt(hero.agility + 1, agility)
    if is_le == TRUE:
        _update_hero(
            combat_id,
            hero_index,
            hero.health,
            cur_hero_index,
            hero.bear_from_hero,
            hero.bear_from_boss,
            hero.damage_to_hero,
            hero.damage_to_boss,
        )
        if hero_index == left:
            let (combat) = FR3rd_combat.read(combat_id)
            _update_combat(
                combat_id=combat_id,
                round=combat.round,
                action_count=combat.action_count,
                hero_1th=hero_index,
                hero_count=combat.hero_count,
                last_combat_time=combat.last_combat_time,
                end_info=combat.end_info,
            )
        else:
            _update_hero(
                combat_id,
                pre_hero_index,
                hero.health,
                hero_index,
                hero.bear_from_hero,
                hero.bear_from_boss,
                hero.damage_to_hero,
                hero.damage_to_boss,
            )
        end
        return ()
    else:
        return FR3rd_add_sort_loop(
            combat_id, agility, hero_index, hero.next_hero_index, cur_hero_index, left - 1
        )
    end
end

# internal

func _is_combat_init{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (is_init : felt):
    alloc_locals
    let (combat) = _get_combat(combat_id)
    if combat.hero_count == 0:
        return (FALSE)
    end
    return (TRUE)
end

func FR3rd_combat_is_end{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (is_end : felt):
    alloc_locals
    let (combat) = _get_combat(combat_id)

    if combat.end_info != 0:
        return (TRUE)
    end
    if combat.total_reward == 0:
        return (TRUE)
    end
    return (FALSE)
end

func FR3rd_combat_is_last_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (is_end : felt):
    alloc_locals
    let (combat) = _get_combat(combat_id)

    if combat.end_info != 0:
        return (TRUE)
    end

    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    # check time & round
    let cur_round_end_time = combat.last_combat_time + combat_meta.max_round_time
    let (block_timestamp) = get_block_timestamp()
    let (is_le) = is_le_felt(block_timestamp, cur_round_end_time)
    if is_le == TRUE:
        return (FALSE)
    end
    return (TRUE)
end

func FR3rd_combat_is_round_end{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (is_end : felt):
    alloc_locals
    let (combat) = _get_combat(combat_id)
    if combat.end_info != 0:
        return (TRUE)
    end
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    let (is_le_round) = is_le_felt(combat.round + 2, combat_meta.max_round)
    if is_le_round == TRUE:
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
    _update_combat(
        combat_id=combat_id,
        round=combat.round,
        action_count=combat.action_count + 1,
        hero_1th=combat.hero_1th,
        hero_count=combat.hero_count,
        last_combat_time=combat.last_combat_time,
        end_info=combat.end_info,
    )
    if (combat.action_count + 1) == combat.hero_count:
        _combat(combat_id)
        # try clear
        let (result) = FR3rd_try_clear_combat(combat_id)
        if result == FALSE:
            # init next round
            let (block_timestamp) = get_block_timestamp()
            _update_combat(
                combat_id=combat_id,
                round=combat.round + 1,
                action_count=0,
                hero_1th=combat.hero_1th,
                hero_count=combat.hero_count,
                last_combat_time=block_timestamp,
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

# internal  check if can combat 0:false, 1 true
func FR3rd_try_clear_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (result : felt):
    alloc_locals
    # if boss dead
    let (boss) = FR3rd_combat_hero.read(combat_id, 0)
    let (combat) = FR3rd_combat.read(combat_id)
    if boss.health == 0:
        FR3rd_reward_boss_dead(combat_id)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        _update_combat(
            combat_id=combat_id,
            round=combat.round,
            action_count=combat.action_count,
            hero_1th=combat.hero_1th,
            hero_count=combat.hero_count,
            last_combat_time=combat.last_combat_time,
            end_info=1,
        )
        return (TRUE)
    end

    # if all hreo dead
    let (combat) = FR3rd_combat.read(combat_id)
    if combat.hero_count == 0:
        _update_combat(
            combat_id=combat_id,
            round=combat.round,
            action_count=combat.action_count,
            hero_1th=combat.hero_1th,
            hero_count=combat.hero_count,
            last_combat_time=combat.last_combat_time,
            end_info=2,
        )
        return (TRUE)
    end

    # if round end
    let (is_end) = FR3rd_combat_is_round_end(combat_id)
    let (is_last) = FR3rd_combat_is_last_round(combat_id)
    if (is_end * is_last) == TRUE:
        if boss.bear_from_hero == 0:
            # no reward
            _update_combat(
                combat_id=combat_id,
                round=combat.round,
                action_count=combat.action_count,
                hero_1th=combat.hero_1th,
                hero_count=combat.hero_count,
                last_combat_time=combat.last_combat_time,
                end_info=4,
            )
        else:
            _update_combat(
                combat_id=combat_id,
                round=combat.round,
                action_count=combat.action_count,
                hero_1th=combat.hero_1th,
                hero_count=combat.hero_count,
                last_combat_time=combat.last_combat_time,
                end_info=3,
            )
        end
        return (TRUE)
    end
    return (FALSE)
end

#
func FR3rd_reward_boss_dead{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> ():
    alloc_locals
    let (combat) = FR3rd_combat.read(combat_id)
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    let (local hero_indexs : felt*) = alloc()
    let (count) = FR3rd_find_surviving_loop(combat_id, hero_indexs, 1, combat_meta.max_hero)
    if count != 0:
        let (amount, r) = unsigned_div_rem(combat.total_reward, count)
        let (uint256Amount) = _felt_to_uint(amount)
        FR3rd_reward_boss_dead_loop(combat_id, uint256Amount, hero_indexs, count)
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

func FR3rd_find_surviving_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, hero_indexs : felt*, cur_hero_index : felt, left
) -> (count : felt):
    alloc_locals
    if left == 0:
        return (0)
    end
    let (hero) = FR3rd_combat_hero.read(combat_id, cur_hero_index)
    let (is_le) = is_le_felt(1, hero.health)
    if is_le == TRUE:
        assert [hero_indexs] = cur_hero_index
    end
    let (count) = FR3rd_find_surviving_loop(
        combat_id, hero_indexs + 1, cur_hero_index + 1, left - 1
    )
    if is_le == TRUE:
        return (count + 1)
    else:
        return (count)
    end
end

# func FR3rd_find_surviving_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     combat_id:felt,hero_indexs : felt*,cur_hero_index : felt,left
# ) -> (count: felt):
#     alloc_locals
#     if left ==0 :
#         return(0)
#     end
#     let (hero) = FR3rd_combat_hero.read(combat_id, cur_hero_index)
#     let (is_le) = is_le_felt(1, hero.health)
#     if is_le == TRUE:
#         assert [hero_indexs] = cur_hero_index
#     end
#     let (count) = FR3rd_find_surviving_loop(combat_id,hero_indexs,cur_hero_index+1,left-1)
#     if is_le == TRUE:
#         return (count +1)
#     else:
#         return (count)
#     end
# end

func FR3rd_reward_boss_dead_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, amount : Uint256, hero_indexs : felt*, left
) -> ():
    alloc_locals
    if left == 0:
        return ()
    end
    let (hero) = FR3rd_combat_hero.read(combat_id, [hero_indexs])
    let (contract_address) = FR3rd_reward_token.read()
    let (res) = IERC20.transfer(
        contract_address=contract_address, recipient=hero.address, amount=amount
    )
    FR3rd_reward_boss_dead_loop(combat_id, amount, hero_indexs + 1, left - 1)
    return ()
end

# internal  check if can combat 0:false, 1 true
func FR3rd_can_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (result : felt):
    alloc_locals
    let (combat) = _get_combat(combat_id)
    if combat.end_info != 0:
        return (FALSE)
    end
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    if combat.action_count == combat.hero_count:
        return (TRUE)
    else:
        let combat_end_time = combat.last_combat_time + combat_meta.max_round_time
        let (block_timestamp) = get_block_timestamp()
        let (is_le) = is_le_felt(combat_end_time, block_timestamp)
        if is_le == 1:
            return (TRUE)
        end
    end
    return (FALSE)
end

func FR3rd_random{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    hash : felt
):
    alloc_locals
    let (sender) = get_caller_address()
    let (block_timestamp) = get_block_timestamp()
    let (hash) = hash2{hash_ptr=pedersen_ptr}(sender, block_timestamp)
    return (hash)
end

func _combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> ():
    alloc_locals
    let (combat) = _get_combat(combat_id)
    # check status
    let (can_combat) = FR3rd_can_combat(combat_id)
    with_attr error_message("FR3rd_combat: status error "):
        assert can_combat = TRUE
    end
    # boss action
    let (random) = FR3rd_random()
    let (r) = get_random_number(random, 1, combat.hero_count)

    local boss_action : Action
    assert boss_action.hero_index = BOSS_INDEX
    assert boss_action.type = 4
    assert boss_action.target = r
    assert boss_action.damage = 0
    FR3rd_action.write(combat_id, combat.round, BOSS_INDEX, boss_action)
    let (dead) = _combat_action_loop(
        combat_id, combat.round, combat.hero_count + 1, combat.hero_1th, 0
    )
    # todo update dead
    with_attr error_message("FR3rd_combat: dead error"):
        assert_le(dead, combat.hero_count)
    end
    _update_combat(
        combat_id=combat_id,
        round=combat.round,
        action_count=combat.action_count,
        hero_1th=combat.hero_1th,
        hero_count=combat.hero_count - dead,
        last_combat_time=combat.last_combat_time,
        end_info=combat.end_info,
    )
    return ()
end

func _combat_action_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, round_id : felt, total_action : felt, current_hero_index : felt, have_done
) -> (dead):
    alloc_locals

    if total_action == have_done:
        return (0)
    end

    let (action) = FR3rd_action.read(combat_id, round_id, current_hero_index)
    let (hero) = FR3rd_combat_hero.read(combat_id, current_hero_index)
    # dead or no action
    if hero.health * action.type != 0:
        let (cur_dead) = _combat_action_deal(combat_id, round_id, current_hero_index, hero, action)
        let (dead) = _combat_action_loop(
            combat_id, round_id, total_action, hero.next_hero_index, have_done + 1
        )
        return (cur_dead + dead)
    end
    let (dead) = _combat_action_loop(
        combat_id, round_id, total_action, hero.next_hero_index, have_done + 1
    )
    return (dead)
end

func _combat_action_deal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, round_id : felt, hero_index : felt, hero : Hero, action : Action
) -> (dead):
    alloc_locals
    if action.type == 3:
        return (0)
    end

    let (opponent) = FR3rd_combat_hero.read(combat_id, action.target)
    if opponent.health == 0:
        return (0)
    end
    let atk = hero.robots * 60
    let (damage, r) = unsigned_div_rem(atk * atk, atk + opponent.defense)
    _update_action(combat_id, round_id, hero_index, action.damage + damage)

    if action.target == BOSS_INDEX:
        _update_hero(
            combat_id,
            hero_index,
            hero.health,
            hero.next_hero_index,
            hero.bear_from_hero,
            hero.bear_from_boss,
            hero.damage_to_hero,
            hero.damage_to_boss + damage,
        )
    else:
        _update_hero(
            combat_id,
            hero_index,
            hero.health,
            hero.next_hero_index,
            hero.bear_from_hero,
            hero.bear_from_boss,
            hero.damage_to_hero + damage,
            hero.damage_to_boss,
        )
    end
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    let (is_le) = is_le_felt(damage, opponent.health)
    if is_le == TRUE:
        if hero_index == BOSS_INDEX:
            _update_hero(
                combat_id,
                action.target,
                opponent.health - damage,
                opponent.next_hero_index,
                opponent.bear_from_hero,
                opponent.bear_from_boss + damage,
                opponent.damage_to_hero + damage,
                opponent.damage_to_boss,
            )
        else:
            _update_hero(
                combat_id,
                action.target,
                opponent.health - damage,
                opponent.next_hero_index,
                opponent.bear_from_hero + damage,
                opponent.bear_from_boss,
                opponent.damage_to_hero + damage,
                opponent.damage_to_boss,
            )
        end
    else:
        if hero_index == BOSS_INDEX:
            _update_hero(
                combat_id,
                action.target,
                0,
                opponent.next_hero_index,
                opponent.bear_from_hero,
                opponent.bear_from_boss + damage,
                opponent.damage_to_hero + damage,
                opponent.damage_to_boss,
            )
        else:
            _update_hero(
                combat_id,
                action.target,
                0,
                opponent.next_hero_index,
                opponent.bear_from_hero + damage,
                opponent.bear_from_boss,
                opponent.damage_to_hero + damage,
                opponent.damage_to_boss,
            )
        end
    end
    if is_le == FALSE:
        if action.target != BOSS_INDEX:
            return (1)
        end
    end
    return (0)
end

# _update_combat(combat_id= ,round= ,action_count=,hero_1th=,hero_count=,last_combat_time=,end_info=)
func _update_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt,
    round : felt,
    action_count : felt,
    hero_1th : felt,
    hero_count : felt,
    last_combat_time : felt,
    end_info : felt,
) -> ():
    alloc_locals
    let (combat) = FR3rd_combat.read(combat_id)
    local new_combat : Combat
    assert new_combat.combat_id = combat.combat_id
    assert new_combat.meta_id = combat.meta_id
    assert new_combat.boss_id = combat.boss_id
    assert new_combat.total_reward = combat.total_reward
    assert new_combat.start_time = combat.start_time

    # round
    assert new_combat.round = round

    # action_count
    assert new_combat.action_count = action_count

    # hero_count
    assert new_combat.hero_count = hero_count

    # hero_1th
    assert new_combat.hero_1th = hero_1th

    # last_combat_time
    assert new_combat.last_combat_time = last_combat_time

    # end_info
    assert new_combat.end_info = end_info
    FR3rd_combat.write(combat_id, new_combat)
    return ()
end

# _update_hero(combat_id,hero_index, health,next_hero_index,bear_from_hero,bear_from_boss,damage_to_hero,damage_to_boss)
func _update_hero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt,
    hero_index : felt,
    health : felt,
    next_hero_index : felt,
    bear_from_hero : felt,
    bear_from_boss : felt,
    damage_to_hero : felt,
    damage_to_boss : felt,
) -> ():
    alloc_locals
    let (hero) = FR3rd_combat_hero.read(combat_id, hero_index)
    local new_hero : Hero
    assert new_hero.address = hero.address
    assert new_hero.defense = hero.defense
    assert new_hero.agility = hero.agility
    assert new_hero.robots = hero.robots

    # health
    assert new_hero.health = health
    # bear
    assert new_hero.bear_from_hero = bear_from_hero
    assert new_hero.bear_from_boss = bear_from_boss

    # damage
    assert new_hero.damage_to_hero = damage_to_hero
    assert new_hero.damage_to_boss = damage_to_boss

    # next_hero_index
    assert new_hero.next_hero_index = next_hero_index

    FR3rd_combat_hero.write(combat_id, hero_index, new_hero)
    return ()
end

# _update_action(combat_id,round_id,hero_index, damage)
func _update_action{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, round_id : felt, hero_index : felt, damage : felt
) -> ():
    alloc_locals

    let (action) = FR3rd_action.read(combat_id, round_id, hero_index)
    local new_action : Action
    assert new_action.hero_index = action.hero_index
    assert new_action.type = action.type
    assert new_action.target = action.target
    assert new_action.damage = damage

    FR3rd_action.write(combat_id, round_id, hero_index, new_action)
    return ()
end
