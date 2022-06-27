%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call
from starkware.starknet.common.syscalls import get_caller_address

from contracts.proxy.upgradeProxy.library import Proxy

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    implementation_hash : felt
):
    Proxy._set_implementation(implementation_hash)
    return ()
end

@external
func setAdmin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(admin : felt) -> (
    ):
    Proxy.assert_only_admin()
    Proxy._set_admin(admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    implementation_hash : felt
) -> ():
    Proxy.assert_only_admin()
    Proxy._set_implementation(implementation_hash)
    return ()
end

@view
func getImplementation{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    address : felt
):
    let (address : felt) = Proxy.get_implementation()
    return (address=address)
end

@view
func getAdmin{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    address : felt
):
    let (address : felt) = Proxy.get_admin()
    return (address=address)
end

#
# Fallback functions
#

@external
@raw_input
@raw_output
func __default__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    selector : felt, calldata_size : felt, calldata : felt*
) -> (retdata_size : felt, retdata : felt*):
    let (class_hash) = Proxy.get_implementation()

    let (retdata_size : felt, retdata : felt*) = library_call(
        class_hash=class_hash,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata,
    )

    return (retdata_size=retdata_size, retdata=retdata)
end
