""" test file."""

import json
import pytest
import os
from nile.utils import (
    to_uint, add_uint, sub_uint, str_to_felt, MAX_UINT256, ZERO_ADDRESS,
    INVALID_UINT256, TRUE, assert_revert,hex_address
)

from signers import MockSigner

from starkware.starknet.public.abi import get_selector_from_name

from utils import (Account,
    assert_event_emitted, assert_events_emitted, contract_path, State, get_cairo_path, get_contract_class
)

# The path to the contract source code.
signer = MockSigner(123456789)

# testing var


@pytest.mark.asyncio
async def test():
    print("initializer")

    koma_cls = get_contract_class('contracts/komaNFT/KomaType.cairo')
    # print(koma_cls)
    proxy_cls = get_contract_class('openzeppelin/upgrades/presets/Proxy.cairo')
    account_cls = get_contract_class("openzeppelin/account/presets/Account.cairo")

    # """Test market."""
    print('start')
    starknet = await State.init()

    account1 = await starknet.deploy(
        contract_class=account_cls,
        constructor_calldata=[signer.public_key]
    )
    print("account1:",account1.contract_address)

    account2 = await starknet.deploy(
        contract_class=account_cls,
        constructor_calldata=[signer.public_key]
    )
    print("account2:",account2.contract_address)



    koma = await starknet.declare(
        contract_class=koma_cls,
    )
    print("koma.class_hash")
    print(koma.class_hash)

    selector = get_selector_from_name('initializer')
    params = [
        account1.contract_address   # admin account
    ]
    proxy = await starknet.deploy(
        contract_class=proxy_cls,
        constructor_calldata=[koma.class_hash, selector,
                              len(params),
                              *params]
    )

    # # initialize
    # await signer.send_transaction(
    #     account1, proxy.contract_address, 'initializer', [
    #         account1.contract_address]
    # )

    info = await signer.send_transaction(
        account1, proxy.contract_address, 'getAdmin', []
    )
    print(info.call_info.retdata)
    print(hex_address(info.call_info.retdata[1]))


    info = await signer.send_transaction(
        account1, proxy.contract_address, 'wl_status', [
            account2.contract_address]
    )
    print(info.call_info.retdata)

    info = await signer.send_transaction(
        account1, proxy.contract_address, 'wl_status', [
            account2.contract_address]
    )
    print("before")
    print(info.call_info.retdata)

    # await signer.send_transaction(
    #     account1, proxy.contract_address, 'set_wl', [1,1,account2.contract_address]
    # )

    await signer.send_transaction(
        account1, proxy.contract_address, 'set_open', [1]
    )

    await signer.send_transaction(
        account1, proxy.contract_address, 'set_operator', [
            account2.contract_address, 1]
    )

    await signer.send_transaction(
        account2, proxy.contract_address, 'add_airdrop_type', [1, 1]
    )
    await signer.send_transaction(
        account2, proxy.contract_address, 'add_airdrop_type', [2, 5]
    )
    await signer.send_transaction(
        account2, proxy.contract_address, 'add_airdrop_type', [3, 9]
    )

    await signer.send_transaction(
        account2, proxy.contract_address, 'add_wl_mint', [
            1, account2.contract_address]
    )

    # info = await signer.send_transaction(
    #     account1, proxy.contract_address, 'balanceOf', [account2.contract_address]
    # )
    # print(info)

    info = await signer.send_transaction(
        account1, proxy.contract_address, 'get_user_koma_type', [
            account2.contract_address]
    )
    print(info.call_info.retdata)



    # await signer.send_transaction(
    #     account2, proxy.contract_address, 'set_mint_limit',[4]
    # )

    # info = await signer.send_transaction(
    #     account2, proxy.contract_address, 'mint', [2]
    # )

    # info = await signer.send_transaction(
    #     account1, proxy.contract_address, 'get_user_koma_type', [account2.contract_address]
    # )
    # print(info.result)

    # info = await signer.send_transaction(
    #     account2, proxy.contract_address, 'mint', [2]
    # )