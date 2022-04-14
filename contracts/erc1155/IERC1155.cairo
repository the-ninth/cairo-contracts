%lang starknet

# IERC1155,  use felt for token id instead of Uint256

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC1155:

    func balanceOf(account: felt, id: felt) -> (balance: Uint256):
    end

    func balanceOfBatch(
        accounts_len: felt,
        accounts: felt*,
        ids_len: felt,
        ids: felt*
    ) -> (amounts_len: felt, amounts: Uint256*):
    end

    func setApprovalForAll(operator: felt, approved: felt):
    end

    func isApprovedForAll(account: felt, operator: felt) -> (approved: felt):
    end

    func safeTransferFrom(
        from_: felt,
        to: felt,
        id: felt,
        amount: Uint256,
        data: felt
    ):
    end

    func safeBatchTransferFrom(
        from_: felt,
        to: felt,
        ids_len: felt,
        ids: felt*,
        amounts_len: felt,
        amounts: Uint256*,
        data: felt
    ):
    end

end
