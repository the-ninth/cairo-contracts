// Koma contract of The Ninth Game, based on openzepplin

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.upgrades.library import Proxy

from openzeppelin.token.erc721.library import ERC721

from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable

from openzeppelin.introspection.erc165.library import ERC165

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import ROLE_KOMA_MINTER, ROLE_ADMIN
from contracts.pvp.Koma.library import Koma, KomaCreature, KomaLibrary, Koma_access_contract

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    return ();
}

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    access_contract: felt, admin: felt
) {
    ERC721.initializer('Ninth Koma', 'NKOMA');
    ERC721Enumerable.initializer();
    Koma_access_contract.write(access_contract);

    Proxy.initializer(admin);
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
) -> (token_uri_len: felt, token_uri: felt*) {
    let (token_uri_len, token_uri) = KomaLibrary.get_token_uri(tokenId);
    return (token_uri_len, token_uri);
}

@view
func getKoma{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (koma: Koma) {
    let (koma) = KomaLibrary.get_koma(token_id);
    return (koma,);
}

@view
func getKomas{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, index: Uint256, length: felt
) -> (komas_len: felt, komas: Koma*) {
    let (komas_len, komas) = KomaLibrary.get_komas(account, index, length);
    return (komas_len, komas);
}

@view
func getKomaCreature{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    koma_creature_id: felt
) -> (koma_creature: KomaCreature) {
    let (koma_creature) = KomaLibrary.get_koma_creature(koma_creature_id);
    return (koma_creature,);
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
func setKomaCreature{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    koma_creature_id: felt, koma_creature: KomaCreature
) -> () {
    onlyRole(ROLE_ADMIN);
    KomaLibrary.set_koma_creature(koma_creature_id, koma_creature);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, koma_creature_id: felt
) -> (token_id: Uint256) {
    onlyRole(ROLE_KOMA_MINTER);
    let (token_id) = KomaLibrary.mint(to, koma_creature_id);
    return (token_id,);
}

@external
func faucetClaim{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    let (caller) = get_caller_address();
    KomaLibrary.faucet_claim(caller);
    return ();
}

@external
func mintMulti{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, creature_ids_len: felt, creature_ids: felt*
) {
    onlyRole(ROLE_KOMA_MINTER);
    KomaLibrary.mint_multi(to, creature_ids_len, creature_ids);
    return ();
}

@external
func setKomaCreatureUri{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    koma_creature_id: felt, token_uri_len: felt, token_uri: felt*
) {
    onlyRole(ROLE_ADMIN);
    KomaLibrary.set_koma_creature_uri(koma_creature_id, token_uri_len, token_uri);
    return ();
}

func onlyRole{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(role: felt) -> () {
    let (access_contract) = Koma_access_contract.read();
    let (caller) = get_caller_address();
    IAccessControl.onlyRole(contract_address=access_contract, role=role, account=caller);
    return ();
}
