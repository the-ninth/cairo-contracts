%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem

from starkware.cairo.common.bool import TRUE, FALSE

from contracts.pvp.first_relic.constants import (
    PROP_CREATURE_SHIELD,
    PROP_CREATURE_ATTACK_UP_30P,
    PROP_CREATURE_DAMAGE_DOWN_30P,
    PROP_CREATURE_HEALTH_KIT,
)
from contracts.pvp.first_relic.structs import Prop

from contracts.pvp.first_relic.third_stage.base.FR3rdBaseLibrary import FR3rd_base_get_prop
from contracts.pvp.first_relic.third_stage.base.storages import (
    FR3rd_combat_prop_used,
    FR3rd_combat_prop_len,
)

# use prop
func FR3rd_use_prop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, prop_id : felt, address : felt
) -> ():
    alloc_locals
    let (used) = FR3rd_combat_prop_used.read(combat_id, prop_id)
    if used == TRUE:
        return ()
    end
    let (owner, prop) = FR3rd_base_get_prop(combat_id, prop_id)
    if owner != address:
        return ()
    end
    let (len) = FR3rd_combat_prop_len.read(combat_id, address, prop.prop_creature_id)
    if prop.prop_creature_id == PROP_CREATURE_SHIELD:
        FR3rd_combat_prop_len.write(combat_id, address, prop.prop_creature_id, len + 1)
        return ()
    end
    if len != 0:
        FR3rd_combat_prop_len.write(combat_id, address, prop.prop_creature_id, 1)
        return ()
    end
    return ()
end

func FR3rd_prop_atk{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, address : felt, atk : felt
) -> (atk : felt):
    alloc_locals
    let (len) = FR3rd_combat_prop_len.read(combat_id, address, PROP_CREATURE_ATTACK_UP_30P)
    if len == 1:
        FR3rd_combat_prop_len.write(combat_id, address, PROP_CREATURE_ATTACK_UP_30P, 0)
        let (new_atk, r) = unsigned_div_rem(atk * 130, 100)
        return (new_atk)
    end
    return (atk)
end

func FR3rd_prop_damage{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, address : felt, damage : felt
) -> (damage : felt):
    alloc_locals
    let (len) = FR3rd_combat_prop_len.read(combat_id, address, PROP_CREATURE_SHIELD)
    if len != 0:
        FR3rd_combat_prop_len.write(combat_id, address, PROP_CREATURE_SHIELD, len - 1)
        return (0)
    end
    let (len) = FR3rd_combat_prop_len.read(combat_id, address, PROP_CREATURE_DAMAGE_DOWN_30P)
    if len != 0:
        FR3rd_combat_prop_len.write(combat_id, address, PROP_CREATURE_DAMAGE_DOWN_30P, 0)
        let (new_damage, r) = unsigned_div_rem(damage * 70, 100)
        return (new_damage)
    end
    return (damage)
end

func FR3rd_prop_health{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    combat_id : felt, address : felt
) -> (add_health : felt):
    alloc_locals
    let (len) = FR3rd_combat_prop_len.read(combat_id, address, PROP_CREATURE_HEALTH_KIT)
    if len != 0:
        FR3rd_combat_prop_len.write(combat_id, address, PROP_CREATURE_HEALTH_KIT, 0)
        return (20)
    end
    return (0)
end
