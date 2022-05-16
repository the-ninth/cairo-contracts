%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import delegate_l1_handler, delegate_call
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.upgrades.library import (
    Proxy_implementation_address,
    Proxy_set_implementation,
    Proxy_only_admin,
    Proxy_get_admin,
    Proxy_set_admin,
    Proxy_get_implementation,
)

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    implementation_address : felt
):
    Proxy_set_implementation(implementation_address)
    return ()
end

@external
func setAdmin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(admin : felt) -> (
    ):
    Proxy_only_admin()
    Proxy_set_admin(admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    implementation_address : felt
) -> ():
    Proxy_only_admin()
    Proxy_set_implementation(implementation_address)
    return ()
end

@view
func getImplementation{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    address : felt
):
    let (address : felt) = Proxy_get_implementation()
    return (address=address)
end

@view
func getAdmin{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    address : felt
):
    let (address : felt) = Proxy_get_admin()
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
    let (address) = Proxy_implementation_address.read()

    let (retdata_size : felt, retdata : felt*) = delegate_call(
        contract_address=address,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata,
    )

    return (retdata_size=retdata_size, retdata=retdata)
end
