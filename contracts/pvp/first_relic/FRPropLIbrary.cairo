%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le_felt, assert_lt_felt, unsigned_div_rem

from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.pvp.first_relic.constants import (
    get_props_pool,
    PROP_CREATURE_SHIELD,
    PROP_TYPE_EQUIPMENT
)
from contracts.pvp.first_relic.structs import (
    Chest,
    Coordinate,
    Prop,
    PropEffect
)
from contracts.pvp.first_relic.storages import (
    chests,
    chest_options,
    FirstRelicCombat_koma_props_len,
    FirstRelicCombat_koma_props_id_by_index,
    FirstRelicCombat_koma_props_effect,
    FirstRelicCombat_koma_props_effect_creature_id_len,
    FirstRelicCombat_koma_props_effect_creature_id_by_index,
    FirstRelicCombat_props,
    FirstRelicCombat_props_counter,
    FirstRelicCombat_props_owner,
    FirstRelicCombat_koma_equipments
)
from contracts.util.math import max
from contracts.util.random import get_random_number_and_seed


func FirstRelicCombat_open_chest{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, target: Coordinate):
    let (chest) = chests.read(combat_id, target)
    with_attr error_message("FirstRelicCombat: invalid chest"):
        assert_not_zero(chest.coordinate.x * chest.coordinate.y)
    end
    with_attr error_message("FirstRelicCombat: chest opened"):
        assert chest.opener = 0
    end

    # write options to storage
    let (props_pool_len, props_pool) = get_props_pool()
    let (block_timestamp) = get_block_timestamp()
    let (index1, _) = get_random_number_and_seed(block_timestamp * account, props_pool_len)
    let (index2, _) = get_random_number_and_seed(block_timestamp * account, props_pool_len)
    let (index3, _) = get_random_number_and_seed(block_timestamp * account, props_pool_len)
    chest_options.write(combat_id, target, 1, props_pool[index1])
    chest_options.write(combat_id, target, 2, props_pool[index2])
    chest_options.write(combat_id, target, 3, props_pool[index3])
    let chest_updated = Chest(coordinate=target, opener=account, option_selected=0)
    chests.write(combat_id, target, chest_updated)

    return ()
end

func FirstRelicCombat_select_chest_option{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, target: Coordinate, option: felt):
    let (chest) = chests.read(combat_id, target)
    with_attr error_message("FirstRelicCombat: invalid chest"):
        assert_not_zero(chest.coordinate.x * chest.coordinate.y)
    end
    with_attr error_message("FirstRelicCombat: not your chest"):
        assert chest.opener = account
    end
    with_attr error_message("FirstRelicCombat: chest option selected"):
        assert chest.option_selected = 0
    end

    let chest_updated = Chest(chest.coordinate, chest.opener, option)
    let (selected_prop_creature_id) = chest_options.read(combat_id, target, option)
    with_attr error_message("FirstRelicCombat: invalid chest option"):
        assert_lt_felt(0, selected_prop_creature_id)
    end
    let (props_count) = FirstRelicCombat_props_counter.read(combat_id)
    let prop_id = props_count + 1
    let (len) = FirstRelicCombat_koma_props_len.read(combat_id, account)
    let prop = Prop(prop_id=prop_id, prop_creature_id=selected_prop_creature_id, used_timetamp=0, index_in_koma_props=len)
    FirstRelicCombat_props.write(combat_id, prop_id, prop)
    FirstRelicCombat_props_owner.write(combat_id, prop_id, account)
    FirstRelicCombat_koma_props_id_by_index.write(combat_id, account, len, prop_id)
    FirstRelicCombat_props_counter.write(combat_id, prop_id)
    FirstRelicCombat_koma_props_len.write(combat_id, account, len + 1)
    
    return ()
end

func FirstRelicCombat_get_koma_props{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt) -> (data_len: felt, data: Prop*):
    alloc_locals

    let (len) = FirstRelicCombat_koma_props_len.read(combat_id, account)
    let (local data: Prop*) = alloc()
    _get_koma_props(combat_id, account, 0, len, data)

    return (len, data)
end

# recursively get props array 
func _get_koma_props{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, index: felt, data_len: felt, data: Prop*):
    if data_len == 0:
        return ()
    end

    let (prop_id) = FirstRelicCombat_koma_props_id_by_index.read(combat_id, account, index)
    let (prop) = FirstRelicCombat_props.read(combat_id, prop_id)
    assert data[index] = prop
    _get_koma_props(combat_id, account, index+1, data_len-1, data)

    return ()
end

func FirstRelicCombat_use_prop{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, prop_id: felt):
    alloc_locals

    let (prop) = FirstRelicCombat_props.read(combat_id, prop_id)
    with_attr error_message("FirstRelicCombat: prop invalid"):
        assert_not_zero(prop.prop_creature_id)
    end
    let (prop_owner) = FirstRelicCombat_props_owner.read(combat_id, prop_id)
    with_attr error_message("FirstRelicCombat: prop not owned"):
        assert account = prop_owner
    end
    with_attr error_message("FirstRelicCombat: prop not owned"):
        assert prop.used_timetamp = 0
    end

    let (block_timestamp) = get_block_timestamp()
    let prop_updated = Prop(prop.prop_id, prop.prop_creature_id, block_timestamp, 0)
    FirstRelicCombat_props.write(combat_id, prop_id, prop_updated)
    let (props_len) = FirstRelicCombat_koma_props_len.read(combat_id, account)
    if props_len == 1:
        FirstRelicCombat_koma_props_len.write(combat_id, account, 0)
    else:
        let (last_prop_id) = FirstRelicCombat_koma_props_id_by_index.read(combat_id, account, props_len - 1)
        FirstRelicCombat_koma_props_id_by_index.write(combat_id, account, prop.index_in_koma_props, last_prop_id)
        FirstRelicCombat_koma_props_len.write(combat_id, account, props_len - 1)
    end

    if prop.prop_creature_id == PROP_CREATURE_SHIELD:
        _prop_effect_use(combat_id, account, PROP_CREATURE_SHIELD)
        return ()
    end

    if prop.prop_creature_id == PROP_CREATURE_HEALTH_KIT:
        
    end

    with_attr error_message("FirstRelicCombat: prop is unuseable"):
        assert 0 = 1
    end

    return ()
