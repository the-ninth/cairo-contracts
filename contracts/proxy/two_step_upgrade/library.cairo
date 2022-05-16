%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

#
# Events
#

@event
func Upgraded(implementation: felt):
end

#
# Storage variables
#

@storage_var
func TwoStepUpgradeProxy_implementation_address() -> (implementation_address: felt):
end

@storage_var
func TwoStepUpgradeProxy_confirming_implementation_address() -> (confirming_implementation_address: felt):
end

@storage_var
func TwoStepUpgradeProxy_owner() -> (proxy_owner: felt):
end

@storage_var
func TwoStepUpgradeProxy_admin() -> (proxy_admin: felt):
end

@storage_var
func TwoStepUpgradeProxy_confirmer() -> (proxy_confirmer: felt):
end

@storage_var
func TwoStepUpgradeProxy_initialized() -> (initialized: felt):
end

#
# Initializer
#

namespace TwoStepUpgradeProxy:

    #
    # Constructor
    #

    func constructor{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }():
        let (initialized) = TwoStepUpgradeProxy_initialized.read()
        with_attr error_message("Proxy: contract already initialized"):
            assert initialized = FALSE
        end

        TwoStepUpgradeProxy_initialized.write(TRUE)
        # TwoStepUpgradeProxy_owner.write(proxy_owner)
        # TwoStepUpgradeProxy_admin.write(proxy_admin)
        # TwoStepUpgradeProxy_confirmer.write(proxy_confirmer)
        return ()
    end

    #
    # Upgrades
    #

    func _set_implementation{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(new_implementation: felt):
        TwoStepUpgradeProxy_implementation_address.write(new_implementation)
        Upgraded.emit(new_implementation)
        return ()
    end

    func _upgrade_implemention{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(new_implementation: felt):
        TwoStepUpgradeProxy_confirming_implementation_address.write(new_implementation)
        return ()
    end

    func _confirm_implementation{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(new_implementation: felt):
        let (confirming_address) = TwoStepUpgradeProxy_confirming_implementation_address.read()
        with_attr error_message("invalid confirming address"):
            assert confirming_address = new_implementation
        end
        TwoStepUpgradeProxy_implementation_address.write(new_implementation)
        Upgraded.emit(new_implementation)
        return ()
    end

    #
    # Setters
    #

    func _set_owner{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(new_owner: felt):
        TwoStepUpgradeProxy_owner.write(new_owner)
        return ()
    end

    func _set_admin{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(new_admin: felt):
        TwoStepUpgradeProxy_admin.write(new_admin)
        return ()
    end

    func _set_confirmer{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(new_confirmer: felt):
        TwoStepUpgradeProxy_confirmer.write(new_confirmer)
        return ()
    end

    #
    # Getters
    #

    func get_implementation{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }() -> (implementation: felt):
        let (implementation) = TwoStepUpgradeProxy_implementation_address.read()
        return (implementation)
    end

    func get_owner{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }() -> (owner: felt):
        let (owner) = TwoStepUpgradeProxy_owner.read()
        return (owner)
    end

    func get_admin{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }() -> (admin: felt):
        let (admin) = TwoStepUpgradeProxy_admin.read()
        return (admin)
    end

    func get_confirmer{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }() -> (confirmer: felt):
        let (confirmer) = TwoStepUpgradeProxy_confirmer.read()
        return (confirmer)
    end

    #
    # Guards
    #

    func assert_only_owner{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }():
        let (caller) = get_caller_address()
        let (owner) = TwoStepUpgradeProxy_owner.read()
        with_attr error_message("Proxy: caller is not owner"):
            assert owner = caller
        end
        return ()
    end

    func assert_only_admin{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }():
        let (caller) = get_caller_address()
        let (admin) = TwoStepUpgradeProxy_admin.read()
        with_attr error_message("Proxy: caller is not admin"):
            assert admin = caller
        end
        return ()
    end

    func assert_only_confirmer{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }():
        let (caller) = get_caller_address()
        let (confirmer) = TwoStepUpgradeProxy_confirmer.read()
        with_attr error_message("Proxy: caller is not confirmer"):
            assert confirmer = caller
        end
        return ()
    end

end