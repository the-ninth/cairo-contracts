"""market/Market.cairo test file."""
from curses.ascii import SO
import os
from itsdangerous import Signer
from numpy import sign
import pytest
import json
import time
import random

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.state import CastableToAddress, StarknetState
from utils import (Signer, contract_path, to_uint,from_uint, uint_list_to_felt_list,str_to_felt,MAX_UINT256)

# The path to the contract source code.
MARKET_CONTRACT_FILE = contract_path('contracts/market/Market.cairo')
ERC1155_CONTRACT_FILE = contract_path('contracts/erc1155/ERC1155.cairo')
ACCOUNT_CONTRACT_FILE = contract_path('openzeppelin/account/Account.cairo')
ERC20_CONTRACT_FILE = contract_path('openzeppelin/token/erc20/ERC20_Mintable.cairo')
FRBoss_CONTRACT_FILE = contract_path('contracts/pvp/first_relic/third_stage/FR3rd.cairo')
COMBAT_MOCK = contract_path('contracts/pvp/first_relic/third_stage/mocks/FirstRelicCombatMock.cairo')
Proxy_CONTRACT_FILE = contract_path('contracts/proxy/upgradeProxy/UpgradeProxy.cairo')
signer = Signer(123456789)

maxUser =9
# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.


def getPropId(heroIndex,type,index):
    return type + (heroIndex*100)+index

def printAction(result):
    alen = len(result.actions)
    print('actions ',alen)
    for i in range(alen):
        print(result.actions[i])

def printHero(result,infos):
    alen = len(result.heros)
    print('heros ',alen)
    for i in range(alen):
        if i ==0:
            print(result.heros[i])
        else:
            print(result.heros[i],infos[i-1].agility,infos[i-1].atk)

PROP_CREATURE_SHIELD           = 100000001
PROP_CREATURE_ATTACK_UP_30P    = 100000002
PROP_CREATURE_DAMAGE_DOWN_30P  = 100000003
PROP_CREATURE_HEALTH_KIT       = 100000004
@pytest.mark.asyncio
async def test_market():
    """Test market."""
    print('start')
    starknet = await Starknet.empty()

    frboss_def = compile_starknet_files([FRBoss_CONTRACT_FILE], debug_info=True,disable_hint_validation=True)
    state = await StarknetState.empty()
    print('start')
    print(time.time())
    owner_contract = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
    implementation_contract = await starknet.deploy(contract_def=frboss_def, constructor_calldata=[]) 
    frboss_contract = await starknet.deploy(Proxy_CONTRACT_FILE, constructor_calldata=[implementation_contract.contract_address])
    mock_contract = await starknet.deploy(COMBAT_MOCK, constructor_calldata=[])


    print('-----------')

    frboss_contract = StarknetContract(state=starknet.state, abi=frboss_def.abi, contract_address=frboss_contract.contract_address,deploy_execution_info=frboss_contract.deploy_execution_info)
    
# 
    execution_info = await frboss_contract.checkAction(0,0).call()
    print(execution_info.result)
    print(execution_info.result[0])
    print(execution_info.result[1])

    print('frboss_contract')
    await signer.send_transaction(
        owner_contract, frboss_contract.contract_address, 'initialize', [owner_contract.contract_address]
    )
    await signer.send_transaction(
        owner_contract, frboss_contract.contract_address, 'setCombat1stAddress', [mock_contract.contract_address]
    )
    print('initialize')
    # print(dir(frboss_contract1))

    erc20_contract = await starknet.deploy(ERC20_CONTRACT_FILE, constructor_calldata=[str_to_felt('TEST'),str_to_felt('TEST'),18,*to_uint(100000000000000000),frboss_contract.contract_address,owner_contract.contract_address])


    # set market config
    await signer.send_transaction(
        owner_contract, frboss_contract.contract_address, 'addBossMeta', [5000,100,100,1100]
    )
    await signer.send_transaction(
        owner_contract, frboss_contract.contract_address, 'setRewardTokenAddress', [erc20_contract.contract_address]
    )
    await signer.send_transaction(
        owner_contract, frboss_contract.contract_address, 'addCombatMeta', [100000000000000000,60,11,maxUser]
    )

    execution_info = await erc20_contract.balanceOf(frboss_contract.contract_address).call()
    print(execution_info.result)

    print('boss init end ',time.time())
    heros = []
    for i in range(maxUser):
        hero = await starknet.deploy(ACCOUNT_CONTRACT_FILE, constructor_calldata=[signer.public_key])
        heros.append(hero)
    print('hero contract end ',time.time())
    
    allInfos = []
    for i in range(maxUser):
        print(i,'join  : ',heros[i].contract_address)
        await signer.send_transaction(
            heros[i], frboss_contract.contract_address, 'join', [0,heros[i].contract_address]
        )
        execution_info = await mock_contract.getKoma(0,heros[i].contract_address).call()
        allInfos.append(execution_info.result.koma)
        print(execution_info.result)
        
    # print heros
    execution_info = await frboss_contract.getCombatInfoById(0,0).call()
    print(execution_info.result)
    print(execution_info.result.combat)
    printHero(execution_info.result,allInfos)

    # props
    await signer.send_transaction(
        heros[1], mock_contract.contract_address, 'mintProp', [0,heros[1].contract_address,1]
    )

    # Test for repeated join
#     await signer.send_transaction(heros[3], frboss_contract.contract_address, 'join', [])
    # execution_info = await frboss_contract.getCombatInfoById(0).call()
    # print(execution_info.result)

    print('hero join end ',time.time())
    for j in range(5):
        for i in range(maxUser):
            print('action',i)
            execution_info = await frboss_contract.checkAction(0,i+1).call()
            if execution_info.result[1] == 0:
                print(f' hero {i+1} ,no need')
                continue
            if i ==1:
                await signer.send_transaction(
                    heros[i], frboss_contract.contract_address, 'action', [0, j, i+1 ,2,getPropId(1,PROP_CREATURE_SHIELD,j)]
                )
            else:
                if i < maxUser/2:
                    target = 0
                else:
                    target = random.randint(0,maxUser)
                print(target)
                tx = await signer.send_transaction(
                    heros[i], frboss_contract.contract_address, 'action', [0, j, i+1 ,1,target]
                )
        print(tx.raw_events)
        print('action end ',time.time())
        execution_info = await frboss_contract.getCombatInfoById(0,0).call()
        print(execution_info.result.combat)
        printHero(execution_info.result,allInfos)
        printAction(execution_info.result)
        execution_info1 = await frboss_contract.getSurvivings(0).call()
        print(execution_info1.result)
        if execution_info.result.combat.end_info != 0:
            break

    # check token len
    execution_info = await frboss_contract.getCombatInfoById(0,0).call()
    print(execution_info.result)

    print(execution_info.result.combat)
    printHero(execution_info.result,allInfos)
    printAction(execution_info.result)

    execution_info = await erc20_contract.balanceOf(frboss_contract.contract_address).call()
    print(execution_info.result)
    for i in range(maxUser):
        execution_info = await erc20_contract.balanceOf(heros[i].contract_address).call()
        print(execution_info.result)
    

    execution_info = await frboss_contract.getCombatInfoById(0,0).call()
    print(execution_info.result)
