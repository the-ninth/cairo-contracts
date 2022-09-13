%lang starknet
// erc1155

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.uint256 import Uint256, uint256_check

from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.security.safemath.library import SafeUint256

@event
func ApprovalForAll(owner: felt, operator: felt, approved: felt) {
}

@event
func TransferSingle(operator: felt, from_: felt, to_, id: felt, amount: Uint256) {
}

@storage_var
func ERC1155_balances(account: felt, id: felt) -> (balance: Uint256) {
}

@storage_var
func ERC1155_operator_approvals(owner: felt, operator: felt) -> (approved: felt) {
}

func ERC1155_balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, id: felt
) -> (balance: Uint256) {
    let (balance: Uint256) = ERC1155_balances.read(account, id);
    return (balance,);
}

func ERC1155_balanceOfBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    accounts_len: felt, accounts: felt*, ids_len: felt, ids: felt*
) -> (amounts_len: felt, amounts: Uint256*) {
    let (amounts: Uint256*) = alloc();
    // todo: implements
    assert 1 = 0;
    return (0, amounts);
}

func ERC1155_setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, operator: felt, approved: felt
) {
    with_attr error_message("ERC1155: setting approval status for self") {
        assert_not_equal(account, operator);
    }

    ERC1155_operator_approvals.write(account, operator, approved);
    ApprovalForAll.emit(account, operator, approved);
    return ();
}

func ERC1155_isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, operator: felt
) -> (approved: felt) {
    if (account == operator) {
        return (1,);
    }

    let (approved) = ERC1155_operator_approvals.read(account, operator);
    return (approved,);
}

// not implement ERC1155_RECEIVER checking yet
func ERC1155_safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, id: felt, amount: Uint256, data: felt
) {
    alloc_locals;

    with_attr error_message("ERC1155: cannot transfer from the zero address") {
        assert_not_zero(from_);
    }

    with_attr error_message("ERC1155: transfer to the zero address") {
        assert_not_zero(to);
    }

    with_attr error_message("ERC1155: amount is not a valid Uint256") {
        uint256_check(amount);  // almost surely not needed, might remove after confirmation
    }

    let (caller) = get_caller_address();

    let (from_balance) = ERC1155_balances.read(from_, id);
    with_attr error_message("ERC1155: transfer amount exceeds balance") {
        let (new_from_balance: Uint256) = SafeUint256.sub_le(from_balance, amount);
    }

    ERC1155_balances.write(from_, id, new_from_balance);

    let (to_balance: Uint256) = ERC1155_balances.read(to, id);
    let (new_to_balance: Uint256) = SafeUint256.add(to_balance, amount);
    ERC1155_balances.write(to, id, new_to_balance);

    TransferSingle.emit(caller, from_, to, id, amount);

    return ();
}

func ERC1155_safeBatchTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt,
    to: felt,
    ids_len: felt,
    ids: felt*,
    amounts_len: felt,
    amounts: Uint256*,
    data: felt,
) {
    // todo: implements
    assert 1 = 0;
    return ();
}

func ERC1155_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, id: felt, amount: Uint256, data: felt
) {
    with_attr error_message("ERC1155: amount is not a valid Uint256") {
        uint256_check(amount);
    }

    with_attr error_message("ERC1155: cannot mint to the zero address") {
        assert_not_zero(to);
    }

    let (caller) = get_caller_address();
    let (balance) = ERC1155_balances.read(to, id);
    let (new_balance) = SafeUint256.add(balance, amount);
    ERC1155_balances.write(to, id, new_balance);
    TransferSingle.emit(caller, 0, to, id, amount);

    return ();
}
