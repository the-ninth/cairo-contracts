# from signers import MockSigner
# from signers import MockSigner
from nile.signer import Signer

from nile.core.account import Account


# signer = Signer("")
def run(nre):
    account = Account("PRI", nre.network)
    print(account)
    print(account.address)
    contractAddr = "0x0192e5bc40dc9ef4ce7b7dcdf07c8c6adda7d138989ef918caf741eb93a85e49"
    # 0x006c51a5e5a7c9000e0707591e76fb980829b6c307f680e8bdc0e78ec09b4a44
    # initializer
    # info = account.send(contractAddr,"initializer",[int("0x006c51a5e5a7c9000e0707591e76fb980829b6c307f680e8bdc0e78ec09b4a44",16)],"15945000119560")
    # print(info)
    # set open
    # info = account.send(contractAddr,"set_open",["1"],"15945000119560")
    # print(info)

    # add whitelist
    # info = account.send(contractAddr, "set_wl",
    #                     ["1", 4,
    #                      int("0x05DB0Bdc859dE851ED58CE698E984B36B111697df5E36409bd15015c891ac15a", 16),
    #                      int("0x03C4Daf97214A1Eede9877fFb88a3b2607BE89e9C2BF5bc94303a371f5021a39", 16),
    #                      int("0x074EE31a006e20DA3b6b4eE32943D35632fDe6B11510894666b32Fcd681720E7", 16),
    #                      int("0x023A2b00fcF356f0A04AE20818c87f1B49C119eCac13D890E553713acdf6FEc3", 16),
    #                      ],
    #                     "10025945000119560",78)
    # print(info)

    # upgrade
    # info = account.send(contractAddr,"upgrade",[int("0x482840e80663b23e5a672ab82f2b15f73329baf0bf5679f03d3a7ee7513dc1f",16)],"15945000119560")
    # print(info)

    # set_operator
    # info = account.send(contractAddr,"set_operator",[int("0x07080bb18ecee6fc9178014184c70cdd79ee1ea182f3edee8c9b87b0c70d264a",16),1],"15945000119560")
    # print(info)

    # mint
    # info = account.send(contractAddr,"mint",["3"],"31138002409732")
    # print(info)

    # airdrop
    # info = account.send(contractAddr, "airdrop", [int(
    #     "0x066D0e8fb782afEF2C1a9ac1A95E2c0A800a12a30402713517766F40de511fad", 16), "5"], "31138002409732")
    # print(info)

    # info = account.send(contractAddr, "airdrop", [int(
    #     "0x002011f4fa8c93a16a25b084deef5020381a714e28a94a5492a2bd620784d6ad", 16), "1"], "31138002409732", 44)
    # print(info)

    # info = account.send(contractAddr, "airdrop", [int(
    #     "0x002011f4fa8c93a16a25b084deef5020381a714e28a94a5492a2bd620784d6ad", 16), "5"], "31138002409732", 43)
    # print(info)

    # info = account.send(contractAddr, "airdrop", [int(
    #     "0x002011f4fa8c93a16a25b084deef5020381a714e28a94a5492a2bd620784d6ad", 16), "9"], "31138002409732", 44)
    # print(info)

    # account.send(contractAddr,"airdrop",[int("0x05DB0Bdc859dE851ED58CE698E984B36B111697df5E36409bd15015c891ac15a", 16),"5"],"31138002409732",79)
    # account.send(contractAddr,"airdrop",[int("0x03C4Daf97214A1Eede9877fFb88a3b2607BE89e9C2BF5bc94303a371f5021a39", 16),"9"],"31138002409732",80)
    # account.send(contractAddr,"airdrop",[int("0x074EE31a006e20DA3b6b4eE32943D35632fDe6B11510894666b32Fcd681720E7", 16),"1"],"31138002409732",81)
    # account.send(contractAddr,"airdrop",[int("0x023A2b00fcF356f0A04AE20818c87f1B49C119eCac13D890E553713acdf6FEc3", 16),"5"],"31138002409732",82)
    # account.send(contractAddr,"airdrop",[int("0x01eaCEfaa942C45eb1Ef328533Bdc4E8486E89e6C4FA0dCEA94D448192A6e352", 16),"9"],"31138002409732",63)
    # account.send(contractAddr,"airdrop",[int("0x00BCf9a9E76C8f17722dF908c4d17dCc9f5C3a5c6e78c1B3102C1cD8995DBd87", 16),"1"],"31138002409732",64)
    # account.send(contractAddr,"airdrop",[int("0x01BCE53340539089736b0713859C82d123d8C8861646f3c6552Cd174ab6EebAa", 16),"5"],"31138002409732",65)
    # account.send(contractAddr,"airdrop",[int("0x02504A1f418098e416Be2e4b5E1639c946cD1cAfc2BB8f4990d8fE699f7f8aB7", 16),"9"],"31138002409732",66)
    # account.send(contractAddr,"airdrop",[int("0x068346f46514A27c50f8b0Dd8115434A5Ee46009c66038CB3a2E92B78a8856E4", 16),"5"],"31138002409732",67)

    data = [
        # "0x07080bb18ecee6fc9178014184c70cdd79ee1ea182f3edee8c9b87b0c70d264a",
        #     "0x04c44a220de40aa7ade7de313e0d60bca2ea2efc3f3f5438642ea3fa72291b44",
        #     "0x04D8c2Ab3d34674f33b0ffAa73292c5391a0e6A0246eB81581FED8df1e9c426E",
        #     "0x01d425cfBEF2E52B4352c8C787E973F558DE63AB0811F6E1B2EE966A6c05F246",
        #     "0x061f2557a163D3598809f3E00F52aEA47d0b5d49BB812984DC0ae8bea7D8b52C",
        #     "0x01BE9f384b3a1dB4fc5228564B4076b465E574151db5288B8cC38462D74426FC",
        #     "0x06b3284570D04d756d0b445FD423944Fb5C5dABd3fa0798D02Cc6215d0a2a178",
        #     "0x067741C8aCAEDbCCfcCB9d196B7d4fb336146B14C0A80a8ecC27472Fc2499592",
        #     "0x027bbDf7117911a9cFa8ee40F46b4E703a2A69Beda8d3af0310B712dD45DC0a0",
        #     "0x06b3284570D04d756d0b445FD423944Fb5C5dABd3fa0798D02Cc6215d0a2a178",
        #     "0x00a3FFb68acceBfB984A351D5d904e3aE682326AF8C3e13A64C5f7da69BbB59b",
        #     "0x00c73E720B92D72C789eb0F83335CEbCb3d9Ef5F3Ca45F57462888436210DCAC",
        #     "0x065c4a24dAc02034029240413c18016fEE03143B710465C39906C989389fe84D",
        #     "0x0277dD3371b1AA81515843F635fa89944f521d52fBC0F4e120aD14073E9875c1",
        #     "0x02BA0e27988030e9809F83D910Cc7CEB5d73985786E09892c355cde0ecaf6420",
        #     "0x0558Ea2B56c3440f3C0a99Ac2845b8c8830bA9E4D013Ad0ba2E2c6b3C78778d6",
        #     "0x016074a9c3cA216e9cFF801fBF7A6b0eEa7Ea57f679e898170Ad95629bF7d1AB",
        #     "0x07449E3756a81257F288aee1078A3344a44D14385beD084fB03BbB9be4dB177a",
        #     "0x02F400a39B7199E3932544c7A946478E43f2071f012822c669DC159C017b66B2",
        #     "0x043B10D7098aA3104dbEB64AC0ED7F5f0C2634c1DC209a34De8Bb92Ec98BA999",
        #     "0x047D46068E40B63dFfbaf4F07a79ea8f1EdB9CA0d3cC404C4878C8e7B5020d58",
        #     "0x04e04a4dDbcEEDae6a2c7fD9A455387306f1E596563109423d26A15e9a4477C0",
        "0x016e45b2e17a763B7F75565bf2AbC437Df522d3a71ecECD4328E3B3107c15D84"]
    for address in data:
        info = nre.call(contractAddr,"get_user_koma_type", [address])
        print(address, info)

    # info = nre.call(contractAddr,
    #                     "wl_status", ["0x016e45b2e17a763B7F75565bf2AbC437Df522d3a71ecECD4328E3B3107c15D84"])
    # print( info)

    # setKomaURI
    # ipfs://QmSRPVPfPcZeSJ7DMghMDhAVExs4ppUFZUmG7sNxfnV7f6/robot-1.json

    # info = account.send(contractAddr, "setTokenBaseURI",
    #                     [2,
    #                      int.from_bytes(
    #                          "ipfs://QmSRPVPfPcZeSJ7DMghMDhA".encode("ascii"), "big"),
    #                         int.from_bytes(
    #                          "VExs4ppUFZUmG7sNxfnV7f6/robot-".encode("ascii"), "big"),
    #                      ], "31138002409732", 48)
    # print(info)

    # setTokenBaseURI
    # info = account.send(contractAddr, "setKomaURI", [1, int.from_bytes(
    #     "1.json".encode("ascii"), "big")], "31138002409732", 49)
    # print(info)
