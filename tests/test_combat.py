"""pvp/Combat.cairo test file."""
from curses.ascii import SO
import os
from utils import (Signer, contract_path, to_uint, uint_list_to_felt_list, add_uint)

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
COMBAT_CONTRACT_FILE = contract_path('contracts/pvp/first_relic/FirstRelicCombat.cairo')
ACCESS_CONTROL_CONTRACT_FILE = contract_path('contracts/access/AccessControl.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
RANDOM_PRODUCER_CONTRACT_FILE = contract_path('contracts/random/RandomProducer.cairo')
signer = Signer(123456789)

# testing var



# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_combat_init():
    """Test combat init."""
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    access_control_contract = await starknet.deploy(ACCESS_CONTROL_CONTRACT_FILE, constructor_calldata=[account_contract.contract_address])
    fr_combat_contract = await starknet.deploy(COMBAT_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])
    random_producer_contract = await starknet.deploy(RANDOM_PRODUCER_CONTRACT_FILE)
    # set contract addresses to access control
    await signer.send_transactions(
        account_contract,
        [
            [access_control_contract.contract_address, "setRandomProducerContract", [random_producer_contract.contract_address]],
            [access_control_contract.contract_address, "grantRole", [0xf0845edbfd13ab09e214c98fdbf5ae36408448178802e82e04d85d98, account_contract.contract_address]]
        ],
    )

    await signer.send_transaction(account_contract, fr_combat_contract.contract_address, "newCombat", [])
    execution_info = await fr_combat_contract.getChestCount(1).call()
    assert execution_info.result.count == 10

    execution_info = await fr_combat_contract.getChests(1, 0, 5).call()
    print(execution_info)



