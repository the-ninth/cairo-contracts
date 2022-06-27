"""pvp/Combat.cairo test file."""
from curses.ascii import SO
import os
from utils import (Signer, contract_path, to_uint,
                   uint_list_to_felt_list, add_uint)

import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo

# The path to the contract source code.
KOMA_CONTRACT_FILE = contract_path('contracts/pvp/Koma/Koma.cairo')
ACCESS_CONTROL_CONTRACT_FILE = contract_path(
    'contracts/access/AccessControl.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
signer = Signer(123456789)

# testing var


@pytest.mark.asyncio
async def test(contract_factory):
    """test combat register"""
    print("\n")
    starknet, account_contract, access_contract, koma_contract = contract_factory
    await signer.send_transaction(account_contract, koma_contract.contract_address, "setKomaCreature", [
        1, 1, 1, 3, 3, 100, 15, 7, 200
    ])
    await signer.send_transaction(account_contract, koma_contract.contract_address, "mint", [
        account_contract.contract_address, 1
    ])
    execution_info = await koma_contract.getKomaCreature(1).call()
    print(execution_info.result)
    execution_info = await koma_contract.getKoma(to_uint(1)).call()
    print(execution_info.result)


@pytest.fixture
async def contract_factory():
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    access_control_contract = await starknet.deploy(ACCESS_CONTROL_CONTRACT_FILE, constructor_calldata=[account_contract.contract_address])
    koma_contract = await starknet.deploy(KOMA_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])
    # set contract addresses to access control
    await signer.send_transactions(
        account_contract,
        [
            [access_control_contract.contract_address, "grantRole", [
                0x9a865f51c556bd6d6cf6999ca74b4fc19ab8fb6a756db54e1e0c80b3, account_contract.contract_address]],
            [access_control_contract.contract_address, "grantRole", [
                0x17a1d03badb9194b7cd7c85e4c945d8ec414a6831c6eb4fe03fd0a1a, account_contract.contract_address]]
        ],
    )
    return starknet, account_contract, access_control_contract, koma_contract
