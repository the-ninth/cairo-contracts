"""pvp/Combat.cairo test file."""
from curses.ascii import SO
import os
from itsdangerous import Signer
from numpy import sign
from utils import (Signer, contract_path, to_uint, uint_list_to_felt_list, add_uint)

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CARRIAGE_CONTRACT_FILE = contract_path('contracts/token/Carriage.cairo')
SOLDIER_CONTRACT_FILE = contract_path('contracts/token/Soldier.cairo')
COMBAT_CONTRACT_FILE = contract_path('contracts/pvp/Combat.cairo')
ACCESS_CONTROL_CONTRACT_FILE = contract_path('contracts/access/AccessControl.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
signer = Signer(123456789)

# testing vars
PLAYER1_SOLDIERS_COUNT = 5
PLAYER2_SOLDIERS_COUNT = 5

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_combat():
    """Test land mint."""
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    account1_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    account2_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    access_control_contract = await starknet.deploy(ACCESS_CONTROL_CONTRACT_FILE, constructor_calldata=[account_contract.contract_address])
    carriage_contract = await starknet.deploy(CARRIAGE_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])
    soldier_contract = await starknet.deploy(SOLDIER_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])
    combat_contract = await starknet.deploy(COMBAT_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])

    # set contract addresses to access control
    await signer.send_transactions(
        account_contract,
        [
            [access_control_contract.contract_address, "setCarriageContract", [carriage_contract.contract_address]],
            [access_control_contract.contract_address, "setSoldierContract", [soldier_contract.contract_address]],
        ],
    )

    # grant carriage, solider minter role
    await signer.send_transactions(
        account_contract,
        [
            (access_control_contract.contract_address, "grantRole", [0xc323dda993e8030ae375d46c7b2d197a8fc0ef7e247e5034f623d9e2, account_contract.contract_address]),
            (access_control_contract.contract_address, "grantRole", [0x2a1039a289ff8a169e7311419cb8d250dcd0693c0c5f039b5976d3bc, account_contract.contract_address]),
        ]
    )

    # prepare carriage
    (player1_carriage_id, player1_soldier_ids) = await prepare_carriage(account_contract, carriage_contract, soldier_contract, PLAYER1_SOLDIERS_COUNT, account1_contract)

    # player setApproval
    await signer.send_transaction(
        account1_contract, carriage_contract.contract_address, "setApprovalForAll", [combat_contract.contract_address, 1]
    )
    await signer.send_transaction(
        account2_contract, carriage_contract.contract_address, "setApprovalForAll", [combat_contract.contract_address, 1]
    )

    # new combat
    await signer.send_transaction(
        account1_contract, combat_contract.contract_address, "newCombat", [*player1_carriage_id]
    )
    execution_info = await combat_contract.combatCount().call()
    assert execution_info.result.count == 1
    
    
async def prepare_carriage(account_contract, carriage_contract, soldier_contract, soldiers_count, player_contract):
    # mint carriage to player
    execution_info = await signer.send_transaction(
        account_contract, carriage_contract.contract_address, 'mint', [player_contract.contract_address]
    )
    carriage_id = tuple(execution_info.result.response)

    # mint soldier to player
    execution_info = await soldier_contract.totalSupply().call()
    next_soldier_id = execution_info.result.totalSupply
    soldier_ids = []
    mint_soldier_calls = []
    for i in range(0, soldiers_count):
        next_soldier_id = add_uint(next_soldier_id, to_uint(1))
        soldier_ids.append(next_soldier_id)
        mint_soldier_calls.append(
            [soldier_contract.contract_address, "mint", [player_contract.contract_address]]
        )
    await signer.send_transactions(account_contract, mint_soldier_calls)

    # player setApproval
    await signer.send_transaction(
        player_contract, soldier_contract.contract_address, "setApprovalForAll", [carriage_contract.contract_address, 1]
    )

    # take soldiers aboard
    await signer.send_transaction(
        player_contract, carriage_contract.contract_address, 'takeSouldiersAboard', [*to_uint(1), soldiers_count, *uint_list_to_felt_list(soldier_ids)]
    )
    
    return (carriage_id, soldier_ids)
