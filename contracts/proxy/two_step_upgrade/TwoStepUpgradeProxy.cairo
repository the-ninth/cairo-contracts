# SPDX-License-Identifier: MIT
# based on OpenZeppelin Contracts for Cairo

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import delegate_l1_handler, delegate_call
from contracts.proxy.two_step_upgrade.library import TwoStepUpgradeProxy

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        implementation_address: felt,
        owner: felt,
        admin: felt,
        confirmer: felt
    ):
    TwoStepUpgradeProxy._set_implementation(implementation_address)
    TwoStepUpgradeProxy._set_owner(owner)
    TwoStepUpgradeProxy._set_admin(admin)
    TwoStepUpgradeProxy._set_confirmer(confirmer)
    return ()
end

@view
func implementation{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (implementation: felt):
    let (implementation_address) = TwoStepUpgradeProxy.get_implementation()
    return (implementation_address)
end

@view
func getOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (owner: felt):
    let (owner) = TwoStepUpgradeProxy.get_owner()
    return (owner)
end

@view
func getAdmin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (admin: felt):
    let (admin) = TwoStepUpgradeProxy.get_admin()
    return (admin)
end

@view
func getConfirmer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (confirmer: felt):
    let (confirmer) = TwoStepUpgradeProxy.get_confirmer()
    return (confirmer)
end

@external
func upgrade{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(implementation_address: felt):
    TwoStepUpgradeProxy.assert_only_admin()
    TwoStepUpgradeProxy._upgrade_implemention(implementation_address)
    return ()
end

@external
func confirm{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(implementation_address: felt):
    TwoStepUpgradeProxy.assert_only_confirmer()
    TwoStepUpgradeProxy._confirm_implementation(implementation_address)
    return ()
end

@external
func setOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt):
    TwoStepUpgradeProxy.assert_only_owner()
    TwoStepUpgradeProxy._set_owner(owner)
    return ()
end

@external
func setAdmin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(admin: felt):
    TwoStepUpgradeProxy.assert_only_owner()
    TwoStepUpgradeProxy._set_admin(admin)
    return ()
end

@external
func setConfirmer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(confirmer: felt):
    TwoStepUpgradeProxy.assert_only_owner()
    TwoStepUpgradeProxy._set_confirmer(confirmer)
    return ()
end

#
# Fallback functions
#

@external
@raw_input
@raw_output
func __default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ) -> (
        retdata_size: felt,
        retdata: felt*
    ):
    let (address) = TwoStepUpgradeProxy.get_implementation()

    let (retdata_size: felt, retdata: felt*) = delegate_call(
        contract_address=address,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata
    )

    return (retdata_size=retdata_size, retdata=retdata)
end

@l1_handler
@raw_input
func __l1_default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ):
    let (address) = TwoStepUpgradeProxy.get_implementation()

    delegate_l1_handler(
        contract_address=address,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata
    )

    return ()
end