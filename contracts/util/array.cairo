%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE

# return bool if the elem exist in the array
func felt_in_array{
        range_check_ptr
    }(elem: felt, arr_len: felt, arr: felt*) -> (res: felt):
    if arr_len == 0:
        return (FALSE)
    end
    if elem == arr[0]:
        return (TRUE)
    end
    return felt_in_array(elem, arr_len - 1, arr + 1)
end