%lang starknet

from starkware.cairo.common.math import sign

func min{
        range_check_ptr
    }(a: felt, b: felt) -> (min: felt):
    let (res) = sign(a - b)
    if res == 1:
        return (a)
    end
    return (b)
end