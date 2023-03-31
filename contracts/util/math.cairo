%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import abs_value, sign, unsigned_div_rem, assert_lt_felt
from contracts.pvp.first_relic.structs import Coordinate

func min{range_check_ptr}(a: felt, b: felt) -> (min: felt) {
    let res = sign(a - b);
    if (res == 1) {
        return (b,);
    }

    return (a,);
}

func max{range_check_ptr}(a: felt, b: felt) -> (min: felt) {
    let res = sign(a - b);
    if (res == 1) {
        return (a,);
    }

    return (b,);
}

func sort_asc{range_check_ptr}(a: felt, b: felt) -> (lower: felt, higher: felt) {
    let res = sign(a - b);
    if (res == 1) {
        return (b, a);
    }
    return (a, b);
}

// in or on oval check
// x0, y0 oval origin point
// x1, y1 point to check
func in_on_oval{range_check_ptr}(x0: felt, y0: felt, x1: felt, y1: felt, a: felt, b: felt) -> (
    res: felt
) {
    return (TRUE,);
    // let x_distance = x1 - x0
    // let y_distance = y1 - y0
    // let (x, _) = unsigned_div_rem(x_distance * x_distance, a * a)
    // let (y, _) = unsigned_div_rem(y_distance * y_distance, b * b)
    // let (sign_) = sign(x + y - 1)
    // if sign_ == 1:
    //     return (FALSE)
    // else:
    //     return (TRUE)
    // end
}

// check if target in or on layer x out of p
func in_on_layer{range_check_ptr}(p: Coordinate, target: Coordinate, layer: felt) -> (res: felt) {
    alloc_locals;

    assert_lt_felt(0, layer);
    let x_distance = abs_value(p.x - target.x);
    let y_distance = abs_value(p.y - target.y);
    let (x_valid) = felt_le(x_distance, layer);
    let (y_valid) = felt_le(y_distance, layer);
    if (x_valid * y_valid == 0) {
        return (FALSE,);
    } else {
        return (TRUE,);
    }
}

// check if a is lower than or equal to b
func felt_le{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
    let res = sign(a - b);
    if (res == 1) {
        return (FALSE,);
    } else {
        return (TRUE,);
    }
}

// check if a is lower than b
func felt_lt{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
    let res = sign(a - b);
    if (res == -1) {
        return (TRUE,);
    } else {
        return (FALSE,);
    }
}
