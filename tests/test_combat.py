"""pvp/Combat.cairo test file."""
from curses.ascii import SO
import os
from utils import (Signer, contract_path, to_uint, uint_list_to_felt_list, add_uint)

import pytest
from starkware.starknet.testing.starknet import Starknet

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
KOMA_STATUS_STATIC = 1
PREPARE_TIME = 300


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


