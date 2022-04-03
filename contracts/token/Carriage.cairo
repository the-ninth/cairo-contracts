# Land contract of The Ninth Game, based on openzepplin

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc721.library import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,

    ERC721_initializer,
    ERC721_approve, 
    ERC721_setApprovalForAll,
    ERC721_only_token_owner,
    ERC721_setTokenURI,
    ERC721_tokenURI
)

from openzeppelin.token.erc721_enumerable.library import (
    ERC721_Enumerable_initializer,
    ERC721_Enumerable_totalSupply,
    ERC721_Enumerable_tokenByIndex,
    ERC721_Enumerable_tokenOfOwnerByIndex,
    ERC721_Enumerable_mint,
    ERC721_Enumerable_burn,
    ERC721_Enumerable_transferFrom,
    ERC721_Enumerable_safeTransferFrom
)

from openzeppelin.introspection.ERC165 import ERC165_supports_interface

from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from contracts.ERC721_Enumerable_AutoId.library import (
    ERC721_Enumerable_AutoId_mint
)

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import ROLE_CARRIAGE_MINTER

#
# Storage
#

@storage_var
func Carriage_access_contract() -> (access_contract: felt):
end

# carriage token id -> soldier length
@storage_var
func carriage_soldier_len(carriage_id: Uint256) -> (len: felt):
end

# the soldier token id at the index in a carriage
@storage_var
func carriage_soldier_by_index(carriage_id: Uint256, index: felt) -> (soldier_id: Uint256):
end

# the carriage token id and the index in the carriage
@storage_var
func carriage_soldier_index(soldier_id: Uint256) -> (carriage_and_index: (Uint256, felt)):
end


# @storage_var
# func soldiers

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        access_contract: felt,
    ):
    ERC721_initializer('Ninth Carriage', 'NCAR')
    ERC721_Enumerable_initializer()
    Carriage_access_contract.write(access_contract)
    return ()
end

#
# Getters
#

@view
func totalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = ERC721_Enumerable_totalSupply()
    return (totalSupply)
end

@view
func tokenByIndex{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(index: Uint256) -> (tokenId: Uint256):
    let (tokenId: Uint256) = ERC721_Enumerable_tokenByIndex(index)
    return (tokenId)
end

@view
func tokenOfOwnerByIndex{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(owner: felt, index: Uint256) -> (tokenId: Uint256):
    let (tokenId: Uint256) = ERC721_Enumerable_tokenOfOwnerByIndex(owner, index)
    return (tokenId)
end

@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721_ownerOf(tokenId)
    return (owner)
end

@view
func getApproved{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt):
    let (approved: felt) = ERC721_getApproved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved: felt) = ERC721_isApprovedForAll(owner, operator)
    return (isApproved)
end

@view
func tokenURI{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (tokenURI: felt):
    let (tokenURI: felt) = ERC721_tokenURI(tokenId)
    return (tokenURI)
end

@view
func carriageSoldierLength{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(carriage_id: Uint256) -> (len: felt):
    let (len: felt) = carriage_soldier_len.read(carriage_id)
    return (len)
end

@view
func carriageSoldierByIndex{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(carriage_id: Uint256, index: felt) -> (soldier_id: Uint256):
    let (soldier_id: Uint256) = carriage_soldier_by_index.read(carriage_id, index)
    return (soldier_id)
end

@view
func carriageSoldierIndex{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(soldier_id: Uint256) -> (carriage_and_index: (Uint256, felt)):
    let (carriage_and_index: (Uint256, felt)) = carriage_soldier_index.read(soldier_id)
    return (carriage_and_index)
end

#
# Externals
#

@external
func approve{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721_approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _from: felt, 
        to: felt, 
        tokenId: Uint256
    ):
    ERC721_Enumerable_transferFrom(_from, to, tokenId)
    return ()
end

@external
func safeTransferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _from: felt, 
        to: felt, 
        tokenId: Uint256, 
        data_len: felt,
        data: felt*
    ):
    ERC721_Enumerable_safeTransferFrom(_from, to, tokenId, data_len, data)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt) -> (tokenId: Uint256):
    let (access_contract) = Carriage_access_contract.read()
    let (caller) = get_caller_address()
    IAccessControl.onlyRole(contract_address=access_contract, role=ROLE_CARRIAGE_MINTER, account=caller)
    let (tokenId) = _mint(to)
    return (tokenId)
end

# transfer soldiers to carriage contract, the owner of carriage and soldiers must be the caller
@external
func takeSouldiersAboard{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(carriage_id: Uint256, soldier_ids_len: felt, soldier_ids: Uint256*):
    if soldier_ids_len == 0:
        return ()
    end
    let (self) = get_contract_address()
    let (caller) = get_caller_address()
    let (access_contract) = Carriage_access_contract.read()
    let (soldier_contract) = IAccessControl.soldierContract(contract_address=access_contract)
    let (soldiers_owner) = IERC721.ownerOf(contract_address=soldier_contract, tokenId=soldier_ids[0])
    let (carriage_owner) = ERC721_ownerOf(carriage_id)
    assert carriage_owner = caller
    assert soldiers_owner = caller

    let soldier_id = soldier_ids[0]
    IERC721.transferFrom(contract_address=soldier_contract, from_=caller, to=self, tokenId=soldier_id)
    let (next_soldier_index) = carriage_soldier_len.read(carriage_id)
    carriage_soldier_by_index.write(carriage_id, next_soldier_index, soldier_id)
    carriage_soldier_index.write(soldier_id, (carriage_id, next_soldier_index))
    carriage_soldier_len.write(carriage_id, next_soldier_index + 1)

    takeSouldiersAboard(carriage_id, soldier_ids_len - 1, &soldier_ids[1])
    return()
end

#
# internals
#

func _mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt) -> (tokenId: Uint256):
    let (tokenId) = ERC721_Enumerable_AutoId_mint(to)
    return (tokenId)
end