// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_mul,
    uint256_add,
    uint256_unsigned_div_rem,
    uint256_lt,
)
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_block_timestamp,
)

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from contracts.komaNFT.library import KomaType
from openzeppelin.upgrades.library import Proxy

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) {
    ERC721.initializer('Ninth Koma', 'NKOMA');
    ERC721Enumerable.initializer();
    Ownable.initializer(owner);
    Proxy.initializer(owner);
    return ();
}

@external
func setAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(admin: felt) -> () {
    Proxy.assert_only_admin();
    Proxy._set_admin(admin);
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

@view
func getImplementationHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    implementation: felt
) {
    return Proxy.get_implementation_hash();
}

@view
func getAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (admin: felt) {
    return Proxy.get_admin();
}

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
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

@view
func is_open{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (is_open: felt) {
    return KomaType.is_open();
}

@view
func is_operator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (result: felt) {
    return KomaType.is_operator(account);
}

@view
func wl_status{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    result: felt
) {
    return KomaType.wl_status(account);
}

@view
func mint_limit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    result: felt
) {
    return KomaType.mint_limit();
}

@view
func get_implementation_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    implementation: felt
) {
    return Proxy.get_implementation_hash();
}

@view
func get_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (admin: felt) {
    return Proxy.get_admin();
}

@view
func get_user_koma_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user: felt
) -> (komas_len: felt, komas: felt*) {
    alloc_locals;
    let (balance: Uint256) = ERC721.balance_of(user);
    let (local komas: felt*) = alloc();
    _get_user_komas(user, komas, balance.low);
    return (balance.low, komas);
}

@view
func get_airdrop_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt
) -> (koma_creature_id: felt) {
    alloc_locals;
    return KomaType.get_airdrop_type(index);
}

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
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(koma_creature_id: felt) {
    alloc_locals;
    KomaType.assert_mintable();
    KomaType.assert_wl();
    let (caller) = get_caller_address();
    let (balance) = ERC721.balance_of(caller);
    let (limit) = KomaType.mint_limit();
    let (is_lt) = uint256_lt(balance, Uint256(limit, 0));
    with_attr error_message("mint:only one") {
        assert is_lt = 1;
    }
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    let (tokenId_, _) = uint256_mul(totalSupply, Uint256(10000000, 0));
    let (tokenId, _) = uint256_add(tokenId_, Uint256(koma_creature_id, 0));
    ERC721Enumerable._mint(caller, tokenId);
    return ();
}

@external
func airdrop{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, koma_creature_id: felt
) {
    KomaType.assert_op();
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    let (tokenId_, _) = uint256_mul(totalSupply, Uint256(10000000, 0));
    let (tokenId, _) = uint256_add(tokenId_, Uint256(koma_creature_id, 0));
    ERC721Enumerable._mint(to, tokenId);
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
    Ownable.assert_only_owner();
    ERC721._set_token_uri(tokenId, tokenURI);
    return ();
}

@external
func setKomaURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    koma_creature_id: felt, token_uri: felt
) {
    Ownable.assert_only_owner();
    KomaType.set_koma_type_URI(koma_creature_id, token_uri);
    return ();
}

@external
func setTokenBaseURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    base_uri_len: felt, base_uri: felt*
) {
    Ownable.assert_only_owner();
    KomaType.set_koma_type_base_URI(base_uri_len, base_uri);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

@external
func set_wl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    target_status: felt, accounts_len: felt, accounts: felt*
) -> () {
    KomaType.assert_op();
    KomaType.set_wl(target_status, accounts_len, accounts);
    return ();
}

@external
func set_mint_limit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(len: felt) -> (
    ) {
    KomaType.assert_op();
    KomaType.set_mint_limit(len);
    return ();
}

@external
func add_wl_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    accounts_len: felt, accounts: felt*
) -> () {
    KomaType.assert_op();
    _add_wl_mint_loop(accounts, accounts_len);
    return ();
}

@external
func set_open{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    target_status: felt
) -> () {
    Ownable.assert_only_owner();
    KomaType.set_open(target_status);
    return ();
}

@external
func set_operator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, target_status: felt
) -> () {
    Ownable.assert_only_owner();
    KomaType.set_op(target_status, account);
    return ();
}

@external
func add_airdrop_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt, koma_creature_id: felt
) -> () {
    KomaType.assert_op();
    KomaType.add_airdrop_type(index, koma_creature_id);
    return ();
}

func _get_user_komas{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user: felt, komas: felt*, left
) -> () {
    alloc_locals;
    if (left == 0) {
        return ();
    }
    let (tokenId: Uint256) = ERC721Enumerable.token_of_owner_by_index(user, Uint256(left - 1, 0));
    let (_, remainder) = uint256_unsigned_div_rem(tokenId, Uint256(10000000, 0));
    assert [komas] = remainder.low;
    _get_user_komas(user, komas=komas + 1, left=left - 1);
    return ();
}

func _add_wl_mint_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    accounts: felt*, left
) -> () {
    alloc_locals;
    if (left == 0) {
        return ();
    }
    let account = accounts[0];
    KomaType.set_wl_single(1, account);
    let (block_timestamp) = get_block_timestamp();
    let (koma_creature_id) = KomaType.get_airdrop_type_num(block_timestamp + left);
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    let (tokenId_, _) = uint256_mul(totalSupply, Uint256(10000000, 0));
    let (tokenId, _) = uint256_add(tokenId_, Uint256(koma_creature_id, 0));
    ERC721Enumerable._mint(account, tokenId);
    _add_wl_mint_loop(accounts + 1, left - 1);
    return ();
}
