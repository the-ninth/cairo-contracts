%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.uint256 import Uint256

from starkware.starknet.common.syscalls import get_caller_address

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import (
    ROLE_FRCOMBAT_CREATOR,
    RANDOM_PRODUCER_CONTRACT,
    DELEGATE_ACCOUNT_REGISTRY_CONTRACT,
)

from contracts.delegate_account.interfaces.IDelegateAccountRegistry import IDelegateAccountRegistry
from contracts.delegate_account.actions import (
    ACTION_FR_COMBAT_MOVE,
    ACTION_FR_COMBAT_MINE_ORE,
    ACTION_FR_COMBAT_RECALL_WORKERS,
    ACTION_FR_COMBAT_PRODUCE_BOT,
    ACTION_FR_COMBAT_ATTACK,
    ACTION_FR_COMBAT_CHEST,
    ACTION_FR_COMBAT_USE_PROP,
    ACTION_FR_COMBAT_ENTER_GATE,
)

from contracts.random.IRandomProducer import IRandomProducer

from contracts.pvp.first_relic.constants import MAX_PLAYERS, CHEST_PER_PLAYER, ORE_PER_PLAYER
from contracts.pvp.first_relic.structs import (
    Combat,
    Chest,
    Coordinate,
    Koma,
    KomaEquipments,
    Movment,
    Ore,
    Prop,
    RelicGate,
    KOMA_STATUS_DEAD,
    KOMA_STATUS_MINING,
    KOMA_STATUS_THIRD_STAGE,
)
from contracts.pvp.first_relic.storages import (
    FirstRelicCombat_komas,
    FirstRelicCombat_access_contract,
)
from contracts.pvp.first_relic.FRCombatLibrary import (
    FirstRelicCombat_init_chests,
    FirstRelicCombat_in_moving_stage,
    FirstRelicCombat_init_ores,
    FirstRelicCombat_new_combat,
    FirstRelicCombat_get_combat,
    FirstRelicCombat_get_combat_count,
    FirstRelicCombat_get_chest_count,
    FirstRelicCombat_get_chests,
    FirstRelicCombat_get_chest_by_coordinate,
    FirstRelicCombat_prepare_combat,
    FirstRelicCombat_attack,
    FirstRelicCombat_get_relic_gate,
    FirstRelicCombat_get_relic_gates,
    FirstRelicCombat_enter_relic_gate,
)
from contracts.pvp.first_relic.FRPlayerLibrary import (
    FirstRelicCombat_init_player,
    FirstRelicCombat_get_players_count,
    FirstRelicCombat_get_players,
    FirstRelicCombat_get_koma,
    FirstRelicCombat_get_komas,
    FirstRelicCombat_get_komas_movments,
    FirstRelicCombat_move,
)
from contracts.pvp.first_relic.FRPropLibrary import (
    FirstRelicCombat_open_chest,
    FirstRelicCombat_select_chest_option,
    FirstRelicCombat_get_chest_options,
    FirstRelicCombat_get_koma_equipments,
    FirstRelicCombat_get_koma_props,
    FirstRelicCombat_use_prop,
    FirstRelicCombat_equip_prop,
    FirstRelicCombat_get_koma_prop_effect_creature_ids,
)
from contracts.pvp.first_relic.FROreLibrary import OreLibrary
from contracts.pvp.first_relic.FRManageLibrary import ManageLibrary
from contracts.pvp.first_relic.FRLazyUpdate import (
    LazyUpdate_update_combat_status,
    LazyUpdate_update_ore,
)
from contracts.pvp.first_relic.IFirstRelicCombat import PlayerDeath
from contracts.pvp.first_relic.third_stage.interfaces.IFR3rd import IFR3rd

const RANDOM_TYPE_COMBAT_INIT = 1;

@storage_var
func random_request_type(request_id: felt) -> (type: felt) {
}

@storage_var
func random_request_combat_init(request_id: felt) -> (combat_id: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    access_contract_: felt
) {
    FirstRelicCombat_access_contract.write(access_contract_);
    return ();
}

