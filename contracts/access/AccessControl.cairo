%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.access.library import AccessControl, ROLE_SUPER_ADMIN

@storage_var
func initialized() -> (res: felt) {
}

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    super_admin: felt
) {
    let (inited) = initialized.read();
    with_attr error_message("contract initialized") {
        assert inited = FALSE;
    }
    initialized.write(TRUE);
    AccessControl.grantRole(ROLE_SUPER_ADMIN, super_admin);
    return ();
}

@storage_var
func AccessControl_contract_address(contract_name: felt) -> (contract_address: felt) {
}

@view
func hasRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, account: felt
) -> (res: felt) {
    let (res) = AccessControl.hasRole(role, account);
    return (res,);
}

@view
func getContractAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_name: felt
) -> (contract_address: felt) {
    let (addr) = AccessControl_contract_address.read(contract_name);
    return (addr,);
}

@external
func setContractAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_name: felt, contract_address: felt
) {
    AccessControl.only_super_admin();
    AccessControl_contract_address.write(contract_name, contract_address);
    return ();
}

@external
func grantRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, account: felt
) {
    AccessControl.only_super_admin();
    AccessControl.grantRole(role, account);
    return ();
}

@external
func onlyRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, account: felt
) {
    let (res) = AccessControl.hasRole(role, account);
    assert res = 1;
    return ();
}
