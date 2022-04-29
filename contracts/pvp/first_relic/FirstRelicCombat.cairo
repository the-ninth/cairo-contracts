%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal

from starkware.starknet.common.syscalls import get_caller_address

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import ROLE_FRCOMBAT_CREATOR

from contracts.delegate_account.interfaces.IDelegateAccountRegistry import IDelegateAccountRegistry
from contracts.delegate_account.actions import (
    ACTION_FR_COMBAT_MOVE,
    ACTION_FR_COMBAT_MINE_ORE,
    ACTION_FR_COMBAT_RECALL_WORKERS,
    ACTION_FR_COMBAT_PRODUCE_BOT,
    ACTION_FR_COMBAT_ATTACK
)

from contracts.random.IRandomProducer import IRandomProducer

from contracts.pvp.first_relic.constants import MAX_PLAYERS, CHEST_PER_PLAYER, ORE_PER_PLAYER
from contracts.pvp.first_relic.structs import (
    Combat,
    Chest,
    Coordinate,
    Koma,
    KomaMiningOre,
    Movment,
    Ore,
    KOMA_STATUS_DEAD,
    KOMA_STATUS_MINING
)
from contracts.pvp.first_relic.storages import komas
from contracts.pvp.first_relic.FRCombatLibrary import (
    FirstRelicCombat_init_chests,
    FirstRelicCombat_in_moving_stage,
    FirstRelicCombat_init_ores,
    FirstRelicCombat_mine_ore,
    FirstRelicCombat_new_combat,
    FirstRelicCombat_get_combat,
    FirstRelicCombat_get_combat_count,
    FirstRelicCombat_get_chest_count,
    FirstRelicCombat_get_chests,
    FirstRelicCombat_get_chest_by_coordinate,
    FirstRelicCombat_get_koma_mining_ores,
    FirstRelicCombat_get_ore_count,
    FirstRelicCombat_get_ores,
    FirstRelicCombat_get_ore_by_coordinate,
    FirstRelicCombat_prepare_combat,
    FirstRelicCombat_recall_workers,
    FirstRelicCombat_produce_bot,
    FirstRelicCombat_attack,
    FirstRelicCombat_clear_mining_ores
)
from contracts.pvp.first_relic.FRPlayerLibrary import(
    FirstRelicCombat_init_player,
    FirstRelicCombat_get_players_count,
    FirstRelicCombat_get_players,
    FirstRelicCombat_get_koma,
    FirstRelicCombat_get_komas,
    FirstRelicCombat_get_komas_movments,
    FirstRelicCombat_move
)
from contracts.pvp.first_relic.FRLazyUpdate import LazyUpdate_update_combat_status, LazyUpdate_update_ore, LazyUpdate_update_koma_mining


const RANDOM_TYPE_COMBAT_INIT = 1

@storage_var
func access_contract() -> (access_contract: felt):
end

@storage_var
func random_request_type(request_id: felt) -> (type: felt):
end

@storage_var
func random_request_combat_init(request_id: felt) -> (combat_id: felt):
end

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        access_contract_: felt
    ):
    access_contract.write(access_contract_)
    return ()
end