@view
func getCombatCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    count: felt
) {
    let (count) = FirstRelicCombat_get_combat_count();
    return (count,);
}

@view
func getCombat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt
) -> (combat: Combat) {
    let (combat) = FirstRelicCombat_get_combat(combat_id);
    return (combat,);
}

@view
func getChestCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt
) -> (count: felt) {
    let (count) = FirstRelicCombat_get_chest_count(combat_id);
    return (count,);
}

@view
func getChests{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, offset: felt, length: felt
) -> (data_len: felt, data: Chest*) {
    let (data_len, data) = FirstRelicCombat_get_chests(combat_id, offset, length);
    return (data_len, data);
}

@view
func getChestByCoordinate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, coordinate: Coordinate
) -> (chest: Chest) {
    let (chest) = FirstRelicCombat_get_chest_by_coordinate(combat_id, coordinate);
    return (chest,);
}

@view
func getChestOptions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, coordinate: Coordinate
) -> (options_len: felt, options: felt*) {
    return FirstRelicCombat_get_chest_options(combat_id, coordinate);
}

@view
func getOreCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt
) -> (count: felt) {
    let (count) = OreLibrary.get_ore_count(combat_id);
    return (count,);
}

@view
func getOres{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, offset: felt, length: felt
) -> (ores_len: felt, ores: Ore*) {
    let (ores_len, ores) = OreLibrary.get_ores(combat_id, offset, length);
    return (ores_len, ores);
}

@view
func getOreByCoordinate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, coordinate: Coordinate
) -> (ore: Ore) {
    let (ore) = OreLibrary.get_ore_by_coordinate(combat_id, coordinate);
    return (ore,);
}

@view
func getPlayersCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt
) -> (count: felt) {
    let (count) = FirstRelicCombat_get_players_count(combat_id);
    return (count,);
}

@view
func getPlayers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, offset: felt, length: felt
) -> (players_len: felt, players: felt*) {
    let (players_len, players) = FirstRelicCombat_get_players(combat_id, offset, length);
    return (players_len, players);
}

@view
func getKoma{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) -> (koma: Koma) {
    let (koma) = FirstRelicCombat_get_koma(combat_id, account);
    return (koma,);
}

@view
func getKomas{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, accounts_len: felt, accounts: felt*
) -> (komas_len: felt, komas: Koma*) {
    let (komas_len, komas) = FirstRelicCombat_get_komas(combat_id, accounts_len, accounts);
    return (komas_len, komas);
}

@view
func getKomasMovments{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, accounts_len: felt, accounts: felt*
) -> (movments_len: felt, movments: Movment*) {
    let (movments_len, movments) = FirstRelicCombat_get_komas_movments(
        combat_id, accounts_len, accounts
    );
    return (movments_len, movments);
}

@view
func getKomaProps{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) -> (koma_props_len: felt, koma_props: Prop*) {
    let (koma_props_len, koma_props) = FirstRelicCombat_get_koma_props(combat_id, account);
    return (koma_props_len, koma_props);
}

@view
func getKomaEquipments{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) -> (equipments: KomaEquipments) {
    return FirstRelicCombat_get_koma_equipments(combat_id, account);
}

@view
func getKomaPropEffectCreatureIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) -> (creature_ids_len: felt, creature_ids: felt*) {
    let (creature_ids_len, creature_ids) = FirstRelicCombat_get_koma_prop_effect_creature_ids(
        combat_id, account
    );
    return (creature_ids_len, creature_ids);
}

@view
func getRelicGate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, number: felt
) -> (relic_gate: RelicGate) {
    return FirstRelicCombat_get_relic_gate(combat_id, number);
}

@view
func getRelicGates{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt
) -> (relic_gates_len: felt, relic_gates: RelicGate*) {
    let (relic_gates_len, relic_gates) = FirstRelicCombat_get_relic_gates(combat_id);

    return (relic_gates_len, relic_gates);
}

