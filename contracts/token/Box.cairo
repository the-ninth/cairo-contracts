// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.6.1 (token/erc1155/presets/ERC1155MintableBurnable.cairo)

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.utils.constants.library import DEFAULT_ADMIN_ROLE
from openzeppelin.token.erc1155.library import ERC1155
from openzeppelin.introspection.erc165.library import ERC165

from contracts.proxy.two_step_upgrade.library import TwoStepUpgradeProxy

const RoleMinter = 0x14a29a7a52126dd9ed87a315096a38eeae324f6f3ca318bc444b62a9ed9375a;

@storage_var
func Box_token_uri_len(token_id: Uint256) -> (uri_len: felt) {
}

@storage_var
func Box_token_uri(token_id: Uint256, index: felt) -> (res: felt) {
}

//
// Constructor
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) {
    TwoStepUpgradeProxy.initialized();
    AccessControl.initializer();
    AccessControl._grant_role(DEFAULT_ADMIN_ROLE, owner);
    return ();
}

//
// Getters
//

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@view
func uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id: Uint256) -> (
    uri_len: felt, uri: felt*
) {
    alloc_locals;
    let (uri: felt*) = alloc();
    let (uri_len) = Box_token_uri_len.read(id);
    let (uri_len, uri) = _get_token_uri(id, 0, uri_len, uri);
    return (uri_len, uri);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, id: Uint256
) -> (balance: Uint256) {
    return ERC1155.balance_of(account, id);
}

@view
func balanceOfBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    accounts_len: felt, accounts: felt*, ids_len: felt, ids: Uint256*
) -> (balances_len: felt, balances: Uint256*) {
    return ERC1155.balance_of_batch(accounts_len, accounts, ids_len, ids);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, operator: felt
) -> (approved: felt) {
    return ERC1155.is_approved_for_all(account, operator);
}

@view
func hasRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, user: felt
) -> (has_role: felt) {
    return AccessControl.has_role(role, user);
}

@view
func getRoleAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(role: felt) -> (
    admin: felt
) {
    return AccessControl.get_role_admin(role);
}

@view
func getUpgradeOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    owner: felt
) {
    let (owner) = TwoStepUpgradeProxy.get_owner();
    return (owner,);
}

@view
func getUpgradeAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    admin: felt
) {
    let (admin) = TwoStepUpgradeProxy.get_admin();
    return (admin,);
}

@view
func getUpgradeConfirmer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    confirmer: felt
) {
    let (confirmer) = TwoStepUpgradeProxy.get_confirmer();
    return (confirmer,);
}

//
// Externals
//

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC1155.set_approval_for_all(operator, approved);
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, value: Uint256, data_len: felt, data: felt*
) {
    ERC1155.safe_transfer_from(from_, to, id, value, data_len, data);
    return ();
}

@external
func safeBatchTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt,
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    values_len: felt,
    values: Uint256*,
    data_len: felt,
    data: felt*,
) {
    ERC1155.safe_batch_transfer_from(from_, to, ids_len, ids, values_len, values, data_len, data);
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, id: Uint256, value: Uint256, data_len: felt, data: felt*
) {
    AccessControl.assert_only_role(RoleMinter);
    ERC1155._mint(to, id, value, data_len, data);
    return ();
}

@external
func mintBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    values_len: felt,
    values: Uint256*,
    data_len: felt,
    data: felt*,
) {
    AccessControl.assert_only_role(RoleMinter);
    ERC1155._mint_batch(to, ids_len, ids, values_len, values, data_len, data);
    return ();
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, id: Uint256, value: Uint256
) {
    ERC1155.assert_owner_or_approved(owner=from_);
    ERC1155._burn(from_, id, value);
    return ();
}

@external
func burnBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, ids_len: felt, ids: Uint256*, values_len: felt, values: Uint256*
) {
    ERC1155.assert_owner_or_approved(owner=from_);
    ERC1155._burn_batch(from_, ids_len, ids, values_len, values);
    return ();
}

@external
func setTokenUri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, uri_len: felt, uri: felt*
) {
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);
    Box_token_uri_len.write(token_id, uri_len);
    _set_token_uri(token_id, 0, uri_len, uri);
    return ();
}

@external
func grantRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, user: felt
) {
    AccessControl.grant_role(role, user);
    return ();
}

@external
func revokeRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, user: felt
) {
    AccessControl.revoke_role(role, user);
    return ();
}

@external
func renounceRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, user: felt
) {
    AccessControl.renounce_role(role, user);
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation_address: felt
) {
    TwoStepUpgradeProxy.assert_only_admin();
    TwoStepUpgradeProxy._upgrade_implemention(implementation_address);
    return ();
}

@external
func confirmUpgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation_address: felt
) {
    TwoStepUpgradeProxy.assert_only_confirmer();
    TwoStepUpgradeProxy._confirm_implementation(implementation_address);
    return ();
}

@external
func setUpgradeOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) {
    TwoStepUpgradeProxy.assert_only_owner();
    TwoStepUpgradeProxy._set_owner(owner);
    return ();
}

@external
func setUpgradeAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(admin: felt) {
    TwoStepUpgradeProxy.assert_only_owner();
    TwoStepUpgradeProxy._set_admin(admin);
    return ();
}

@external
func setUpgradeConfirmer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    confirmer: felt
) {
    TwoStepUpgradeProxy.assert_only_owner();
    TwoStepUpgradeProxy._set_confirmer(confirmer);
    return ();
}

func _get_token_uri{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    token_id: Uint256, index: felt, len: felt, token_uri: felt*
) -> (token_uri_len: felt, token_uri: felt*) {
    if (index == len) {
        return (index, token_uri);
    }

    let (uri) = Box_token_uri.read(token_id, index);
    assert token_uri[index] = uri;
    return _get_token_uri(token_id, index + 1, len, token_uri);
}

func _set_token_uri{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    token_id: Uint256, index: felt, len: felt, token_uri: felt*
) -> () {
    if (index == len) {
        return ();
    }

    Box_token_uri.write(token_id, index, token_uri[index]);
    _set_token_uri(token_id, index + 1, len, token_uri);
    return ();
}
