%lang starknet
# erc1155 

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.uint256 import Uint256, uint256_check

from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.security.safemath import (
    uint256_checked_add, uint256_checked_sub_le
)

@event
func ApprovalForAll(owner: felt, operator: felt, approved: felt):
end

@event 
func TransferSingle(operator: felt, from_: felt, to_, id: felt, amount: Uint256):
end


@storage_var
func ERC1155_balances(account: felt, id: felt) -> (balance: Uint256):
end

@storage_var
func ERC1155_operator_approvals(owner: felt, operator: felt) -> (approved: felt):
end

func ERC1155_balanceOf{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt, id: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC1155_balances.read(account, id)
    return (balance)
end

func ERC1155_balanceOfBatch{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        accounts_len: felt,
        accounts: felt*,
        ids_len: felt,
        ids: felt*
    ) -> (amounts_len: felt, amounts: Uint256*):
    let (amounts: Uint256*) = alloc()
    # todo: implements
    return (0, amounts)
end

func ERC1155_setApprovalForAll{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt, operator: felt, approved: felt):
    with_attr error_message("ERC1155: setting approval status for self"):
        assert_not_equal(account, operator)
    end
    ERC1155_operator_approvals.write(account, operator, approved)
    ApprovalForAll.emit(account, operator, approved)
    return ()
end

func ERC1155_isApprovedForAll{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt, operator: felt) -> (approved: felt):
    if account == operator:
        return (1)
    end
    let (approved) = ERC1155_operator_approvals.read(account, operator)
    return (approved)
end

# not implement ERC1155_RECEIVER checking yet
func ERC1155_safeTransferFrom{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        to: felt,
        id: felt,
        amount: Uint256,
        data: felt
    ):
    alloc_locals
    
    with_attr error_message("ERC1155: cannot transfer from the zero address"):
        assert_not_zero(from_)
    end

    with_attr error_message("ERC1155: transfer to the zero address"):
        assert_not_zero(to)
    end

    with_attr error_message("ERC1155: amount is not a valid Uint256"):
        uint256_check(amount) # almost surely not needed, might remove after confirmation
    end

    let (caller) = get_caller_address()

    let (from_balance) = ERC1155_balances.read(from_, id)
    with_attr error_message("ERC1155: transfer amount exceeds balance"):
        let (new_from_balance: Uint256) = uint256_checked_sub_le(from_balance, amount)
    end
    ERC1155_balances.write(from_, id, new_from_balance)

    let (to_balance: Uint256) = ERC1155_balances.read(to, id)
    let (new_to_balance: Uint256) = uint256_checked_add(to_balance, amount)
    ERC1155_balances.write(to, id, new_to_balance)

    TransferSingle.emit(caller, from_, to, id, amount)

    return ()
end

func ERC1155_safeBatchTransferFrom{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        to: felt,
        ids_len: felt,
        ids: felt*,
        amounts_len: felt,
        amounts: Uint256*,
        data: felt
    ):
    # todo: implements
    return ()
end

func ERC1155_mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(to: felt, id: felt, amount: Uint256, data: felt):

    with_attr error_message("ERC1155: amount is not a valid Uint256"):
        uint256_check(amount)
    end

    with_attr error_message("ERC1155: cannot mint to the zero address"):
        assert_not_zero(to)
    end

    let (caller) = get_caller_address()
    let (balance) = ERC1155_balances.read(to, id)
    let (new_balance) = uint256_checked_add(balance, amount)
    ERC1155_balances.write(to, id, new_balance)
    TransferSingle.emit(caller, 0, to, id, amount)

    return ()
end