@view
func getAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, offset: felt, length: felt
) -> (komas_len: felt, komas: Koma*, chests_len: felt, chests: Chest*, ores_len: felt, ores: Ore*) {
    alloc_locals;

    let (ores_len, ores) = OreLibrary.get_ores(combat_id, offset, length);
    let (chests_len, chests) = FirstRelicCombat_get_chests(combat_id, offset, length);
    let (accounts_len, accounts) = FirstRelicCombat_get_players(combat_id, offset, length);
    let (komas_len, komas) = FirstRelicCombat_get_komas(combat_id, accounts_len, accounts);

    return (komas_len, komas, chests_len, chests, ores_len, ores);
}

@view
func getCombatAccountKomaId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) -> (koma_token_id: Uint256) {
    let (koma_token_id) = ManageLibrary.get_combat_account_koma_token(combat_id, account);
    return (koma_token_id,);
}

@external
func newCombat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(combat_id) -> () {
    let (access_contract_address) = FirstRelicCombat_access_contract.read();
    let (caller) = get_caller_address();
    IAccessControl.onlyRole(access_contract_address, ROLE_FRCOMBAT_CREATOR, caller);
    FirstRelicCombat_new_combat(combat_id);
    return ();
}

@external
func register{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, koma_token_id: Uint256
) -> () {
    alloc_locals;

    let (account) = get_caller_address();
    ManageLibrary.register(combat_id, account, koma_token_id);
    let (next_seed) = FirstRelicCombat_init_player(combat_id, account);
    // generate chests and ores
    let (next_seed) = FirstRelicCombat_init_chests(combat_id, CHEST_PER_PLAYER, next_seed);
    FirstRelicCombat_init_ores(combat_id, ORE_PER_PLAYER, next_seed);
    // ready to launch
    let (count) = FirstRelicCombat_get_players_count(combat_id);
    if (count == MAX_PLAYERS) {
        FirstRelicCombat_prepare_combat(combat_id);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return ();
}

@external
func move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, to: Coordinate
) {
    authorized_call(account, ACTION_FR_COMBAT_MOVE);
    LazyUpdate_update_combat_status(combat_id);
    player_can_move(combat_id, account);

    FirstRelicCombat_move(combat_id, account, to);

    return ();
}

@external
func mineOre{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, target: Coordinate, workers_count: felt
) {
    authorized_call(account, ACTION_FR_COMBAT_MINE_ORE);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);
    LazyUpdate_update_ore(combat_id, target);

    OreLibrary.mine_ore(combat_id, account, target, workers_count);

    return ();
}

@external
func recallWorkers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, target: Coordinate, workers_count: felt
) {
    authorized_call(account, ACTION_FR_COMBAT_RECALL_WORKERS);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);
    LazyUpdate_update_ore(combat_id, target);

    OreLibrary.recall_workers(combat_id, account, target, workers_count);
    return ();
}

@external
func produceBot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, bot_type: felt, quantity: felt
) {
    authorized_call(account, ACTION_FR_COMBAT_PRODUCE_BOT);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);

    OreLibrary.produce_bot(combat_id, account, bot_type, quantity);

    return ();
}

@external
func collectOre{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, target: Coordinate
) {
    alloc_locals;

    authorized_call(account, ACTION_FR_COMBAT_MINE_ORE);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);

    OreLibrary.collect_ore(combat_id, account, target);
    return ();
}

@external
func attackOre{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, target: Coordinate
) {
    alloc_locals;

    authorized_call(account, ACTION_FR_COMBAT_MINE_ORE);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);

    OreLibrary.attack_ore(combat_id, account, target);
    return ();
}

@external
func attack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, target_account: felt
) {
    alloc_locals;

    authorized_call(account, ACTION_FR_COMBAT_ATTACK);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);

    let (koma_attacked_status) = FirstRelicCombat_attack(combat_id, account, target_account);
    if (koma_attacked_status == KOMA_STATUS_DEAD) {
        OreLibrary.clear_koma_ores(combat_id, target_account);
        PlayerDeath.emit(combat_id, target_account);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return ();
}

