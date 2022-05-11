%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import sign, unsigned_div_rem

func min{
        range_check_ptr
    }(a: felt, b: felt) -> (min: felt):
    let (res) = sign(a - b)
    if res == 1:
        return (b)
    end
    return (a)
end

func max{
        range_check_ptr
    }(a: felt, b: felt) -> (min: felt):
    let (res) = sign(a - b)
    if res == 1:
        return (a)
    end
    return (b)
end

# in or on oval check
# x0, y0 oval origin point
# x1, y1 point to check
func in_on_oval{
        range_check_ptr
    }(x0: felt, y0: felt, x1: felt, y1: felt, a: felt, b: felt) -> (res: felt):

    return (TRUE)
    # let x_distance = x1 - x0
    # let y_distance = y1 - y0
    # let (x, _) = unsigned_div_rem(x_distance * x_distance, a * a)
    # let (y, _) = unsigned_div_rem(y_distance * y_distance, b * b)
    # let (sign_) = sign(x + y - 1)
    # if sign_ == 1:
    #     return (FALSE)
    # else:
    #     return (TRUE)
    # end
end