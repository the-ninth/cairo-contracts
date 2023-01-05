import pytest
from signers import MockSigner
from utils import get_contract_class, cached_contract, State
from starkware.starknet.public.abi import get_selector_from_name


signer = MockSigner(1234)

def felt_to_str(felt):
    b_felt = felt.to_bytes(31, "big")
    return b_felt.decode()

@pytest.mark.asyncio
async def test_koma():

    print("initializer")

    koma_cls = get_contract_class('KomaType')
    print(koma_cls)
    proxy_cls = get_contract_class(
        'openzeppelin/upgrades/presets/Proxy.cairo', True)
    account_cls = get_contract_class(
        "openzeppelin/account/presets/Account.cairo", True)

    # """Test market."""
    print('start')
    starknet = await State.init()

    account1 = await starknet.deploy(
        contract_class=account_cls,
        constructor_calldata=[signer.public_key]
    )

    koma = await starknet.declare(
        contract_class=koma_cls,
    )
    print("koma.class_hash")
    print(koma.class_hash)
    params = [
            account1.contract_address   # admin account
        ]
    proxy = await starknet.deploy(
        contract_class=proxy_cls,
        constructor_calldata=[
            koma.class_hash,
            get_selector_from_name('initializer'),
            len(params),
                *params
            ]
    )

    # initialize
    # await signer.send_transaction(
    #     account1, proxy.contract_address, 'initializer', [
    #         account1.contract_address,     # recipient
    #     ]
    # )

    # await signer.send_transaction(
    #     account1, proxy.contract_address, 'set_operator', [
    #         account1.contract_address, 1
    #     ]
    # )


    await signer.send_transaction(
        account1, proxy.contract_address, 'add_airdrop_type', [
            1
        ]
    )
    await signer.send_transaction(
        account1, proxy.contract_address, 'add_airdrop_type', [
            2
        ]
    )

    await signer.send_transaction(
        account1, proxy.contract_address, 'setTokenBaseURI',
        [2,
            int.from_bytes(
             "ipfs://QmSRPVPfPcZeSJ7DMghMD".encode("ascii"), "big"),
             int.from_bytes(
             "hAVExsxxxxxxx/".encode("ascii"), "big")
        ]
    )

    await signer.send_transaction(
        account1, proxy.contract_address, 'setKomaURI',
        [1,int.from_bytes(
             "1.json".encode("ascii"), "big")]
    )

    await signer.send_transaction(
        account1, proxy.contract_address, 'setKomaURI',
        [2,int.from_bytes(
             "2.json".encode("ascii"), "big")]
    )

    info = await signer.send_transaction(
        account1, proxy.contract_address, 'tokenURI', [
            *(1, 0)
        ]
    )
    print(info.call_info.retdata)
    print(felt_to_str(info.call_info.retdata[2]))
    print(felt_to_str(info.call_info.retdata[3]))
    print(felt_to_str(info.call_info.retdata[4]))

    info = await signer.send_transaction(
        account1, proxy.contract_address, 'tokenURI', [
            *(2, 0)
        ]
    )
    print(info.call_info.retdata)
    print(felt_to_str(info.call_info.retdata[2]))
    print(felt_to_str(info.call_info.retdata[3]))
    print(felt_to_str(info.call_info.retdata[4]))


    info = await signer.send_transaction(
        account1, proxy.contract_address, 'set_wl', 
        [1,1,account1.contract_address]
    )



    info = await signer.send_transaction(
        account1, proxy.contract_address, 'mint', [2]
    )
