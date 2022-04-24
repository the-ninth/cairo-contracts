"""market/Market.cairo test file."""
from curses.ascii import SO
import os
from itsdangerous import Signer
from numpy import sign
from utils import (Signer, contract_path)

import pytest
from starkware.starknet.testing.starknet import Starknet
from utils import (Signer, contract_path, to_uint,from_uint, uint_list_to_felt_list,str_to_felt,MAX_UINT256)

# The path to the contract source code.
MARKET_CONTRACT_FILE = contract_path('contracts/market/Market.cairo')
ERC1155_CONTRACT_FILE = contract_path('contracts/erc1155/ERC1155.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
ERC20_CONTRACT_FILE = contract_path('openzeppelin/token/erc20/ERC20_Mintable.cairo')
signer = Signer(123456789)

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_market():
    """Test market."""
    starknet = await Starknet.empty()
    owner_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    seller_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    buyer_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])

    erc1155_contract = await starknet.deploy(ERC1155_CONTRACT_FILE, constructor_calldata=[])
    erc20_contract = await starknet.deploy(ERC20_CONTRACT_FILE, constructor_calldata=[str_to_felt('TEST'),str_to_felt('TEST'),18,*to_uint(1000000000),owner_contract.contract_address,owner_contract.contract_address])
    market_contract = await starknet.deploy(MARKET_CONTRACT_FILE, constructor_calldata=[owner_contract.contract_address])

    # set market config
    await signer.send_transaction(
        owner_contract, market_contract.contract_address, 'addToken', [erc20_contract.contract_address, 20]
    )
    await signer.send_transaction(
        owner_contract, market_contract.contract_address, 'addToken', [erc1155_contract.contract_address, 1155]
    )

    # mint erc20 to buyer
    await signer.send_transaction(
        owner_contract, erc20_contract.contract_address, 'mint', [buyer_contract.contract_address,*to_uint(10000) ]
    )
    
    # mint 1155 
    await signer.send_transaction(
        owner_contract, erc1155_contract.contract_address, 'mint', [seller_contract.contract_address, 1, *to_uint(100), 0]
    )

    # set approve
    await signer.send_transaction(
        seller_contract, erc1155_contract.contract_address, 'setApprovalForAll', [market_contract.contract_address, 1]
    )

    # sell
    # base_coin_no,coin_no,id,amount,unit_price
    await signer.send_transaction(
        seller_contract, market_contract.contract_address, 'sell', [*to_uint(0),*to_uint(1),*to_uint(1),*to_uint(3),*to_uint(100)]
    )

    # check market order len
    execution_info = await market_contract.orderLen().call()
    assert from_uint(execution_info.result.len) == 1

    # check token len
    execution_info = await market_contract.tokenLen().call()
    assert from_uint(execution_info.result.len) == 2

    # check market balance
    execution_info = await erc1155_contract.balanceOf(market_contract.contract_address,1).call()
    assert from_uint(execution_info.result.balance) == 3

    # buy
    # approve market of transferring erc20 
    await signer.send_transaction(
        buyer_contract, erc20_contract.contract_address, 'approve', [market_contract.contract_address,*MAX_UINT256]
    )

    await signer.send_transaction(
        buyer_contract, market_contract.contract_address, 'buy', [*to_uint(0),*to_uint(1)]
    )

    # check market balance
    execution_info = await erc1155_contract.balanceOf(market_contract.contract_address,1).call()
    assert from_uint(execution_info.result.balance) == 2

    # check buyer erc1155 balance
    execution_info = await erc1155_contract.balanceOf(buyer_contract.contract_address,1).call()
    assert from_uint(execution_info.result.balance) == 1

    # check seller erc20 balance
    execution_info = await erc20_contract.balanceOf(seller_contract.contract_address).call()
    assert from_uint(execution_info.result.balance) == 100

    # cancel
    await signer.send_transaction(
        seller_contract, market_contract.contract_address, 'cancel', [*to_uint(0)]
    )

    # check market balance
    execution_info = await erc1155_contract.balanceOf(market_contract.contract_address,1).call()
    assert from_uint(execution_info.result.balance) == 0

    # check buyer erc1155 balance
    execution_info = await erc1155_contract.balanceOf(buyer_contract.contract_address,1).call()
    assert from_uint(execution_info.result.balance) == 1

    # check seller erc1155 balance
    execution_info = await erc1155_contract.balanceOf(seller_contract.contract_address,1).call()
    assert from_uint(execution_info.result.balance) == 99
   