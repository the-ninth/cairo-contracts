%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_lt, uint256_eq
from starkware.cairo.common.math import assert_not_zero, assert_le_felt, assert_lt_felt

from openzeppelin.security.safemath import uint256_checked_add, uint256_checked_sub_le
from openzeppelin.token.erc721.library import ERC721_balanceOf, ERC721_setTokenURI, ERC721_tokenURI
from openzeppelin.token.erc721_enumerable.library import ERC721_Enumerable_tokenOfOwnerByIndex

from contracts.ERC721_Enumerable_AutoId.library import ERC721_Enumerable_AutoId_mint

from contracts.util.math import felt_lt

#
# structs
#

struct KomaCreature:
    member creature_id : felt
    member rarity : felt
    member workers_count : felt
    member drones_count : felt
    member max_hp : felt
    member defense : felt
    member atk : felt
    member worker_mining_speed : felt
end

struct Koma:
    member token_id : Uint256
    member creature_id : felt
    member rarity : felt
    member workers_count : felt
    member drones_count : felt
    member max_hp : felt
    member defense : felt
    member atk : felt
    member worker_mining_speed : felt
end

const CLAIM_VERSION = 1

#
# Storage
#

@storage_var
func Koma_access_contract() -> (access_contract : felt):
end

@storage_var
func Koma_koma_creatures(koma_creature_id : felt) -> (koma_creature : KomaCreature):
end

@storage_var
func Koma_komas_creature_id(token_id : Uint256) -> (creature_id : felt):
end

@storage_var
func Koma_koma_creature_uri_len(koma_creature_id : felt) -> (len : felt):
end

@storage_var
func Koma_koma_creature_uri_by_index(koma_creature_id : felt, index : felt) -> (uri : felt):
end

@storage_var
func Koma_faucet_claim_version(account : felt) -> (claim_version : felt):
end

