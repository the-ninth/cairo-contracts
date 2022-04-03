"""token/Land.cairo test file."""
import os
from itsdangerous import Signer
from numpy import sign
from utils import (Signer, contract_path)

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
LAND_CONTRACT_FILE = contract_path('contracts/token/Land.cairo')
FARMER_CONTRACT_FILE = contract_path('contracts/token/Farmer.cairo')
ACCESS_CONTROL_CONTRACT_FILE = contract_path('contracts/access/AccessControl.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
signer = Signer(123456789)

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_mint():
    """Test land mint."""
    starknet = await Starknet.empty()
    account_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    access_control_contract = await starknet.deploy(ACCESS_CONTROL_CONTRACT_FILE, constructor_calldata=[account_contract.contract_address])
    land_contract = await starknet.deploy(LAND_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])
    farmer_contract = await starknet.deploy(FARMER_CONTRACT_FILE, constructor_calldata=[access_control_contract.contract_address])

    # set contract addresses to access control
    await signer.send_transaction(
        account_contract, access_control_contract.contract_address, "setLandContract", [land_contract.contract_address]
    )
    await signer.send_transaction(
        account_contract, access_control_contract.contract_address, "setFarmerContract", [farmer_contract.contract_address]
    )
    
    # grant land, farmer minter role
    await signer.send_transaction(
        account_contract, access_control_contract.contract_address, 'grantRole', [
            0x38e5770043859d87f53b82995e7d4e9b3128fff8abdd209988d3bc03,
            account_contract.contract_address
        ]
    )
    await signer.send_transaction(
        account_contract, access_control_contract.contract_address, 'grantRole', [
            0x5ca0a20c64d420776352fb99142bf9974cb6457eed577553731b8218,
            land_contract.contract_address
        ]
    )
    execution_info = await access_control_contract.hasRole(0x38e5770043859d87f53b82995e7d4e9b3128fff8abdd209988d3bc03, account_contract.contract_address).call()
    assert execution_info.result.res == 1
    execution_info = await access_control_contract.hasRole(0x5ca0a20c64d420776352fb99142bf9974cb6457eed577553731b8218, land_contract.contract_address).call()
    assert execution_info.result.res == 1
    
    # mint land and come with a farmer
    await signer.send_transaction(
        account_contract, land_contract.contract_address, 'mint', [
            account_contract.contract_address,
            *(1, 0)
        ]
    )
    execution_info = await land_contract.ownerOf((1,0)).call()
    assert execution_info.result.owner == account_contract.contract_address
    execution_info = await farmer_contract.ownerOf((1,0)).call()
    assert execution_info.result.owner == land_contract.contract_address
