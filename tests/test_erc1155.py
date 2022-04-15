"""token/Carriage.cairo test file."""
from curses.ascii import SO
import os
from numpy import sign
from utils import (Signer, contract_path, to_uint, uint_list_to_felt_list)

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
ERC1155_CONTRACT_FILE = contract_path('contracts/erc1155/ERC1155.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
signer = Signer(123456789)

# testing vars
ACCOUNT1_MINT_AMOUNT_TOKEN_1 = 1000
ACCOUNT1_TRANSFER_TO_ACCOUNT2_AMOUNT_TOKEN_1 = 500

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_erc1155():
    """Test land mint."""
    starknet = await Starknet.empty()
    erc1155_contract = await starknet.deploy(ERC1155_CONTRACT_FILE, constructor_calldata=[])
    op_account_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    account1_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    account2_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    

    # mint for account1
    await signer.send_transaction(
        op_account_contract, erc1155_contract.contract_address, 'mint', [account1_contract.contract_address, 1, *to_uint(ACCOUNT1_MINT_AMOUNT_TOKEN_1), 0]
    )
    execution_info = await erc1155_contract.balanceOf(account1_contract.contract_address, 1).call()
    assert execution_info.result.balance == to_uint(ACCOUNT1_MINT_AMOUNT_TOKEN_1)

    # transfer to account2
    await signer.send_transaction(
        account1_contract, erc1155_contract.contract_address, 'safeTransferFrom', [
            account1_contract.contract_address, 
            account2_contract.contract_address,
            1,
            *to_uint(ACCOUNT1_TRANSFER_TO_ACCOUNT2_AMOUNT_TOKEN_1),
            0
        ]
    )
    execution_info = await erc1155_contract.balanceOf(account1_contract.contract_address, 1).call()
    account1_balance = execution_info.result.balance
    assert account1_balance == to_uint(ACCOUNT1_MINT_AMOUNT_TOKEN_1 - ACCOUNT1_TRANSFER_TO_ACCOUNT2_AMOUNT_TOKEN_1)
    execution_info = await erc1155_contract.balanceOf(account2_contract.contract_address, 1).call()
    assert execution_info.result.balance == to_uint(ACCOUNT1_TRANSFER_TO_ACCOUNT2_AMOUNT_TOKEN_1)

    # account 1 approve to account 2, account 2 transfer from account 1
    await signer.send_transaction(
        account1_contract, erc1155_contract.contract_address, 'setApprovalForAll', [account2_contract.contract_address, 1]
    )
    await signer.send_transaction(
        account2_contract, erc1155_contract.contract_address, 'safeTransferFrom', [
            account1_contract.contract_address, 
            account2_contract.contract_address,
            1,
            *account1_balance,
            0
        ]
    )
    execution_info = await erc1155_contract.balanceOf(account1_contract.contract_address, 1).call()
    assert execution_info.result.balance == to_uint(0)
    execution_info = await erc1155_contract.balanceOf(account2_contract.contract_address, 1).call()
    assert execution_info.result.balance == to_uint(ACCOUNT1_MINT_AMOUNT_TOKEN_1)
    
    
    
