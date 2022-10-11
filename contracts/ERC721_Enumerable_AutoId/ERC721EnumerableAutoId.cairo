// Farmer contract of The Ninth Game, based on openzepplin

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc721.library import ERC721

from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.introspection.erc165.library import ERC165

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721

from contracts.ERC721_Enumerable_AutoId.library import ERC721_Enumerable_AutoId

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, owner: felt
) {
    Ownable.initializer(owner);
    ERC721.initializer(name, symbol);
    ERC721Enumerable.initializer();
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
    return (totalSupply,);
}

@view
func tokenByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_by_index(index);
    return (tokenId,);
}

@view
func tokenOfOwnerByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_of_owner_by_index(owner, index);
    return (tokenId,);
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
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved=isApproved);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    let (tokenURI_len, tokenURI) = ERC721_Enumerable_AutoId.tokenURI(tokenId);
    return (tokenURI_len, tokenURI);
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
    _from: felt, to: felt, tokenId: Uint256
) {
    ERC721Enumerable.transfer_from(_from, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721Enumerable.safe_transfer_from(_from, to, tokenId, data_len, data);
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    ERC721.assert_only_token_owner(tokenId);
    ERC721Enumerable._burn(tokenId);
    return ();
}

@external
func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenURI_len: felt, tokenURI: felt*
) {
    Ownable.assert_only_owner();
    ERC721_Enumerable_AutoId.set_tokenURI(tokenURI_len, tokenURI);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(to: felt) -> (
    tokenId: Uint256
) {
    Ownable.assert_only_owner();
    let (tokenId) = ERC721_Enumerable_AutoId.mint(to);
    return (tokenId,);
}

@external
func mintMulti{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to_list_len: felt, to_list: felt*
) -> (token_ids_len: felt, token_ids: Uint256*) {
    Ownable.assert_only_owner();
    let (token_ids_len, token_ids) = ERC721_Enumerable_AutoId.mint_multi(to_list_len, to_list);
    return (token_ids_len, token_ids);
}

@external
func setOwner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(owner: felt) {
    Ownable.assert_only_owner();
    Ownable.transfer_ownership(owner);
    return ();
}

//
// internals
//

func _mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(to: felt) -> (
    tokenId: Uint256
) {
    let (tokenId) = ERC721_Enumerable_AutoId.mint(to);
    return (tokenId,);
}
