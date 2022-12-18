"""pvp/Combat.cairo test file."""
from curses.ascii import SO
import os
from utils import (Signer, contract_path, to_uint,
                   uint_list_to_felt_list, add_uint)

import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo

# The path to the contract source code.
ERC721_CONTRACT_FILE = contract_path(
    'contracts/ERC721_Enumerable_AutoId/ERC721EnumerableAutoId.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
signer = Signer(123456789)

# testing var


@pytest.mark.asyncio
async def test(contract_factory):
    print("\n")
    starknet, account_contract, erc721_contract = contract_factory
    await signer.send_transaction(account_contract, erc721_contract.contract_address, "mintMulti", [
        2, 0x1, 0x2
    ])


@pytest.fixture
async def contract_factory():
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    erc721_contract = await starknet.deploy(ERC721_CONTRACT_FILE, constructor_calldata=[0x1, 0x2, account_contract.contract_address])
    return starknet, account_contract, erc721_contract
