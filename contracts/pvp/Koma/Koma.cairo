# Koma contract of The Ninth Game, based on openzepplin

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
    ERC721_tokenURI,
)

from openzeppelin.token.erc721_enumerable.library import (
    ERC721_Enumerable_initializer,
    ERC721_Enumerable_totalSupply,
    ERC721_Enumerable_tokenByIndex,
    ERC721_Enumerable_tokenOfOwnerByIndex,
    ERC721_Enumerable_mint,
    ERC721_Enumerable_burn,
    ERC721_Enumerable_transferFrom,
    ERC721_Enumerable_safeTransferFrom,
)

from openzeppelin.introspection.ERC165 import ERC165_supports_interface

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import ROLE_KOMA_MINTER, ROLE_ADMIN
from contracts.pvp.Koma.library import Koma, KomaCreature, KomaLibrary

@storage_var
func Koma_access_contract() -> (access_contract : felt):
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    access_contract_ : felt
):
    ERC721_initializer('Ninth Koma', 'NKOMA')
    ERC721_Enumerable_initializer()
    Koma_access_contract.write(access_contract_)
    return ()
end

#
# Getters
#

@view
func totalSupply{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    totalSupply : Uint256
):
    let (totalSupply : Uint256) = ERC721_Enumerable_totalSupply()
    return (totalSupply)
end

@view
func tokenByIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    index : Uint256
) -> (tokenId : Uint256):
    let (tokenId : Uint256) = ERC721_Enumerable_tokenByIndex(index)
    return (tokenId)
end

@view
func tokenOfOwnerByIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    owner : felt, index : Uint256
) -> (tokenId : Uint256):
    let (tokenId : Uint256) = ERC721_Enumerable_tokenOfOwnerByIndex(owner, index)
    return (tokenId)
end

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
    balance : Uint256
):
    let (balance : Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (owner : felt):
    let (owner : felt) = ERC721_ownerOf(tokenId)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (approved : felt):
    let (approved : felt) = ERC721_getApproved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, operator : felt
) -> (isApproved : felt):
    let (isApproved : felt) = ERC721_isApprovedForAll(owner, operator)
    return (isApproved)
end

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (tokenURI : felt):
    let (tokenURI : felt) = ERC721_tokenURI(tokenId)
    return (tokenURI)
end

@view
func getKoma{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (koma : Koma):
    let (koma) = KomaLibrary.get_koma(token_id)
    return (koma)
end

@view
func getKomas{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt, index : Uint256, length : felt
) -> (komas_len : felt, komas : Koma*):
    let (komas_len, komas) = KomaLibrary.get_komas(account, index, length)
    return (komas_len, komas)
end

@view
func getKomaCreature{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    koma_creature_id : felt
) -> (koma_creature : KomaCreature):
    let (koma_creature) = KomaLibrary.get_koma_creature(koma_creature_id)
    return (koma_creature)
end

#
# Externals
#

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    to : felt, tokenId : Uint256
):
    ERC721_approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    operator : felt, approved : felt
):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    _from : felt, to : felt, tokenId : Uint256
):
    ERC721_Enumerable_transferFrom(_from, to, tokenId)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    _from : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*
):
    ERC721_Enumerable_safeTransferFrom(_from, to, tokenId, data_len, data)
    return ()
end

@external
func setTokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256, tokenURI : felt
):
    ERC721_setTokenURI(tokenId, tokenURI)
    return ()
end

@external
func setKomaCreature{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    koma_creature_id : felt, koma_creature : KomaCreature
) -> ():
    onlyRole(ROLE_ADMIN)
    KomaLibrary.set_koma_creature(koma_creature_id, koma_creature)
    return ()
end

@external
func mint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    to : felt, koma_creature_id : felt
) -> (token_id : Uint256):
    onlyRole(ROLE_KOMA_MINTER)
    let (token_id) = KomaLibrary.mint(to, koma_creature_id)
    return (token_id)
end

func onlyRole{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(role : felt) -> ():
    let (access_contract) = Koma_access_contract.read()
    let (caller) = get_caller_address()
    IAccessControl.onlyRole(contract_address=access_contract, role=role, account=caller)
    return ()
end