end

# func _use_prop_shield{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }(combat_id: felt, account: felt):
#     alloc_locals

#     let (prop_effect) = FirstRelicCombat_koma_props_effect.read(combat_id, account, PROP_CREATURE_SHIELD)
#     let (len) = FirstRelicCombat_koma_props_effect_creature_id_len.read(combat_id, account)
#     let (index) = max(prop_effect.index_in_koma_effects, len)
#     let (block_timestamp) = get_block_timestamp()
#     local new_len
#     if prop_effect.prop_creature_id == 0:
#         new_len = len + 1
#     else:
#         new_len = len
#     end
#     let prop_effect_updated = PropEffect(
#         prop_creature_id=PROP_CREATURE_SHIELD,
#         index_in_koma_effects=index,
#         used_timetamp=block_timestamp
#     )
#     FirstRelicCombat_koma_props_effect.write(combat_id, account, PROP_CREATURE_SHIELD, )
#     FirstRelicCombat_koma_props_effect_creature_id_len.write(combat_id, account, new_len)
#     FirstRelicCombat_koma_props_effect_creature_id_by_index(combat_id, account, index, PROP_CREATURE_SHIELD)
# end

# for useable and have consistent effect props
func _prop_effect_use{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, prop_creature_id: felt):
    alloc_locals

    let (prop_effect) = FirstRelicCombat_koma_props_effect.read(combat_id, account, prop_creature_id)
    let (len) = FirstRelicCombat_koma_props_effect_creature_id_len.read(combat_id, account)
    let (index) = max(prop_effect.index_in_koma_effects, len)
    let (block_timestamp) = get_block_timestamp()
    local new_len
    if prop_effect.prop_creature_id == 0:
        new_len = len + 1
    else:
        new_len = len
    end
    let prop_effect_updated = PropEffect(
        prop_creature_id=prop_creature_id,
        index_in_koma_effects=index,
        used_timetamp=block_timestamp
    )
    FirstRelicCombat_koma_props_effect.write(combat_id, account, prop_creature_id, prop_effect_updated)
    FirstRelicCombat_koma_props_effect_creature_id_len.write(combat_id, account, new_len)
    FirstRelicCombat_koma_props_effect_creature_id_by_index.write(combat_id, account, index, prop_creature_id)

    return ()
end

func FirstRelicCombat_equip_prop{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, prop_id: felt):
    alloc_locals

    let (prop) = FirstRelicCombat_props.read(combat_id, prop_id)
    let (equip_part) = _get_equip_part(prop.prop_creature_id)
    with_attr error_message("FirstRelicCombat: prop invalid"):
        assert_not_zero(prop.prop_creature_id)
    end
    let (prop_owner) = FirstRelicCombat_props_owner.read(combat_id, prop_id)
    with_attr error_message("FirstRelicCombat: prop not owned"):
        assert account = prop_owner
    end
    with_attr error_message("FirstRelicCombat: prop used"):
        assert prop.used_timetamp = 0
    end

    let (block_timestamp) = get_block_timestamp()
    let prop_updated = Prop(prop.prop_id, prop.prop_creature_id, block_timestamp, 0)
    FirstRelicCombat_props.write(combat_id, prop_id, prop_updated)
    let (props_len) = FirstRelicCombat_koma_props_len.read(combat_id, account)
    if props_len == 1:
        FirstRelicCombat_koma_props_len.write(combat_id, account, 0)
    else:
        let (last_prop_id) = FirstRelicCombat_koma_props_id_by_index.read(combat_id, account, props_len - 1)
        FirstRelicCombat_koma_props_id_by_index.write(combat_id, account, prop.index_in_koma_props, last_prop_id)
        FirstRelicCombat_koma_props_len.write(combat_id, account, props_len - 1)
    end

    let (equiped_prop_id) = FirstRelicCombat_koma_equipments.read(combat_id, account, equip_part)
    if equiped_prop_id != 0:
        # put into prop bag
        let (equiped_prop) = FirstRelicCombat_props.read(combat_id, equiped_prop_id)
        let (props_len) = FirstRelicCombat_koma_props_len.read(combat_id, account)
        let equiped_prop_updated = Prop(equiped_prop.prop_id, equiped_prop.prop_creature_id, 0, props_len)
        FirstRelicCombat_props.write(combat_id, equiped_prop.prop_id, equiped_prop_updated)
        FirstRelicCombat_koma_props_len.write(combat_id, account, props_len + 1)
    else:
        FirstRelicCombat_koma_equipments.write(combat_id, account, equip_part, prop_id)
    end

    return ()
end

func _get_equip_part{
        # syscall_ptr : felt*, 
        # pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(prop_creature_id: felt) -> (equip_part: felt):
    let (prop_type, r) = unsigned_div_rem(prop_creature_id, 10**8)
    with_attr error_message("FirstRelicCombat: prop is not a equipment"):
        assert prop_type = PROP_TYPE_EQUIPMENT
    end
    let (equip_part, _) = unsigned_div_rem(r, 10**7)
    with_attr error_message("FirstRelicCombat: equipment part invalid"):
        assert_le_felt(1, equip_part)
        assert_le_felt(equip_part, 4)
    end

    return (equip_part)
end