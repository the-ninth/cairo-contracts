%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero

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
