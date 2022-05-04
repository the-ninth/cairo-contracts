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
)

from contracts.pvp.first_relic.third_stage.base.constants import (
    BOSS_INDEX,
    BOSS_ADDRESS,
    ACTION_TYPE_ATK,
    ACTION_TYPE_PROP,
    DEFAULT_NEXT_HERO_INDEX,
)
@event
func Demo1(step : felt, info : felt, step1 : felt, info1 : felt):
end

from contracts.pvp.first_relic.structs import Koma, Prop

from contracts.pvp.first_relic.IFirstRelicCombat import IFirstRelicCombat

# get combat info by index
func FR3rd_base_get_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (combat : Combat):
    let (combat) = FR3rd_combat.read(combat_id)
    # todo
    # with_attr error_message("FR3rd_base_get_combat: combat error"):
    #     assert_not_zero(combat.timestamp)
    # end
    return (combat=combat)
end

func FR3rd_base_is_round_end{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (is_end : felt):
    alloc_locals
    let (combat) = FR3rd_base_get_combat(combat_id)

    if combat.end_info != 0:
        return (TRUE)
    end

    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    # check time & round
    let cur_round_end_time = combat.last_round_time + combat_meta.max_round_time
    let (block_timestamp) = get_block_timestamp()
    let (is_end) = is_le(cur_round_end_time, block_timestamp)
    return (is_end)
end

func FR3rd_base_is_last_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt
) -> (is_end : felt):
    alloc_locals
    let (combat) = FR3rd_base_get_combat(combat_id)
    if combat.end_info != 0:
        return (TRUE)
    end
    let (combat_meta) = FR3rd_combat_meta.read(combat.meta_id)
    let (is_end) = is_le(combat_meta.max_round, combat.round + 1)
    return (is_end)
end

