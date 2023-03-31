%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero

from starkware.starknet.common.syscalls import get_caller_address, get_block_number

from contracts.random.IRandomConsumer import IRandomConsumer

@event
func RequestRandomness(request_id: felt, caller: felt) {
}

struct Request {
    consumer: felt,
    randomness: felt,
    block_number: felt,
}

@storage_var
func RandomProducer_request_id_counter() -> (count: felt) {
}

@storage_var
func RandomProducer_requests(request_id: felt) -> (request: Request) {
}

@storage_var
func RandomProducer_owner() -> (owner: felt) {
}

@storage_var
func RandomProducer_operator() -> (operator: felt) {
}

@storage_var
func RandomProducer_consumers(consumer: felt) -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner, operator) {
    RandomProducer_owner.write(owner);
    RandomProducer_operator.write(operator);
    return ();
}

@external
func requestRandom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    request_id: felt
) {
    let (caller) = get_caller_address();
    let (valid) = RandomProducer_consumers.read(caller);
    with_attr error_message("RandomProducer: invalid consumer") {
        assert valid = TRUE;
    }
    let (count) = RandomProducer_request_id_counter.read();
    let request_id = count + 1;
    RandomProducer_request_id_counter.write(request_id);
    let request = Request(consumer=caller, randomness=0, block_number=0);
    RandomProducer_requests.write(request_id, request);
    return (request_id,);
}

@external
func fulfill{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    request_id: felt, randomness: felt
) {
    assert_only_operator();
    let (request) = RandomProducer_requests.read(request_id);
    with_attr error_message("RandomProducer: request not exsit") {
        assert_not_zero(request.consumer);
    }
    with_attr error_message("RandomProducer: request fulfilled") {
        assert request.block_number = 0;
    }
    let (block_number) = get_block_number();
    let requestUpdated = Request(
        consumer=request.consumer, randomness=randomness, block_number=block_number
    );
    RandomProducer_requests.write(request_id, requestUpdated);
    IRandomConsumer.fulfillRandomness(
        contract_address=request.consumer, request_id=request_id, randomness=randomness
    );
    return ();
}

@external
func setOperator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(operator: felt) {
    assert_only_owner();
    RandomProducer_operator.write(operator);
    return ();
}

@external
func setOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) {
    assert_only_owner();
    RandomProducer_owner.write(owner);
    return ();
}

@external
func setConsumer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consumer: felt, valid: felt
) {
    assert_only_owner();
    RandomProducer_consumers.write(consumer, valid);
    return ();
}

@view
func getRandomnessRequest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    request_id: felt
) -> (request: Request) {
    let (request) = RandomProducer_requests.read(request_id);
    return (request,);
}

func assert_only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (owner) = RandomProducer_owner.read();
    with_attr error_message("RandomProducer: invalid owner") {
        assert caller = owner;
    }
    return ();
}

func assert_only_operator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (operator) = RandomProducer_operator.read();
    with_attr error_message("RandomProducer: invalid operator") {
        assert caller = operator;
    }
    return ();
}
