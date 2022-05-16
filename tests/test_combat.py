"""pvp/Combat.cairo test file."""
from curses.ascii import SO
import os
from utils import (Signer, contract_path, to_uint, uint_list_to_felt_list, add_uint)

import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo

# The path to the contract source code.
COMBAT_CONTRACT_FILE = contract_path('contracts/pvp/first_relic/FirstRelicCombat.cairo')
COMBAT_REGISTER_CONTRACT_FILE = contract_path('contracts/pvp/first_relic/FirstRelicCombatRegister.cairo')
ACCESS_CONTROL_CONTRACT_FILE = contract_path('contracts/access/AccessControl.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
RANDOM_PRODUCER_CONTRACT_FILE = contract_path('contracts/random/RandomProducer.cairo')
NINTH_CONTRACT_FILE = contract_path('contracts/token/Ninth.cairo')
signer = Signer(123456789)

# testing var
COMBAT_STATUS_REGISTERING = 1
COMBAT_STATUS_PREPARING = 2
COMBAT_STATUS_FIRST_STAGE = 3
COMBAT_STATUS_SECOND_STAGE = 4
KOMA_STATUS_STATIC = 1
KOMA_STATUS_MOVING = 2
PREPARE_TIME = 300
WORKERS_COUNT = 3
DRONES_COUNT = 3
MOVE_TO = {"x": 50, "y": 60}


# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_combat_init(contract_factory):
    """Test combat init."""
    _, account_contract, _, fr_combat_contract, _, _, ninth_contract = contract_factory
    await signer.send_transaction(account_contract, fr_combat_contract.contract_address, "newCombat", [])
    execution_info = await fr_combat_contract.getCombatCount().call()
    assert execution_info.result.count == 1
    execution_info = await fr_combat_contract.getCombat(1).call()
    assert execution_info.result.combat.status == COMBAT_STATUS_REGISTERING

@pytest.mark.asyncio
async def test_combat_register(contract_factory):
    """test combat register"""
    starknet, account_contract, _, fr_combat_contract, fr_combat_register_contract, _, ninth_contract = contract_factory
    await signer.send_transaction(account_contract, fr_combat_contract.contract_address, "newCombat", [])
    player1 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    player2 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player1.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player2.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player1, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player2, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])

    await signer.send_transaction(player1, fr_combat_register_contract.contract_address, "register", [1])
    execution_info = await fr_combat_contract.getPlayersCount(1).call()
    assert execution_info.result.count == 1
    execution_info = await ninth_contract.balanceOf(player1.contract_address).call()
    assert execution_info.result.balance == to_uint(5000000000000000000)

    await signer.send_transaction(player2, fr_combat_register_contract.contract_address, "register", [1])
    execution_info = await fr_combat_contract.getPlayersCount(1).call()
    assert execution_info.result.count == 2

    execution_info = await fr_combat_contract.getPlayers(1, 0, 10).call()
    assert execution_info.result.players[0] == player1.contract_address
    assert execution_info.result.players[1] == player2.contract_address

    execution_info = await fr_combat_contract.getKoma(1, player1.contract_address).call()
    player1_koma = execution_info.result.koma
    assert player1_koma.status == KOMA_STATUS_STATIC

    execution_info = await fr_combat_contract.getKoma(1, player2.contract_address).call()
    player2_koma = execution_info.result.koma
    assert player2_koma.status == KOMA_STATUS_STATIC

    assert player1_koma.coordinate != player2_koma.coordinate

    execution_info = await fr_combat_contract.getKomas(1, [player1.contract_address, player2.contract_address]).call()
    assert len(execution_info.result.komas) == 2

    execution_info = await fr_combat_contract.getCombat(1).call()
    assert execution_info.result.combat.status == COMBAT_STATUS_PREPARING
    assert execution_info.result.combat.first_stage_time - execution_info.result.combat.prepare_time == PREPARE_TIME