func FR3rd_base_check_hero_in_loop{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(sender : felt, combat_id : felt, left) -> (is_in : felt):
    alloc_locals
    if left == 0:
        return (FALSE)
    end
    let (hero) = FR3rd_combat_hero.read(combat_id, left)
    if hero.address == sender:
        return (TRUE)
    end
    return FR3rd_base_check_hero_in_loop(sender=sender, combat_id=combat_id, left=left - 1)
end

func FR3rd_base_find_surviving_loop{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(combat_id : felt, hero_indexs : felt*, cur_hero_index : felt, left) -> (count : felt):
    alloc_locals
    if left == 0:
        return (0)
    end
    let (hero) = FR3rd_combat_hero.read(combat_id, cur_hero_index)
    let (is_l) = is_le(1, hero.health)
    if is_l == TRUE:
        assert [hero_indexs] = cur_hero_index
        let (count) = FR3rd_base_find_surviving_loop(
            combat_id, hero_indexs + 1, cur_hero_index + 1, left - 1
        )
        return (count + 1)
    end
    let (count) = FR3rd_base_find_surviving_loop(
        combat_id, hero_indexs, cur_hero_index + 1, left - 1
    )
    return (count)
end

func FR3rd_base_random{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    hash : felt
):
    alloc_locals
    let (sender) = get_caller_address()
    let (block_timestamp) = get_block_timestamp()
    let (hash) = hash2{hash_ptr=pedersen_ptr}(sender, block_timestamp)
    return (hash)
end

func FR3rd_base_sort_by_damage_to_boss{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(combat_id : felt) -> ():
    alloc_locals
    let (combat) = FR3rd_base_get_combat(combat_id)
    FR3rd_base_sort_by_damage_to_boss_loop(combat_id, 2, combat.init_hero_count - 1)
    return ()
end

func FR3rd_base_sort_by_damage_to_boss_loop{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(combat_id : felt, hero_index : felt, left) -> ():
    alloc_locals
    if left == 0:
        return ()
    end
    let (hero) = FR3rd_combat_hero.read(combat_id, hero_index)
    if hero.damage_to_boss != 0:
        let (combat) = FR3rd_base_get_combat(combat_id)
        FR3rd_base_sort_by_damage_to_boss_loop2(
            combat_id,
            hero.damage_to_boss,
            hero_index,
            hero,
            combat.damage_to_boss_1st,
            0,
            hero_index - 1,
        )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    FR3rd_base_sort_by_damage_to_boss_loop(combat_id, hero_index + 1, left - 1)
    return ()
end

func FR3rd_base_sort_by_damage_to_boss_loop2{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(
    combat_id : felt,
    damage_to_boss : felt,
    hero_index : felt,
    hero : Hero,
    cur_hero_index : felt,
    pre_hero_index : felt,
    left,
) -> ():
    alloc_locals
    # hero is the last
    if left == 0:
        let (pre_hero) = FR3rd_combat_hero.read(combat_id, pre_hero_index)
        FR3rd_base_update_hero(
            combat_id,
            pre_hero_index,
            pre_hero.health,
            pre_hero.bear_from_hero,
            pre_hero.bear_from_boss,
            pre_hero.damage_to_hero,
            pre_hero.damage_to_boss,
            pre_hero.agility_next_hero,
            hero_index,
        )
        return ()
    end
    let (cur_hero) = FR3rd_combat_hero.read(combat_id, cur_hero_index)
    let (is_l) = is_le(cur_hero.damage_to_boss + 1, damage_to_boss)
    if is_l == TRUE:
        FR3rd_base_update_hero(
            combat_id,
            hero_index,
            hero.health,
            hero.bear_from_hero,
            hero.bear_from_boss,
            hero.damage_to_hero,
            hero.damage_to_boss,
            hero.agility_next_hero,
            cur_hero_index,
        )
        let (combat) = FR3rd_combat.read(combat_id)
        if cur_hero_index == combat.damage_to_boss_1st:
            FR3rd_base_update_combat(
                combat_id=combat_id,
                round=combat.round,
                action_count=combat.action_count,
                agility_1st=combat.agility_1st,
                damage_to_boss_1st=hero_index,
                cur_hero_count=combat.cur_hero_count,
                init_hero_count=combat.init_hero_count,
                last_round_time=combat.last_round_time,
                end_info=combat.end_info,
            )
        else:
            let (pre_hero) = FR3rd_combat_hero.read(combat_id, pre_hero_index)
            FR3rd_base_update_hero(
                combat_id,
                pre_hero_index,
                pre_hero.health,
                pre_hero.bear_from_hero,
                pre_hero.bear_from_boss,
                pre_hero.damage_to_hero,
                pre_hero.damage_to_boss,
                pre_hero.agility_next_hero,
                hero_index,
            )
        end
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        FR3rd_base_sort_by_damage_to_boss_loop2(
            combat_id,
            damage_to_boss,
            hero_index,
            hero,
            cur_hero.damage_to_boss_next_hero,
            cur_hero_index,
            left - 1,
        )
    end
    return ()
end

func FR3rd_base_sort_by_agility_loop{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(
    combat_id : felt,
    agility : felt,
    hero_index : felt,
    hero : Hero,
    cur_hero_index : felt,
    pre_hero_index : felt,
    left,
) -> ():
    alloc_locals

    # hero is the last
    if left == 0:
        let (pre_hero) = FR3rd_combat_hero.read(combat_id, pre_hero_index)
        FR3rd_base_update_hero(
            combat_id,
            pre_hero_index,
            pre_hero.health,
            pre_hero.bear_from_hero,
            pre_hero.bear_from_boss,
            pre_hero.damage_to_hero,
            pre_hero.damage_to_boss,
            hero_index,
            pre_hero.damage_to_boss_next_hero,
        )
        return ()
    end

    let (cur_hero) = FR3rd_combat_hero.read(combat_id, cur_hero_index)
    let (opp_agility) = FR3rd_base_get_agility(combat_id, cur_hero_index, cur_hero.address)
    let (is_l) = is_le(opp_agility + 1, agility)
    if is_l == TRUE:
        FR3rd_base_update_hero(
            combat_id,
            hero_index,
            hero.health,
            hero.bear_from_hero,
            hero.bear_from_boss,
            hero.damage_to_hero,
            hero.damage_to_boss,
            cur_hero_index,
            hero.damage_to_boss_next_hero,
        )
        let (combat) = FR3rd_combat.read(combat_id)
        if cur_hero_index == combat.agility_1st:
            FR3rd_base_update_combat(
                combat_id=combat_id,
                round=combat.round,
                action_count=combat.action_count,
                agility_1st=hero_index,
                damage_to_boss_1st=combat.damage_to_boss_1st,
                cur_hero_count=combat.cur_hero_count,
                init_hero_count=combat.init_hero_count,
                last_round_time=combat.last_round_time,
                end_info=combat.end_info,
            )
        else:
            let (pre_hero) = FR3rd_combat_hero.read(combat_id, pre_hero_index)
            FR3rd_base_update_hero(
                combat_id,
                pre_hero_index,
                pre_hero.health,
                pre_hero.bear_from_hero,
                pre_hero.bear_from_boss,
                pre_hero.damage_to_hero,
                pre_hero.damage_to_boss,
                hero_index,
                pre_hero.damage_to_boss_next_hero,
            )
        end
        return ()
    else:
        return FR3rd_base_sort_by_agility_loop(
            combat_id,
            agility,
            hero_index,
            hero,
            cur_hero.agility_next_hero,
            cur_hero_index,
            left - 1,
        )
    end
end

func FR3rd_base_get_agility{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, hero_index : felt, address : felt
) -> (agility : felt):
    alloc_locals
    if hero_index == BOSS_INDEX:
        let (combat) = FR3rd_base_get_combat(combat_id)
        let (boss_meta) = FR3rd_boss_meta.read(combat.boss_id)
        return (boss_meta.agility)
    else:
        let (koma) = FR3rd_base_get_koma(combat_id, address)
        return (koma.agility)
    end
end

func FR3rd_base_get_defense{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, hero_index : felt, address : felt
) -> (defense : felt):
    alloc_locals
    if hero_index == BOSS_INDEX:
        let (combat) = FR3rd_base_get_combat(combat_id)
        let (boss_meta) = FR3rd_boss_meta.read(combat.boss_id)
        return (boss_meta.defense)
    else:
        let (koma) = FR3rd_base_get_koma(combat_id, address)
        return (koma.defense)
    end
end

func FR3rd_base_get_atk{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, hero_index : felt, address : felt
) -> (defense : felt):
    alloc_locals
    if hero_index == BOSS_INDEX:
        let (combat) = FR3rd_base_get_combat(combat_id)
        let (boss_meta) = FR3rd_boss_meta.read(combat.boss_id)
        return (boss_meta.atk)
    else:
        let (koma) = FR3rd_base_get_koma(combat_id, address)
        return (koma.atk * koma.drones_count)
    end
end

# FR3rd_base_update_combat(combat_id= ,round= ,action_count=,agility_1st=,damage_to_boss_1st=,cur_hero_count=,init_hero_count=,last_round_time=,end_info=)
func FR3rd_base_update_combat{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt,
    round : felt,
    action_count : felt,
    agility_1st : felt,
    damage_to_boss_1st : felt,
    cur_hero_count : felt,
    init_hero_count : felt,
    last_round_time : felt,
    end_info : felt,
) -> ():
    alloc_locals
    let (combat) = FR3rd_combat.read(combat_id)
    local new_combat : Combat
    assert new_combat.combat_id = combat.combat_id
    assert new_combat.meta_id = combat.meta_id
    assert new_combat.boss_id = combat.boss_id
    assert new_combat.start_time = combat.start_time

    # round
    assert new_combat.round = round

    # action_count
    assert new_combat.action_count = action_count

    # cur_hero_count
    assert new_combat.cur_hero_count = cur_hero_count
    # init_hero_count
    assert new_combat.init_hero_count = init_hero_count

    # agility_1st
    assert new_combat.agility_1st = agility_1st

    # damage_to_boss_1st
    assert new_combat.damage_to_boss_1st = damage_to_boss_1st

    # last_round_time
    assert new_combat.last_round_time = last_round_time

    # end_info
    assert new_combat.end_info = end_info
    FR3rd_combat.write(combat_id, new_combat)
    return ()
end

# FR3rd_base_update_hero(combat_id,hero_index, health,bear_from_hero,bear_from_boss,damage_to_hero,damage_to_boss,agility_next_hero,damage_to_boss_next_hero)
func FR3rd_base_update_hero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt,
    hero_index : felt,
    health : felt,
    bear_from_hero : felt,
    bear_from_boss : felt,
    damage_to_hero : felt,
    damage_to_boss : felt,
    agility_next_hero : felt,
    damage_to_boss_next_hero : felt,
) -> ():
    alloc_locals
    let (hero) = FR3rd_combat_hero.read(combat_id, hero_index)
    local new_hero : Hero
    assert new_hero.address = hero.address
    # health
    assert new_hero.health = health
    # bear
    assert new_hero.bear_from_hero = bear_from_hero
    assert new_hero.bear_from_boss = bear_from_boss

    # damage
    assert new_hero.damage_to_hero = damage_to_hero
    assert new_hero.damage_to_boss = damage_to_boss

    # agility_next_hero
    assert new_hero.agility_next_hero = agility_next_hero
    # damage_to_boss_next_hero
    assert new_hero.damage_to_boss_next_hero = damage_to_boss_next_hero

    FR3rd_combat_hero.write(combat_id, hero_index, new_hero)
    return ()
end

# FR3rd_base_update_action(combat_id,round_id,hero_index, damage)
func FR3rd_base_update_action{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
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

# call external contracts

func FR3rd_base_get_koma{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, account : felt
) -> (koma : Koma):
    let (contract_address) = FR3rd_combat_1st_address.read()
    let (koma : Koma) = IFirstRelicCombat.getKoma(
        contract_address=contract_address, combat_id=combat_id, account=account
    )
    return (koma=koma)
end

func FR3rd_base_get_prop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, prop_id : felt
) -> (owner : felt, prop : Prop):
    let (contract_address) = FR3rd_combat_1st_address.read()
    let (res) = IFirstRelicCombat.getProp(
        contract_address=contract_address, combat_id=combat_id, prop_id=prop_id
    )
    return (owner=res[0], prop=res[1])
end
