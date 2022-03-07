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

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from contracts.token.interfaces.IFarmer import IFarmer

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import ROLE_ADMIN

# from contracts.ERC721_Enumerable_AutoId.library import (
#     ERC721_Enumerable_AutoId_mint
# )

const BUILDING_TYPE_MINE = 1
const BUILDING_TYPE_LUMBER_CAMPS = 2

struct Land:
    member building_type : felt
end

#
# Storage
#

@storage_var
func Land_lands(tokenId: Uint256) -> (land: Land):
end

@storage_var
func Land_access_contract() -> (access_contract: felt):
end

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
    ERC721_initializer('Ninth Land', 'NLAND')
    ERC721_Enumerable_initializer()
    Land_access_contract.write(access_contract)
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
func getLand{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(tokenId: Uint256) -> (land: Land):
    ERC721_ownerOf(tokenId)
    let (land) = Land_lands.read(tokenId)
    return (land)
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
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256):
    ERC721_only_token_owner(tokenId)
    ERC721_Enumerable_burn(tokenId)
    return ()
end

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, tokenURI: felt):
    let (access_contract) = Land_access_contract.read()
    IAccessControl.onlyRole(contract_address=access_contract,role=ROLE_ADMIN)
    ERC721_setTokenURI(tokenId, tokenURI)
    return ()
end


@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    let (access_contract) = Land_access_contract.read()
    IAccessControl.onlyRole(contract_address=access_contract,role=ROLE)
    _mint(to, tokenId)
    return ()
end

# pay diamond to buy land
@external
func buyLand{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256):
    # let (amount) = Uint256(low=1000000000000000000000, high=0)
    let (caller) = get_caller_address()
    let (self) = get_contract_address()
    let (access_contract) = Land_access_contract.read()
    let (diamond_contract) = IAccessControl.diamondContract(contract_address=access_contract)
    let (res) = IERC20.transferFrom(contract_address=diamond_contract, sender=caller, recipient=self, amount=Uint256(low=1000000000000000000000, high=0))
    assert res = 1
    _mint(caller, tokenId)
    return ()
end

# pay coin to build
@external
func build{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, buildingType: felt):
    ERC721_only_token_owner(tokenId)
    # let (amount: Uint256) = Uint256(low=1000000000000000000000, high=0)
    let (caller) = get_caller_address()
    let (self) = get_contract_address()
    let (access_contract) = Land_access_contract.read()
    let (coin_contract) = IAccessControl.coinContract(contract_address=access_contract)
    let (res) = IERC20.transferFrom(contract_address=coin_contract, sender=caller, recipient=self, amount=Uint256(low=1000000000000000000000, high=0))
    assert res = 1
    _build(tokenId, buildingType)
    return ()
end

#
# internals
#

func _mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721_Enumerable_mint(to, tokenId)
    # mint a farmer, assign to the land contract
    # todo: record the farmers on a land
    let (access_contract) = Land_access_contract.read()
    let (farmer_contract) = IAccessControl.farmerContract(contract_address=access_contract)
    let (land_contract) = IAccessControl.landContract(contract_address=access_contract)
    let (farmer_token_id) = IFarmer.mint(contract_address=farmer_contract, to=land_contract)
    return ()
end

func _build{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, buildingType: felt):
    let (land: Land) = getLand(tokenId)
    assert land.building_type = 0
    land.building_type = buildingType
    Land_lands.write(tokenId, land)
    return ()
end