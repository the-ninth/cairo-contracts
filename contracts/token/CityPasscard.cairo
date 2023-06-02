// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.6.1 (token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo)

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add

from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.utils.constants.library import DEFAULT_ADMIN_ROLE
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable

from contracts.proxy.two_step_upgrade.library import TwoStepUpgradeProxy

const RoleMinter = 0x14a29a7a52126dd9ed87a315096a38eeae324f6f3ca318bc444b62a9ed9375a;

@storage_var
func CityPasscard_city_uri_len(type: felt) -> (uri_len: felt) {
}

@storage_var
func CityPasscard_city_uri(type, index: felt) -> (res: felt) {
}

@storage_var
func CityPasscard_token_counter() -> (count: Uint256) {
}

@storage_var
func CityPasscard_token_city(token_id: Uint256) -> (type: felt) {
}

//
// Constructor
//
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, owner: felt
) {
    TwoStepUpgradeProxy.initialized();
    ERC721.initializer(name, symbol);
    ERC721Enumerable.initializer();
    AccessControl.initializer();
    AccessControl._grant_role(DEFAULT_ADMIN_ROLE, owner);
    return ();
}

//
// Getters
//

@view
func totalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    return (totalSupply=totalSupply);
}

@view
func tokenByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_by_index(index);
    return (tokenId=tokenId);
}

@view
func tokenOfOwnerByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_of_owner_by_index(owner, index);
    return (tokenId=tokenId);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC721.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC721.symbol();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    return ERC721.balance_of(owner);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    return ERC721.owner_of(tokenId);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    return ERC721.get_approved(tokenId);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (approved: felt) {
    return ERC721.is_approved_for_all(owner, operator);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (uri_len: felt, uri: felt*) {
    alloc_locals;
    let (uri: felt*) = alloc();
    let res = ERC721._exists(tokenId);
    if (res == FALSE) {
        return (0, uri);
    }
    let (type) = CityPasscard_token_city.read(tokenId);
    let (uri_len) = CityPasscard_city_uri_len.read(type);
    let (uri_len, uri) = _get_city_uri(type, 0, uri_len, uri);
    return (uri_len, uri);
}

@view
func getPasscardCity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (city: felt) {
    let res = ERC721._exists(tokenId);
    with_attr error_message("token not exists") {
        assert res = TRUE;
    }
    let (city) = CityPasscard_token_city.read(tokenId);
    return (city,);
}

@view
func getCityUri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(type: felt) -> (
    uri_len: felt, uri: felt*
) {
    alloc_locals;
    let (uri: felt*) = alloc();
    let (uri_len) = CityPasscard_city_uri_len.read(type);
    let (uri_len, uri) = _get_city_uri(type, 0, uri_len, uri);
    return (uri_len, uri);
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
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721Enumerable.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(to: felt, city: felt) {
    AccessControl.assert_only_role(RoleMinter);
    let (count) = CityPasscard_token_counter.read();
    let (token_id, _) = uint256_add(count, Uint256(1, 0));
    CityPasscard_token_counter.write(token_id);
    CityPasscard_token_city.write(token_id, city);
    ERC721Enumerable._mint(to, token_id);
    return ();
}

@external
func setCityUri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    type: felt, uri_len: felt, uri: felt*
) {
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);
    CityPasscard_city_uri_len.write(type, uri_len);
    _set_city_uri(type, 0, uri_len, uri);
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

func _get_city_uri{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    type: felt, index: felt, len: felt, token_uri: felt*
) -> (token_uri_len: felt, token_uri: felt*) {
    if (index == len) {
        return (index, token_uri);
    }

    let (uri) = CityPasscard_city_uri.read(type, index);
    assert token_uri[index] = uri;
    return _get_city_uri(type, index + 1, len, token_uri);
}

func _set_city_uri{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    type: felt, index: felt, len: felt, token_uri: felt*
) -> () {
    if (index == len) {
        return ();
    }

    CityPasscard_city_uri.write(type, index, token_uri[index]);
    _set_city_uri(type, index + 1, len, token_uri);
    return ();
}
