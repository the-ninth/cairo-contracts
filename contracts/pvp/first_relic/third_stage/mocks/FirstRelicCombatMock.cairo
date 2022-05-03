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
    let (agility) = get_random_number(account, 1, 200)
    let (atk) = get_random_number(account, 1, 150)
    let (defense) = get_random_number(account, 1, 150)
    let coo = Coordinate(0,0)
    let koma = Koma(
        account, coo, 0, 1000, 1000, agility,0,0,0,0,0,6, 0,0,0,atk+1,defense+1
    )
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
