%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from contracts.pvp.first_relic.structs import (
    Koma,
    Prop,
    Coordinate,
)
from contracts.pvp.first_relic.third_stage.base.FR3rdBaseLibrary import (
    FR3rd_base_random
)

from contracts.util.random import get_random_number

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
    ):
    return ()
end

@view
func getKoma{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id : felt, account : felt) -> (koma: Koma):
    let (r) = get_random_number(account, 1, 200)
    let coo = Coordinate(0,0)
    let koma = Koma(
        account, coo, 0, 1000, 1000, r,0,0,0,0,0,6, 0,0,0,30,100
    )

    #  let new_koma = Koma(
    #     koma.account, koma.coordinate, koma.status, koma.health, koma.max_health, koma.agility, koma.move_speed,
    #     koma.props_weight, koma.props_max_weight, koma.workers_count, koma.mining_workers_count+workers_count,
    #     koma.drones_count, koma.action_radius, koma.element, koma.ore_amount + retreive_amount, koma.atk, koma.defense
    # )
    return (koma)
end

@view
func getProp{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(combat_id : felt, prop_id : felt) -> (res: (felt, Prop)):
    let prop = Prop(prop_id, 0, 0, 0)
    return ((0,prop))
end