@external
func openChest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, target: Coordinate
) {
    authorized_call(account, ACTION_FR_COMBAT_CHEST);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);

    FirstRelicCombat_open_chest(combat_id, account, target);

    return ();
}

@external
func selectChestOption{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, target: Coordinate, option: felt
) {
    authorized_call(account, ACTION_FR_COMBAT_CHEST);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);

    FirstRelicCombat_select_chest_option(combat_id, account, target, option);

    return ();
}

@external
func useProp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, prop_id: felt
) {
    authorized_call(account, ACTION_FR_COMBAT_USE_PROP);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);

    FirstRelicCombat_use_prop(combat_id, account, prop_id);

    return ();
}

@external
func equipProp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt, prop_id: felt
) {
    authorized_call(account, ACTION_FR_COMBAT_USE_PROP);
    LazyUpdate_update_combat_status(combat_id);
    player_can_action(combat_id, account);

    FirstRelicCombat_equip_prop(combat_id, account, prop_id);

    return ();
}

@external
func fulfillRandom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    request_id: felt, random: felt
) {
    let (caller) = get_caller_address();
    let (access_contract_address) = FirstRelicCombat_access_contract.read();
    let (producer_address) = IAccessControl.getContractAddress(
        contract_address=access_contract_address, contract_name=RANDOM_PRODUCER_CONTRACT
    );

    with_attr error_message("FirstRelicCombat: random fulfill invalid producer") {
        assert caller = producer_address;
    }

    let (type) = random_request_type.read(request_id);
    with_attr error_message("FirstRelicCombat: random request type missed") {
        assert_not_zero(type);
    }

    return ();
}

//
// Modifiers
//

func authorized_call{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, action: felt
) {
    let (caller) = get_caller_address();
    if (caller == account) {
        return ();
    }

    let (access_contract_address) = FirstRelicCombat_access_contract.read();
    let (delegate_registry_contract_address) = IAccessControl.getContractAddress(
        contract_address=access_contract_address, contract_name=DELEGATE_ACCOUNT_REGISTRY_CONTRACT
    );
    let (res) = IDelegateAccountRegistry.authorized(
        contract_address=delegate_registry_contract_address,
        account=account,
        delegate_account=caller,
        action=action,
    );
    with_attr error_message("FirstRelicCombat: unauthorized call") {
        assert res = TRUE;
    }

    return ();
}

// actions include move, attack, open chest
func player_can_move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) {
    alloc_locals;

    let (koma) = FirstRelicCombat_komas.read(combat_id, account);
    let (in_moving_stage) = FirstRelicCombat_in_moving_stage(combat_id);
    with_attr error_message("FirstRelicCombat: combat status invalid") {
        assert in_moving_stage = TRUE;
    }

    with_attr error_message("FirstRelicCombat: player not exist") {
        assert_not_zero(koma.status);
    }

    with_attr error_message("FirstRelicCombat: player is dead") {
        assert_not_equal(koma.status, KOMA_STATUS_DEAD);
    }

    with_attr error_message("FirstRelicCombat: player is mining") {
        assert_not_equal(koma.status, KOMA_STATUS_MINING);
    }

    return ();
}

// actions include mine, recall, produce bot
func player_can_action{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt, account: felt
) {
    alloc_locals;

    let (koma) = FirstRelicCombat_komas.read(combat_id, account);
    let (in_moving_stage) = FirstRelicCombat_in_moving_stage(combat_id);
    with_attr error_message("FirstRelicCombat: combat status invalid") {
        assert in_moving_stage = TRUE;
    }

    with_attr error_message("FirstRelicCombat: player not exist") {
        assert_not_zero(koma.status);
    }

    with_attr error_message("FirstRelicCombat: player in third stage") {
        assert_not_equal(koma.status, KOMA_STATUS_THIRD_STAGE);
    }

    with_attr error_message("FirstRelicCombat: player is dead") {
        assert_not_equal(koma.status, KOMA_STATUS_DEAD);
    }

    return ();
}
