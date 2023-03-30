// SPDX-License-Identifier: MIT
// based on OpenZeppelin Contracts for Cairo

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call, library_call_l1_handler
from contracts.proxy.two_step_upgrade.library import TwoStepUpgradeProxy

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation_hash: felt,
    proxy_owner: felt,
    proxy_admin: felt,
    proxy_confirmer: felt,
    calldata_len: felt,
    calldata: felt*,
) {
    TwoStepUpgradeProxy.initializer(implementation_hash, proxy_owner, proxy_admin, proxy_confirmer);
    // initializer selector: 0x2dd76e7ad84dbed81c314ffe5e7a7cacfb8f4836f01af4e913f275f89a3de1a
    library_call(
        class_hash=implementation_hash,
        function_selector=0x2dd76e7ad84dbed81c314ffe5e7a7cacfb8f4836f01af4e913f275f89a3de1a,
        calldata_size=calldata_len,
        calldata=calldata,
    );
    return ();
}

//
// Fallback functions
//

@external
@raw_input
@raw_output
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    selector: felt, calldata_size: felt, calldata: felt*
) -> (retdata_size: felt, retdata: felt*) {
    let (class_hash) = TwoStepUpgradeProxy.get_implementation();

    let (retdata_size: felt, retdata: felt*) = library_call(
        class_hash=class_hash,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata,
    );

    return (retdata_size=retdata_size, retdata=retdata);
}

@l1_handler
@raw_input
func __l1_default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    selector: felt, calldata_size: felt, calldata: felt*
) {
    let (class_hash) = TwoStepUpgradeProxy.get_implementation();

    library_call_l1_handler(
        class_hash=class_hash,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata,
    );

    return ();
}

@view
func get_implementation{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    implementation: felt
) {
    let (implementation) = TwoStepUpgradeProxy.get_implementation();
    return (implementation,);
}