@view
func getCombatCount{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (count: felt):
    let (count) = FirstRelicCombat_get_combat_count()
    return (count)
end

@view
func getCombat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (combat: Combat):
    let (combat) = FirstRelicCombat_get_combat(combat_id)
    return (combat)
end

@view
func getChestCount{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (count: felt):
    let (count) = FirstRelicCombat_get_chest_count(combat_id)
    return (count)
end

@view
func getChests{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, offset: felt, length: felt) -> (data_len: felt, data: Chest*):
    let (data_len, data) = FirstRelicCombat_get_chests(combat_id, offset, length)
    return (data_len, data)
end

@view
func getChestByCoordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, coordinate: Coordinate) -> (chest: Chest):
    let (chest) = FirstRelicCombat_get_chest_by_coordinate(combat_id, coordinate)
    return (chest)
end

@view
func getOreCount{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (count: felt):
    let (count) = FirstRelicCombat_get_ore_count(combat_id)
    return (count)
end

@view
func getOres{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, offset: felt, length: felt) -> (ores_len: felt, ores: Ore*):
    let (ores_len, ores) = FirstRelicCombat_get_ores(combat_id, offset, length)
    return (ores_len, ores)
end

@view
func getOreByCoordinate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, coordinate: Coordinate) -> (ore: Ore):
    let (ore) = FirstRelicCombat_get_ore_by_coordinate(combat_id, coordinate)
    return (ore)
end

@view
func getPlayersCount{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt) -> (count: felt):
    let (count) = FirstRelicCombat_get_players_count(combat_id)
    return (count)
end

@view
func getPlayers{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, offset: felt, length: felt) -> (players_len: felt, players: felt*):
    let (players_len, players) = FirstRelicCombat_get_players(combat_id, offset, length)
    return (players_len, players)
end

@view
func getKoma{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt) -> (koma: Koma):
    let (koma) = FirstRelicCombat_get_koma(combat_id, account)
    return (koma)
end

@view
func getKomas{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, accounts_len: felt, accounts: felt*) -> (komas_len: felt, komas: Koma*):
    let (komas_len, komas) = FirstRelicCombat_get_komas(combat_id, accounts_len, accounts)
    return (komas_len, komas)
end

@view
func getKomasMovments{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, accounts_len: felt, accounts: felt*) -> (movments_len: felt, movments: Movment*):
    let (movments_len, movments) = FirstRelicCombat_get_komas_movments(combat_id, accounts_len, accounts)
    return (movments_len, movments)
end

@view
func getKomaMiningOres{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt) -> (mining_ores_len: felt, mining_ores: KomaMiningOre*):
    let (mining_ores_len, mining_ores) = FirstRelicCombat_get_koma_mining_ores(combat_id, account)
    return (mining_ores_len, mining_ores)
end

@external
func initPlayer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt):
    alloc_locals

    # only register contract could call
    let (access_contract_address) = access_contract.read()
    let (caller) = get_caller_address()
    let (register_contract_address) = IAccessControl.frCombatRegisterContract(contract_address=access_contract_address)
    assert_not_zero(caller)
    assert caller = register_contract_address

    let (next_seed) = FirstRelicCombat_init_player(combat_id, account)
    # generate chests and ores
    let (next_seed) = FirstRelicCombat_init_chests(combat_id, CHEST_PER_PLAYER, next_seed)
    FirstRelicCombat_init_ores(combat_id, ORE_PER_PLAYER, next_seed)

    # ready to launch
    let (count) = FirstRelicCombat_get_players_count(combat_id)
    if count == MAX_PLAYERS:
        FirstRelicCombat_prepare_combat(combat_id)
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

