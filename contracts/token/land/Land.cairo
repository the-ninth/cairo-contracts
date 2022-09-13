// Land contract of The Ninth Game, based on openzepplin

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc721.library import ERC721

from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable

from openzeppelin.introspection.erc165.library import ERC165

from openzeppelin.token.erc20.IERC20 import IERC20

from contracts.token.land.library_building import Land_build, Land, Land_getLand

from contracts.token.interfaces.IFarmer import IFarmer

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import (
    ROLE_ADMIN,
    ROLE_LAND_MINTER,
    NINTH_CONTRACT,
    NOAH_CONTRACT,
    FARMER_CONTRACT,
)

//
// Storage
//

@storage_var
func Land_access_contract() -> (access_contract: felt) {
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    access_contract: felt
) {
    ERC721.initializer('Ninth Land', 'NLAND');
    ERC721Enumerable.initializer();
    Land_access_contract.write(access_contract);
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
) -> (tokenURI: felt) {
    let (tokenURI: felt) = ERC721.token_uri(tokenId);
    return (tokenURI=tokenURI);
}

@view
func getLand{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    land: Land
) {
    let (land) = Land_getLand(tokenId);
    return (land,);
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
    tokenId: Uint256, tokenURI: felt
) {
    let (access_contract) = Land_access_contract.read();
    let (caller) = get_caller_address();
    IAccessControl.onlyRole(contract_address=access_contract, role=ROLE_ADMIN, account=caller);
    ERC721._set_token_uri(tokenId, tokenURI);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    let (access_contract) = Land_access_contract.read();
    let (caller) = get_caller_address();
    IAccessControl.onlyRole(
        contract_address=access_contract, role=ROLE_LAND_MINTER, account=caller
    );
    _mint(to, tokenId);
    return ();
}

// pay NINTH to buy land
@external
func buyLand{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    // let (amount) = Uint256(low=1000000000000000000000, high=0)
    let (caller) = get_caller_address();
    let (self) = get_contract_address();
    let (access_contract) = Land_access_contract.read();
    let (ninth_contract) = IAccessControl.getContractAddress(
        contract_address=access_contract, contract_name=NINTH_CONTRACT
    );
    let (res) = IERC20.transferFrom(
        contract_address=ninth_contract,
        sender=caller,
        recipient=self,
        amount=Uint256(low=1000000000000000000000, high=0),
    );
    assert res = 1;
    _mint(caller, tokenId);
    return ();
}

// pay noah to build
@external
func build{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, buildingType: felt
) {
    ERC721.assert_only_token_owner(tokenId);
    // let (amount: Uint256) = Uint256(low=1000000000000000000000, high=0)
    let (caller) = get_caller_address();
    let (self) = get_contract_address();
    let (access_contract) = Land_access_contract.read();
    let (noah_contract) = IAccessControl.getContractAddress(
        contract_address=access_contract, contract_name=NOAH_CONTRACT
    );
    let (res) = IERC20.transferFrom(
        contract_address=noah_contract,
        sender=caller,
        recipient=self,
        amount=Uint256(low=1000000000000000000000, high=0),
    );
    assert res = 1;

    Land_build(tokenId, buildingType);
    return ();
}

//
// internals
//

func _mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721Enumerable._mint(to, tokenId);
    // mint a farmer, assign to the land contract
    // todo: record the farmers on a land
    let (access_contract) = Land_access_contract.read();
    let (farmer_contract) = IAccessControl.getContractAddress(
        contract_address=access_contract, contract_name=FARMER_CONTRACT
    );
    let (land_contract) = get_contract_address();
    let (farmer_token_id) = IFarmer.mint(contract_address=farmer_contract, to=land_contract);
    return ();
}
