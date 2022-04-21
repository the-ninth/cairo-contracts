"""pvp/Combat.cairo test file."""
from curses.ascii import SO
import os
from wsgiref.util import request_uri
from utils import (Signer, contract_path, to_uint, uint_list_to_felt_list, add_uint)

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
RANDOM_PRODUCER_CONTRACT_FILE = contract_path('contracts/random/RandomProducer.cairo')
signer = Signer(123456789)



# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_request_random():
    """Test combat init."""
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    random_producer_contract = await starknet.deploy(RANDOM_PRODUCER_CONTRACT_FILE)
    # set contract addresses to access control
    execution_info = await signer.send_transaction(account_contract, random_producer_contract.contract_address, "requestRandom", [])
    request_id = execution_info.result.response[0]
    assert request_id == 1
    execution_info = await random_producer_contract.getRandomRequestRes(request_id).call()
    assert account_contract.contract_address == execution_info.result.caller