@external
func newCombat{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (combat_id: felt):
    let (access_contract_address) = access_contract.read()
    let (caller) = get_caller_address()
    IAccessControl.onlyRole(access_contract_address, ROLE_FRCOMBAT_CREATOR, caller)
    let (combat_id) = FirstRelicCombat_new_combat()
    
    # random request deprecated
    # let (producer_address) = IAccessControl.randomProducerContract(contract_address=access_contract_address)
    # let (request_id) = IRandomProducer.requestRandom(contract_address=producer_address)
    # random_request_type.write(request_id, RANDOM_TYPE_COMBAT_INIT)
    # random_request_combat_init.write(request_id, combat_id)
    # # trigger random fulfill, this should be removed after switch to random oracle
    # IRandomProducer.triggerFulfill(producer_address, request_id)

    return (combat_id)
end

@external
func move{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, to: Coordinate):
    authorized_call(account, ACTION_FR_COMBAT_MOVE)
    LazyUpdate_update_combat_status(combat_id)
    player_can_move(combat_id, account)

    FirstRelicCombat_move(combat_id, account, to)

    return ()
end

@external
func mineOre{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, target: Coordinate, workers_count: felt):
    authorized_call(account, ACTION_FR_COMBAT_MINE_ORE)
    LazyUpdate_update_combat_status(combat_id)
    player_can_action_ores(combat_id, account)
    LazyUpdate_update_ore(combat_id, target)

    FirstRelicCombat_mine_ore(combat_id, account, target, workers_count)

    return()
end

@external
func recallWorkers{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, target: Coordinate, workers_count: felt):
    authorized_call(account, ACTION_FR_COMBAT_RECALL_WORKERS)
    LazyUpdate_update_combat_status(combat_id)
    player_can_action_ores(combat_id, account)
    LazyUpdate_update_ore(combat_id, target)

    FirstRelicCombat_recall_workers(combat_id, account, target, workers_count)

    return ()
end

@external
func produceBot{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, bot_type: felt, quantity: felt):
    authorized_call(account, ACTION_FR_COMBAT_PRODUCE_BOT)
    LazyUpdate_update_combat_status(combat_id)
    player_can_action_ores(combat_id, account)
    LazyUpdate_update_koma_mining(combat_id, account)

    FirstRelicCombat_produce_bot(combat_id, account, bot_type, quantity)

    return ()
end

@external
func attack{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt, target_account: felt):
    alloc_locals

    authorized_call(account, ACTION_FR_COMBAT_ATTACK)
    LazyUpdate_update_combat_status(combat_id)
    player_can_move(combat_id, account)

    let (koma_attacked_status) = FirstRelicCombat_attack(combat_id, account, target_account)
    if koma_attacked_status == KOMA_STATUS_DEAD:
        FirstRelicCombat_clear_mining_ores(combat_id, target_account)
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

@external
func fulfillRandom{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(request_id: felt, random: felt):
    let (caller) = get_caller_address()
    let (access_contract_address) = access_contract.read()
    let (producer_address) = IAccessControl.randomProducerContract(contract_address=access_contract_address)

    with_attr error_message("FirstRelicCombat: random fulfill invalid producer"):
        assert caller = producer_address
    end
    let (type) = random_request_type.read(request_id)
    with_attr error_message("FirstRelicCombat: random request type missed"):
        assert_not_zero(type)
    end

    return ()

end

#
# Modifiers
#

func authorized_call{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt, action: felt):
    let (caller) = get_caller_address()
    if caller == account:
        return ()
    end

    let (access_contract_address) = access_contract.read()
    let (delegate_registry_contract_address) = IAccessControl.delegateAccountRegistryContract(contract_address=access_contract_address)
    let (res) = IDelegateAccountRegistry.authorized(contract_address=delegate_registry_contract_address, account=account, delegate_account=caller, action=action)
    with_attr error_message("FirstRelicCombat: unauthorized call"):
        assert res = TRUE
    end

    return()
end

# actions include move, attack
func player_can_move{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt):
    alloc_locals

    let (koma) = komas.read(combat_id, account)
    let (in_moving_stage) = FirstRelicCombat_in_moving_stage(combat_id)
    with_attr error_message("FirstRelicCombat: combat status invalid"):
        assert in_moving_stage = TRUE
    end

    with_attr error_message("FirstRelicCombat: player not exist"):
        assert_not_zero(koma.status)
    end
    with_attr error_message("FirstRelicCombat: player is dead"):
        assert_not_equal(koma.status, KOMA_STATUS_DEAD)
    end
    with_attr error_message("FirstRelicCombat: player is mining"):
        assert_not_equal(koma.status, KOMA_STATUS_MINING)
    end

    return ()
end

# actions include mine, recall, produce bot
func player_can_action_ores{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id: felt, account: felt):
    alloc_locals

    let (koma) = komas.read(combat_id, account)
    let (in_moving_stage) = FirstRelicCombat_in_moving_stage(combat_id)
    with_attr error_message("FirstRelicCombat: combat status invalid"):
        assert in_moving_stage = TRUE
    end

    with_attr error_message("FirstRelicCombat: player not exist"):
        assert_not_zero(koma.status)
    end
    with_attr error_message("FirstRelicCombat: player is dead"):
        assert_not_equal(koma.status, KOMA_STATUS_DEAD)
    end
    
    return ()
end