namespace KomaLibrary:
    func mint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, koma_creature_id : felt
    ) -> (token_id : Uint256):
        alloc_locals

        let (koma_creature) = Koma_koma_creatures.read(koma_creature_id)
        with_attr error_message("invalid creature id"):
            assert_not_zero(koma_creature.creature_id)
        end
        let (token_id) = ERC721_Enumerable_AutoId_mint(to)
        Koma_komas_creature_id.write(token_id, koma_creature_id)
        return (token_id)
    end

    func get_koma{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        token_id : Uint256
    ) -> (koma : Koma):
        let (creature_id) = Koma_komas_creature_id.read(token_id)
        with_attr error_message("query for nonexistence token"):
            assert_not_zero(creature_id)
        end
        let (koma_creature) = get_koma_creature(creature_id)
        let koma = Koma(
            token_id=token_id,
            creature_id=koma_creature.creature_id,
            rarity=koma_creature.rarity,
            workers_count=koma_creature.workers_count,
            drones_count=koma_creature.drones_count,
            max_hp=koma_creature.max_hp,
            defense=koma_creature.defense,
            atk=koma_creature.atk,
            worker_mining_speed=koma_creature.worker_mining_speed,
        )
        return (koma)
    end

    func get_komas{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        account : felt, index : Uint256, length : felt
    ) -> (komas_len : felt, komas : Koma*):
        alloc_locals

        assert_lt_felt(0, length)
        assert_le_felt(length, 100)
        let (res) = uint256_le(Uint256(0, 0), index)
        assert res = 1
        let (total) = ERC721_balanceOf(account)
        let (res) = uint256_lt(index, total)
        assert res = 1

        let (local komas : Koma*) = alloc()
        let (komas_len, komas) = _get_account_komas_recursively(
            account, index, length, total, 0, komas
        )
        return (komas_len, komas)
    end

    func get_koma_creature{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        koma_creature_id : felt
    ) -> (koma_creature : KomaCreature):
        let (koma_creature) = Koma_koma_creatures.read(koma_creature_id)
        return (koma_creature)
    end

    func set_koma_creature{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        koma_creature_id : felt, koma_creature : KomaCreature
    ) -> ():
        Koma_koma_creatures.write(koma_creature_id, koma_creature)
        return ()
    end

    func get_token_uri{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        token_id : Uint256
    ) -> (token_uri_len : felt, token_uri : felt*):
        let (creature_id) = Koma_komas_creature_id.read(token_id)
        with_attr error_message("query for nonexistence token"):
            assert_not_zero(creature_id)
        end
        let (len) = Koma_koma_creature_uri_len.read(creature_id)
        let (token_uri : felt*) = alloc()
        let (token_uri_len, token_uri) = _get_tokenURI(creature_id, 0, len, token_uri)
        return (token_uri_len, token_uri)
    end

    func set_koma_creature_uri{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        koma_creature_id : felt, token_uri_len : felt, token_uri : felt*
    ):
        with_attr error_message("invalid length"):
            assert_le_felt(0, token_uri_len)
        end
        Koma_koma_creature_uri_len.write(koma_creature_id, token_uri_len)
        _set_tokenURI(koma_creature_id, 0, token_uri_len, token_uri)
        return ()
    end

    func faucet_claim{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        account : felt
    ):
        let (claim_version) = Koma_faucet_claim_version.read(account)
        with_attr error_message("account claimed"):
            assert_lt_felt(claim_version, CLAIM_VERSION)
        end
        Koma_faucet_claim_version.write(account, CLAIM_VERSION)
        mint(account, 1)
        mint(account, 5)
        return ()
    end

    func get_faucet_claim_version{
        pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(account : felt) -> (claim_version : felt):
        let (claim_version) = Koma_faucet_claim_version.read(account)
        return (claim_version)
    end

    func get_faucet_claimable{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        account : felt
    ) -> (res : felt):
        let (claim_version) = Koma_faucet_claim_version.read(account)
        let (res) = felt_lt(claim_version, CLAIM_VERSION)
        return (res)
    end

    func mint_multi{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        account : felt, creature_ids_len : felt, creature_ids : felt*
    ):
        _mint_multi_koma(account, 0, creature_ids_len, creature_ids)
        return ()
    end
end

func _get_account_komas_recursively{
    pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
}(
    account : felt, index : Uint256, length : felt, total : Uint256, komas_len : felt, komas : Koma*
) -> (komas_len : felt, komas : Koma*):
    alloc_locals

    if length == 0:
        return (komas_len, komas)
    end

    let (res) = uint256_eq(index, total)
    if res == TRUE:
        return (komas_len, komas)
    end

    let (token_id) = ERC721_Enumerable_tokenOfOwnerByIndex(account, index)
    let (koma) = KomaLibrary.get_koma(token_id)
    assert komas[komas_len] = koma

    let (index) = uint256_checked_add(index, Uint256(1, 0))
    return _get_account_komas_recursively(account, index, length + 1, total, komas_len + 1, komas)
end

func _get_tokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    koma_creature_id : felt, index : felt, len : felt, tokenURI : felt*
) -> (tokenURI_len : felt, tokenURI : felt*):
    if index == len:
        return (index, tokenURI)
    end
    let (uri) = Koma_koma_creature_uri_by_index.read(koma_creature_id, index)
    assert tokenURI[index] = uri
    return _get_tokenURI(koma_creature_id, index + 1, len, tokenURI)
end

func _set_tokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    koma_creature_id : felt, index : felt, len : felt, tokenURI : felt*
) -> ():
    if index == len:
        return ()
    end
    Koma_koma_creature_uri_by_index.write(koma_creature_id, index, tokenURI[index])
    _set_tokenURI(koma_creature_id, index + 1, len, tokenURI)
    return ()
end

func _mint_multi_koma{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    account : felt, index : felt, creature_ids_len : felt, creature_ids : felt*
):
    if index == creature_ids_len:
        return ()
    end
    KomaLibrary.mint(account, creature_ids[index])
    _mint_multi_koma(account, index + 1, creature_ids_len, creature_ids)
    return ()
end
