// SPDX-License-Identifier: MIT
// add auto id  support for openzeppelin ERC721 Enumerable

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le_felt,
    assert_lt_felt,
)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_lt,
    uint256_eq,
    uint256_check,
)

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable

//
// Storage
//

@storage_var
func ERC721_Enumerable_AutoId_counter() -> (token_id: Uint256) {
}

@storage_var
func ERC721_Enumerable_AutoId_token_uri_len() -> (len: felt) {
}

@storage_var
func ERC721_Enumerable_AutoId_token_uri_by_index(index: felt) -> (res: felt) {
}

func ERC721_Enumerable_AutoId_mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt
) -> (token_id: Uint256) {
    alloc_locals;

    let (last_token_id: Uint256) = ERC721_Enumerable_AutoId_counter.read();
    let (token_id: Uint256, is_overflow) = uint256_add(last_token_id, Uint256(low=1, high=0));
    assert is_overflow = 0;
    ERC721_Enumerable_AutoId_counter.write(token_id);
    ERC721Enumerable._mint(to, token_id);
    return (token_id,);
}

func ERC721_Enumerable_AutoId_mint_multi{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(to_list_len: felt, to_list: felt*) -> (token_ids_len: felt, token_ids: Uint256*) {
    alloc_locals;

    assert_lt_felt(0, to_list_len);
    let (token_ids: Uint256*) = alloc();
    _mint_multi(to_list_len, to_list, token_ids);
    return (to_list_len, token_ids);
}

func ERC721_Enumerable_AutoId_tokenURI{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    let (owner) = ERC721.owner_of(tokenId);
    with_attr error_message("query for nonexistent token") {
        assert_not_zero(owner);
    }
    let (len) = ERC721_Enumerable_AutoId_token_uri_len.read();
    let (tokenURI: felt*) = alloc();
    let (tokenURI_len, tokenURI) = _get_tokenURI(0, len, tokenURI);
    return (tokenURI_len, tokenURI);
}

func ERC721_Enumerable_AutoId_set_tokenURI{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(tokenURI_len: felt, tokenURI: felt*) -> () {
    ERC721_Enumerable_AutoId_token_uri_len.write(tokenURI_len);
    _set_tokenURI(0, tokenURI_len, tokenURI);
    return ();
}

func _get_tokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: felt, len: felt, tokenURI: felt*
) -> (tokenURI_len: felt, tokenURI: felt*) {
    if (index == len) {
        return (index, tokenURI);
    }
    let (uri) = ERC721_Enumerable_AutoId_token_uri_by_index.read(index);
    assert tokenURI[index] = uri;
    return _get_tokenURI(index + 1, len, tokenURI);
}

func _set_tokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: felt, len: felt, tokenURI: felt*
) -> () {
    if (index == len) {
        return ();
    }
    ERC721_Enumerable_AutoId_token_uri_by_index.write(index, tokenURI[index]);
    _set_tokenURI(index + 1, len, tokenURI);
    return ();
}

func _mint_multi{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to_list_len: felt, to_list: felt*, token_ids: Uint256*
) {
    if (to_list_len == 0) {
        return ();
    }
    let (tokenId) = ERC721_Enumerable_AutoId_mint(to_list[0]);
    assert token_ids[0] = tokenId;
    _mint_multi(to_list_len - 1, to_list + 1, token_ids + 2);
    return ();
}
