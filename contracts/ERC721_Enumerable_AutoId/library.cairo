# SPDX-License-Identifier: MIT
# add auto id  support for openzeppelin ERC721 Enumerable

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_lt, uint256_eq, uint256_check
)

from openzeppelin.token.erc721_enumerable.library import (
    ERC721_Enumerable_mint
)

#
# Storage
#

@storage_var
func ERC721_Enumerable_AutoId_counter() -> (token_id: Uint256):
end


func ERC721_Enumerable_AutoId_mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt) -> (token_id: Uint256):
    alloc_locals
    
    let (last_token_id: Uint256) = ERC721_Enumerable_AutoId_counter.read()
    let (token_id: Uint256, is_overflow) = uint256_add(last_token_id, Uint256(low=1, high=0))
    assert is_overflow = 0
    ERC721_Enumerable_AutoId_counter.write(token_id)
    ERC721_Enumerable_mint(to, token_id)
    return (token_id)
end
