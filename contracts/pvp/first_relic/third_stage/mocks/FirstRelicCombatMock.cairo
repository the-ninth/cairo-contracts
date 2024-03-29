%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from contracts.pvp.first_relic.structs import Koma, Prop, Coordinate, Combat
from contracts.pvp.first_relic.third_stage.base.FR3rdBaseLibrary import FR3rd_base_random

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_block_timestamp,
)
from contracts.util.random import get_random_number

from contracts.pvp.first_relic.constants import (
    PROP_CREATURE_SHIELD,
    PROP_CREATURE_ATTACK_UP_30P,
    PROP_CREATURE_DAMAGE_DOWN_30P,
    PROP_CREATURE_HEALTH_KIT,
)

@storage_var
func FR3rd_mock_props(combat_id: felt, prop_id: felt) -> (res: (address: felt, prop: Prop)) {
}
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    return ();
}

@view
func demo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt, number: felt, timestamp: felt
) {
    let (address) = get_caller_address();
    let (number) = get_block_number();
    let (timestamp) = get_block_timestamp();
    return (address, number, timestamp);
}

@view
func getKoma{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) -> (koma: Koma) {
    let (agility) = get_random_number(account, 1, 200);
    let (atk) = get_random_number(account, 1, 150);
    let (defense) = get_random_number(account, 1, 150);
    let coo = Coordinate(0, 0);
    let koma = Koma(
        account, coo, 0, 1000, 1000, agility, 0, 0, 0, 0, 0, 6, 0, 0, 0, atk + 1, defense + 1, 0
    );
    return (koma,);
}

@view
func getProp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, prop_id: felt
) -> (res: (felt, Prop)) {
    let (res) = FR3rd_mock_props.read(combat_id, prop_id);
    return (res,);
}

@external
func mintProp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, hero_index: felt
) -> () {
    mintItem(combat_id, account, PROP_CREATURE_SHIELD, hero_index, 0);
    mintItem(combat_id, account, PROP_CREATURE_SHIELD, hero_index, 1);
    mintItem(combat_id, account, PROP_CREATURE_SHIELD, hero_index, 2);

    mintItem(combat_id, account, PROP_CREATURE_ATTACK_UP_30P, hero_index, 0);
    mintItem(combat_id, account, PROP_CREATURE_ATTACK_UP_30P, hero_index, 1);
    mintItem(combat_id, account, PROP_CREATURE_ATTACK_UP_30P, hero_index, 2);

    mintItem(combat_id, account, PROP_CREATURE_DAMAGE_DOWN_30P, hero_index, 0);
    mintItem(combat_id, account, PROP_CREATURE_DAMAGE_DOWN_30P, hero_index, 1);
    mintItem(combat_id, account, PROP_CREATURE_DAMAGE_DOWN_30P, hero_index, 2);

    mintItem(combat_id, account, PROP_CREATURE_HEALTH_KIT, hero_index, 0);
    mintItem(combat_id, account, PROP_CREATURE_HEALTH_KIT, hero_index, 1);
    mintItem(combat_id, account, PROP_CREATURE_HEALTH_KIT, hero_index, 2);

    return ();
}

func mintItem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, type: felt, hero_index: felt, index: felt
) -> () {
    let prop_id = type * 1000 + (hero_index * 100) + index;
    FR3rd_mock_props.write(combat_id, prop_id, (account, Prop(prop_id, type, 0, 0)));
    return ();
}

@view
func getCombat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt
) -> (combat: Combat) {
    alloc_locals;
    let (timestamp) = get_block_timestamp();
    local combat: Combat;
    assert combat.prepare_time = 0;
    assert combat.first_stage_time = 0;
    assert combat.second_stage_time = 0;
    assert combat.third_stage_time = timestamp;
    assert combat.end_time = 0;
    assert combat.expire_time = 0;
    assert combat.status = 0;
    return (combat,);
}