@pytest.mark.asyncio
async def test_player_move(contract_factory):
    """test player move"""
    starknet, account_contract, _, fr_combat_contract, fr_combat_register_contract, _, ninth_contract = contract_factory
    await signer.send_transaction(account_contract, fr_combat_contract.contract_address, "newCombat", [])
    player1 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    player2 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player1.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player2.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player1, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player2, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player1, fr_combat_register_contract.contract_address, "register", [1])
    await signer.send_transaction(player2, fr_combat_register_contract.contract_address, "register", [1])
    starknet.state.state.block_info = BlockInfo.create_for_testing(starknet.state.state.block_info.block_number, starknet.state.state.block_info.block_timestamp + PREPARE_TIME + 600)
    await signer.send_transaction(player1, fr_combat_contract.contract_address, "move", [1, player1.contract_address, MOVE_TO["x"], MOVE_TO["y"]])
    
    execution_info = await fr_combat_contract.getKoma(1, player1.contract_address).call()
    assert execution_info.result.koma.status == KOMA_STATUS_MOVING
    print(execution_info.result.koma)

    execution_info = await fr_combat_contract.getCombat(1).call()
    assert execution_info.result.combat.status == COMBAT_STATUS_SECOND_STAGE

    execution_info = await fr_combat_contract.getKomasMovments(1, [player1.contract_address]).call()
    movment = execution_info.result.movments[0]
    assert movment.to.x == MOVE_TO["x"]
    assert movment.to.y == MOVE_TO["y"]
    print(movment)


@pytest.mark.asyncio
async def test_mine_ore(contract_factory):
    """test player move"""
    starknet, account_contract, _, fr_combat_contract, fr_combat_register_contract, _, ninth_contract = contract_factory
    await signer.send_transaction(account_contract, fr_combat_contract.contract_address, "newCombat", [])
    player1 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    player2 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player1.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player2.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player1, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player2, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player1, fr_combat_register_contract.contract_address, "register", [1])
    await signer.send_transaction(player2, fr_combat_register_contract.contract_address, "register", [1])
    starknet.state.state.block_info = BlockInfo.create_for_testing(starknet.state.state.block_info.block_number, starknet.state.state.block_info.block_timestamp + PREPARE_TIME + 1)
    execution_info = await fr_combat_contract.getOres(1, 0, 5).call()
    ores = execution_info.result.ores
    await signer.send_transaction(player1, fr_combat_contract.contract_address, "mineOre", [1, player1.contract_address, *ores[0].coordinate, 3])
    execution_info = await fr_combat_contract.getKomaMiningOres(1, player1.contract_address).call()
    mining_ores = execution_info.result.mining_ores
    assert len(mining_ores) == 1

    execution_info = await fr_combat_contract.getKoma(1, player1.contract_address).call()
    print(execution_info.result.koma)
    starknet.state.state.block_info = BlockInfo.create_for_testing(starknet.state.state.block_info.block_number, starknet.state.state.block_info.block_timestamp + 86400)
    await signer.send_transaction(player1, fr_combat_contract.contract_address, "recallWorkers", [1, player1.contract_address, *ores[0].coordinate, 3])
    execution_info = await fr_combat_contract.getKoma(1, player1.contract_address).call()
    print(execution_info.result.koma)

@pytest.mark.asyncio
async def test_produce_bot(contract_factory):
    """test player move"""
    starknet, account_contract, _, fr_combat_contract, fr_combat_register_contract, _, ninth_contract = contract_factory
    await signer.send_transaction(account_contract, fr_combat_contract.contract_address, "newCombat", [])
    player1 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    player2 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player1.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player2.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player1, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player2, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player1, fr_combat_register_contract.contract_address, "register", [1])
    await signer.send_transaction(player2, fr_combat_register_contract.contract_address, "register", [1])
    starknet.state.state.block_info = BlockInfo.create_for_testing(starknet.state.state.block_info.block_number, starknet.state.state.block_info.block_timestamp + PREPARE_TIME + 1)
    execution_info = await fr_combat_contract.getOres(1, 0, 5).call()
    ores = execution_info.result.ores
    await signer.send_transaction(player1, fr_combat_contract.contract_address, "mineOre", [1, player1.contract_address, *ores[0].coordinate, 3])
    starknet.state.state.block_info = BlockInfo.create_for_testing(starknet.state.state.block_info.block_number, starknet.state.state.block_info.block_timestamp + 600)
    await signer.send_transaction(player1, fr_combat_contract.contract_address, "produceBot", [1, player1.contract_address, 1, 1])
    await signer.send_transaction(player1, fr_combat_contract.contract_address, "produceBot", [1, player1.contract_address, 2, 1])
    execution_info = await fr_combat_contract.getKoma(1, player1.contract_address).call()
    koma = execution_info.result.koma
    assert koma.workers_count == WORKERS_COUNT + 1
    assert koma.drones_count == DRONES_COUNT + 1

