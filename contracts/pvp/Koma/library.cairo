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

#
# Storage
#

@storage_var
func Koma_koma_creatures(koma_creature_id : felt) -> (koma_creature : KomaCreature):
end

@storage_var
func Koma_komas(token_id : Uint256) -> (koma : Koma):
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
        let koma = Koma(
            token_id=token_id,
            creature_id=koma_creature_id,
            rarity=koma_creature.rarity,
            workers_count=koma_creature.workers_count,
            drones_count=koma_creature.drones_count,
            max_hp=koma_creature.max_hp,
            defense=koma_creature.defense,
            atk=koma_creature.atk,
            worker_mining_speed=koma_creature.worker_mining_speed,
        )
        Koma_komas.write(token_id, koma)
        return (token_id)
    end

    func get_koma{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        token_id : Uint256
    ) -> (koma : Koma):
        let (koma) = Koma_komas.read(token_id)
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
    let (koma) = Koma_komas.read(token_id)
    assert komas[komas_len] = koma

    let (index) = uint256_checked_add(index, Uint256(1, 0))
    return _get_account_komas_recursively(account, index, length + 1, total, komas_len + 1, komas)
end
