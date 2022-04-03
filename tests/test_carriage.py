"""token/Land.cairo test file."""
from curses.ascii import SO
import os
from itsdangerous import Signer
from numpy import sign
from utils import (Signer, contract_path, to_uint, uint_list_to_felt_list)

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CARRIAGE_CONTRACT_FILE = contract_path('contracts/token/Carriage.cairo')
SOLDIER_CONTRACT_FILE = contract_path('contracts/token/Soldier.cairo')
ACCESS_CONTROL_CONTRACT_FILE = contract_path('contracts/access/AccessControl.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
signer = Signer(123456789)

# testing vars
SOLDIERS_COUNT = int(5)

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_aboard():
    """Test land mint."""
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    access_control_contract = await starknet.deploy(ACCESS_CONTROL_CONTRACT_FILE, constructor_calldata=[account_contract.contract_address])
    carriage_contract = await starknet.deploy(CARRIAGE_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])
    soldier_contract = await starknet.deploy(SOLDIER_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])

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

    # mint carriage
    await signer.send_transaction(
        account_contract, carriage_contract.contract_address, 'mint', [account_contract.contract_address]
    )

    # mint soldier
    mint_soldier_calls = []
    for i in range(0, SOLDIERS_COUNT):
        mint_soldier_calls.append(
            [soldier_contract.contract_address, "mint", [account_contract.contract_address]]
        )
    await signer.send_transactions(account_contract, mint_soldier_calls)

    # account setApproval
    await signer.send_transaction(
        account_contract, soldier_contract.contract_address, "setApprovalForAll", [carriage_contract.contract_address, 1]
    )

    # take soldiers aboard
    # uint list
    soldier_ids = list(map(to_uint, range(1, SOLDIERS_COUNT + 1)))
    await signer.send_transaction(
        account_contract, carriage_contract.contract_address, 'takeSouldiersAboard', [*to_uint(1), SOLDIERS_COUNT, *uint_list_to_felt_list(soldier_ids)]
    )
    execution_info = await carriage_contract.carriageSoldierLength(to_uint(1)).call()
    assert execution_info.result.len == SOLDIERS_COUNT
    for soldier_id in soldier_ids:
        execution_info = await soldier_contract.ownerOf(soldier_id).call()
        assert execution_info.result.owner == carriage_contract.contract_address
        execution_info = await carriage_contract.carriageSoldierIndex(soldier_id).call()
        assert execution_info.result.carriage_and_index[0] == to_uint(1)
    
    
    
    
