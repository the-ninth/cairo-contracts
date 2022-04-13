# library for random number

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_state import (
    hash_init, hash_finalize, hash_update, hash_update_single
)
from starkware.cairo.common.math import unsigned_div_rem

func get_random_number{
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(seed: felt, step: felt, mod: felt) -> (res):
    let hash_ptr = pedersen_ptr
    with hash_ptr:
        let (hash_state_ptr) = hash_init()
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, seed)
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, step)
        let (res) = hash_finalize(hash_state_ptr)
        let pedersen_ptr = hash_ptr
        let (_, r) = unsigned_div_rem(res, mod)
        return (res = r)
    end
end