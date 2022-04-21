# library for random number

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_state import (
    hash_init, hash_finalize, hash_update, hash_update_single
)
from starkware.cairo.common.math import unsigned_div_rem, split_felt

func get_random_number{
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(seed: felt, step: felt, mod: felt) -> (res: felt):
    let hash_ptr = pedersen_ptr
    with hash_ptr:
        let (hash_state_ptr) = hash_init()
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, seed)
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, step)
        let (res) = hash_finalize(hash_state_ptr)
        let pedersen_ptr = hash_ptr
        let (low, _) = split_felt(res)
        let (_, r) = unsigned_div_rem(low, mod)
        return (res = r)
    end
end

func get_random_number_and_seed{
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(seed: felt, mod: felt) -> (res: felt, next_seed: felt):
    let hash_ptr = pedersen_ptr
    with hash_ptr:
        let (hash_state_ptr) = hash_init()
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, seed)
        let (res) = hash_finalize(hash_state_ptr)
        let pedersen_ptr = hash_ptr
        let (low, _) = split_felt(res)
        let (_, r) = unsigned_div_rem(low, mod)
        let next_seed = seed + r
        return (res = r, next_seed = next_seed)
    end
end