@pytest.mark.asyncio
async def test_chest(contract_factory):
    """test player move"""
    starknet, account_contract, _, fr_combat_contract, fr_combat_register_contract, _, ninth_contract = contract_factory
    await signer.send_transaction(account_contract, fr_combat_contract.contract_address, "newCombat", [])
    player1 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    player2 = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player1.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(account_contract, ninth_contract.contract_address, "transfer", [player2.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player1, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player2, ninth_contract.contract_address, "approve", [fr_combat_register_contract.contract_address, *to_uint(10000000000000000000)])
    await signer.send_transaction(player1, fr_combat_register_contract.contract_address, "register", [1])
    await signer.send_transaction(player2, fr_combat_register_contract.contract_address, "register", [1])
    starknet.state.state.block_info = BlockInfo.create_for_testing(starknet.state.state.block_info.block_number, starknet.state.state.block_info.block_timestamp + PREPARE_TIME + 1)
    execution_info = await fr_combat_contract.getChests(1, 0, 5).call()
    chests = execution_info.result.data
    await signer.send_transaction(player1, fr_combat_contract.contract_address, "openChest", [1, player1.contract_address, *chests[0].coordinate])
    execution_info = await fr_combat_contract.getChestOptions(1, chests[0].coordinate).call()
    options = execution_info.result.options
    assert len(options) == 3
    print(options)

    await signer.send_transaction(player1, fr_combat_contract.contract_address, "selectChestOption", [1, player1.contract_address, *chests[0].coordinate, 2])
    execution_info = await fr_combat_contract.getKomaProps(1, player1.contract_address).call()
    player1_props = execution_info.result.koma_props
    print(player1_props)
    assert options[1] == player1_props[0].prop_creature_id


@pytest.fixture
async def contract_factory():
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    access_control_contract = await starknet.deploy(ACCESS_CONTROL_CONTRACT_FILE, constructor_calldata=[account_contract.contract_address])
    fr_combat_contract = await starknet.deploy(COMBAT_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])
    random_producer_contract = await starknet.deploy(RANDOM_PRODUCER_CONTRACT_FILE)
    fr_combat_register_contract = await starknet.deploy(COMBAT_REGISTER_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])
    ninth_contract = await starknet.deploy(NINTH_CONTRACT_FILE, constructor_calldata=[account_contract.contract_address])
    # set contract addresses to access control
    await signer.send_transactions(
        account_contract,
        [
            [access_control_contract.contract_address, "setRandomProducerContract", [random_producer_contract.contract_address]],
            [access_control_contract.contract_address, "setNinthContract", [ninth_contract.contract_address]],
            [access_control_contract.contract_address, "setFrCombatContract", [fr_combat_contract.contract_address]],
            [access_control_contract.contract_address, "setFrCombatRegisterContract", [fr_combat_register_contract.contract_address]],
            [access_control_contract.contract_address, "grantRole", [0xf0845edbfd13ab09e214c98fdbf5ae36408448178802e82e04d85d98, account_contract.contract_address]]
        ],
    )
    return starknet, account_contract, access_control_contract, fr_combat_contract, fr_combat_register_contract, random_producer_contract, ninth_contract


