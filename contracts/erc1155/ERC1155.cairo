%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.uint256 import Uint256

from starkware.starknet.common.syscalls import get_caller_address

from contracts.erc1155.library import ERC1155

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    return ();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, id: felt
) -> (balance: Uint256) {
    let (balance) = ERC1155.balanceOf(account, id);
    return (balance,);
}

@view
func balanceOfBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    accounts_len: felt, accounts: felt*, ids_len: felt, ids: felt*
) -> (amounts_len: felt, amounts: Uint256*) {
    let (amounts_len, amounts) = ERC1155.balanceOfBatch(accounts_len, accounts, ids_len, ids);
    return (amounts_len, amounts);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, operator: felt
) -> (approved: felt) {
    let (approved) = ERC1155.isApprovedForAll(account, operator);
    return (approved,);
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    let (caller) = get_caller_address();
    ERC1155.setApprovalForAll(caller, operator, approved);
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, id: felt, amount: Uint256, data: felt
) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (is_approved) = ERC1155.isApprovedForAll(from_, caller);
    with_attr error_message("ERC1155: either is not approved or the caller is the zero address") {
        assert_not_zero(caller * is_approved);
    }
    ERC1155.safeTransferFrom(from_, to, id, amount, data);
    return ();
}

@external
func safeBatchTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt,
    to: felt,
    ids_len: felt,
    ids: felt*,
    amounts_len: felt,
    amounts: Uint256*,
    data: felt,
) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (is_approved) = ERC1155.isApprovedForAll(from_, caller);
    with_attr error_message("ERC1155: either is not approved or the caller is the zero address") {
        assert_not_zero(caller * is_approved);
    }
    ERC1155.safeBatchTransferFrom(from_, to, ids_len, ids, amounts_len, amounts, data);
    return ();
}

// should add access control for mint
@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, id: felt, amount: Uint256, data: felt
) {
    ERC1155.mint(to, id, amount, data);
    return ();
}
