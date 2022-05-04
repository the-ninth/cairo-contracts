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

from contracts.pvp.first_relic.third_stage.FR3rdPropLibrary import (
    FR3rd_use_prop,
    FR3rd_prop_atk,
    FR3rd_prop_damage,
    FR3rd_prop_health,
)

from contracts.pvp.first_relic.third_stage.base.constants import (
    BOSS_INDEX,
    BOSS_ADDRESS,
    ACTION_TYPE_ATK,
    ACTION_TYPE_PROP,
    DEFAULT_NEXT_HERO_INDEX,
)

from contracts.pvp.first_relic.third_stage.base.FR3rdBaseLibrary import (
    FR3rd_base_update_hero,
    FR3rd_base_update_combat,
    FR3rd_base_is_round_end,
    FR3rd_base_is_last_round,
    FR3rd_base_sort_by_damage_to_boss,
    FR3rd_base_find_surviving_loop,
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

#
# getters
#

# internal  check if can combat 0:false, 1 true
func FR3rd_try_clear_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (is_end : felt):
    alloc_locals
    # if boss dead
    let (boss) = FR3rd_combat_hero.read(combat_id, 0)

    if boss.health == 0:
        FR3rd_reward_boss_dead(combat_id)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        let (combat) = FR3rd_combat.read(combat_id)
        FR3rd_base_update_combat(
            combat_id=combat_id,
            round=combat.round,
            action_count=combat.action_count,
            agility_1st=combat.agility_1st,
            damage_to_boss_1st=combat.damage_to_boss_1st,
            cur_hero_count=combat.cur_hero_count,
            init_hero_count=combat.init_hero_count,
            last_round_time=combat.last_round_time,
            end_info=1,
        )
        return (TRUE)
    end

    # if all hreo dead
    let (combat) = FR3rd_combat.read(combat_id)
    if combat.cur_hero_count == 0:
        FR3rd_reward_hero_dead(combat_id)
        let (combat) = FR3rd_combat.read(combat_id)
        FR3rd_base_update_combat(
            combat_id=combat_id,
            round=combat.round,
            action_count=combat.action_count,
            agility_1st=combat.agility_1st,
            damage_to_boss_1st=combat.damage_to_boss_1st,
            cur_hero_count=combat.cur_hero_count,
            init_hero_count=combat.init_hero_count,
            last_round_time=combat.last_round_time,
            end_info=2,
        )
        return (TRUE)
    end

    let (is_end) = FR3rd_base_is_round_end(combat_id)
    let (is_last) = FR3rd_base_is_last_round(combat_id)

    # not end
    if (1 - is_end) * (1 - is_last) == TRUE:
        return (FALSE)
    end

    if boss.bear_from_hero == 0:
        # no reward
        let (combat) = FR3rd_combat.read(combat_id)
        FR3rd_base_update_combat(
            combat_id=combat_id,
            round=combat.round,
            action_count=combat.action_count,
            agility_1st=combat.agility_1st,
            damage_to_boss_1st=combat.damage_to_boss_1st,
            cur_hero_count=combat.cur_hero_count,
            init_hero_count=combat.init_hero_count,
            last_round_time=combat.last_round_time,
            end_info=4,
        )
    else:
        FR3rd_reward_hero_dead(combat_id)
        let (combat) = FR3rd_combat.read(combat_id)
        FR3rd_base_update_combat(
            combat_id=combat_id,
            round=combat.round,
            action_count=combat.action_count,
            agility_1st=combat.agility_1st,
            damage_to_boss_1st=combat.damage_to_boss_1st,
            cur_hero_count=combat.cur_hero_count,
            init_hero_count=combat.init_hero_count,
            last_round_time=combat.last_round_time,
            end_info=3,
        )
    end
    return (TRUE)
end

func FR3rd_reward_hero_dead{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> ():
    alloc_locals
    # sort by damage
    FR3rd_base_sort_by_damage_to_boss(combat_id)
    let (combat) = FR3rd_combat.read(combat_id)
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    let (local hero_indexs : felt*) = alloc()
    let (count) = FR3rd_get_heros_loop_by_damage(
        combat_id, combat.damage_to_boss_1st, hero_indexs, 3, 0, combat_meta.max_hero
    )
    if count != 0:
        let (amount, r) = unsigned_div_rem(combat_meta.total_reward, count)
        let (uint256Amount) = _felt_to_uint(amount)
        FR3rd_reward_loop(combat_id, uint256Amount, hero_indexs, count)
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

# boss dead
func FR3rd_reward_boss_dead{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> ():
    alloc_locals
    let (combat) = FR3rd_combat.read(combat_id)
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    let (local hero_indexs : felt*) = alloc()
    let (count) = FR3rd_base_find_surviving_loop(combat_id, hero_indexs, 1, combat_meta.max_hero)
    if count != 0:
        let (amount, r) = unsigned_div_rem(combat_meta.total_reward, count)
        let (uint256Amount) = _felt_to_uint(amount)
        FR3rd_reward_loop(combat_id, uint256Amount, hero_indexs, count)
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

func FR3rd_get_heros_loop_by_damage{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(combat_id : felt, cur_index : felt, hero_indexs : felt*, max : felt, have_done : felt, left) -> (
    len : felt
):
    alloc_locals
    if left == 0:
        return (0)
    end
    if cur_index == DEFAULT_NEXT_HERO_INDEX:
        return (0)
    end
    let (local hero) = FR3rd_combat_hero.read(combat_id, cur_index)
    if hero.damage_to_boss == 0:
        return (0)
    end
    if have_done == max:
        return (0)
    end
    assert [hero_indexs] = cur_index
    let (len) = FR3rd_get_heros_loop_by_damage(
        combat_id, hero.damage_to_boss_next_hero, hero_indexs + 1, max, have_done + 1, left=left - 1
    )
    return (len + 1)
end

func FR3rd_reward_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
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
    FR3rd_reward_loop(combat_id, amount, hero_indexs + 1, left - 1)
    return ()
end
