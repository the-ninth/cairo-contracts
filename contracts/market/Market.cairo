%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

const IERC721_RECEIVER_ID = 0x150b7a02

from openzeppelin.introspection.ERC165 import ERC165_supports_interface, ERC165_register_interface

from openzeppelin.access.ownable import Ownable_initializer, Ownable_only_owner

from contracts.market.library import (
    Order,
    Token,
    Market_ordersLen,
    Market_getOrder,
    Market_tokensLen,
    Market_getToken,
    Market_sell,
    Market_buy,
    Market_add_token,
)

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt):
    Ownable_initializer(owner)
    ERC165_register_interface(IERC721_RECEIVER_ID)
    return ()
end

#
# Getters
#

@view
func orderLen{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    len : Uint256
):
    let (len : Uint256) = Market_ordersLen()
    return (len)
end

@view
func tokenLen{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    len : Uint256
):
    let (len : Uint256) = Market_tokensLen()
    return (len)
end

@view
func getOrder{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    index : Uint256
) -> (order : Order):
    let (order : Order) = Market_getOrder(index)
    return (order)
end

@view
func getToken{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    index : Uint256
) -> (token : Token):
    let (token : Token) = Market_getToken(index)
    return (token)
end

@view
func onERC721Received(
    operator : felt, from_ : felt, tokenId : Uint256, data_len : felt, data : felt*
) -> (selector : felt):
    return (IERC721_RECEIVER_ID)
end

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

#
# Externals
#

@external
func sell{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    base_coin_no : Uint256, coin_no : Uint256, id : Uint256, amount : Uint256, unit_price : Uint256
):
    Market_sell(base_coin_no, coin_no, id, amount, unit_price)
    return ()
end

@external
func buy{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    order_index : Uint256, amount : Uint256
):
    Market_buy(order_index, amount)
    return ()
end

@external
func addToken{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    address : felt, type : felt
):
    Ownable_only_owner()
    Market_add_token(address, type)
    return ()
end
