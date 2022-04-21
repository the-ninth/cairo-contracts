%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash_state import (
    hash_init, hash_finalize, hash_update, hash_update_single
)
from starkware.cairo.common.math import assert_not_zero

from starkware.starknet.common.syscalls import get_caller_address, get_block_number

from contracts.random.IRandomConsumer import IRandomConsumer


@storage_var
func request_id_counter() -> (count: felt):
end

# random: felt, caller: felt, block_number: felt
@storage_var
func request_random_res(request_id: felt) -> (res: (felt, felt, felt)):
end

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    return ()
end

@external
func requestRandom{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (request_id: felt):
    let (count) = request_id_counter.read()
    let (caller) = get_caller_address()
    let (block_number) = get_block_number()
    let request_id = count + 1
    let hash_ptr = pedersen_ptr
    with hash_ptr:
        let (hash_state_ptr) = hash_init()
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, request_id)
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, caller)
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, block_number)
        let (res) = hash_finalize(hash_state_ptr)
    end
    let pedersen_ptr = hash_ptr
    
    request_id_counter.write(request_id)
    request_random_res.write(request_id, (res, caller, block_number))
    return (request_id)
end

# workaround for async random number fulfill
@external
func triggerFulfill{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(request_id: felt):
    let (caller) = get_caller_address()
    let (res) = request_random_res.read(request_id)
    with_attr error_message("RandomProducer: request id empty"):
        assert_not_zero(res[2])
    end
    with_attr error_message("RandomProducer: invalid caller"):
        assert caller = res[1]
    end
    # todo: we may need to restrict that the trigger can only run once for every request id
    IRandomConsumer.fulfillRandom(contract_address=caller, request_id=request_id, random=res[0])
    return ()
end

@view
func getRandomRequestRes{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(request_id: felt) -> (random: felt, caller: felt, block_number: felt):
    let (res) = request_random_res.read(request_id)
    return (random=res[0], caller=res[1], block_number=res[2])
end
