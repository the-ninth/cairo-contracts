%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

const IERC721_RECEIVER_ID = 0x150b7a02;

from openzeppelin.introspection.erc165.library import ERC165

from openzeppelin.access.ownable.library import Ownable

from contracts.market.library import (
    Order,
    Token,
    Market_ordersLen,
    Market_getOrder,
    Market_getBatchOrder,
    Market_tokensLen,
    Market_getToken,
    Market_sell,
    Market_buy,
    Market_add_token,
    Market_cancel,
)

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) {
    Ownable.initializer(owner);
    ERC165.register_interface(IERC721_RECEIVER_ID);
    return ();
}

//
// Getters
//

@view
func orderLen{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (len: Uint256) {
    let (len: Uint256) = Market_ordersLen();
    return (len,);
}

@view
func tokenLen{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (len: Uint256) {
    let (len: Uint256) = Market_tokensLen();
    return (len,);
}

@view
func getOrder{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(index: Uint256) -> (
    order: Order
) {
    let (order: Order) = Market_getOrder(index);
    return (order,);
}

@view
func getBatchOrders{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    start: Uint256, last: Uint256
) -> (orders_len: felt, orders: Order*) {
    let (orders_len: felt, orders: Order*) = Market_getBatchOrder(start, last);
    return (orders_len=orders_len, orders=orders);
}

@view
func getToken{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(index: Uint256) -> (
    token: Token
) {
    let (token: Token) = Market_getToken(index);
    return (token,);
}

@view
func onERC721Received(
    operator: felt, from_: felt, tokenId: Uint256, data_len: felt, data: felt*
) -> (selector: felt) {
    return (IERC721_RECEIVER_ID,);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@view
func owner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (owner: felt) {
    let (owner) = Ownable.owner();
    return (owner=owner);
}

//
// Externals
//

@external
func sell{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    base_coin_no: Uint256, coin_no: Uint256, id: Uint256, amount: Uint256, unit_price: Uint256
) {
    Market_sell(base_coin_no, coin_no, id, amount, unit_price);
    return ();
}

@external
func buy{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    order_index: Uint256, amount: Uint256
) {
    Market_buy(order_index, amount);
    return ();
}

@external
func cancel{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(order_index: Uint256) {
    Market_cancel(order_index);
    return ();
}

@external
func addToken{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    address: felt, type: felt
) {
    Ownable.assert_only_owner();
    Market_add_token(address, type);
    return ();
}

@external
func transferOwnership{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    new_owner: felt
) -> (new_owner: felt) {
    Ownable.transfer_ownership(new_owner);
    return (new_owner=new_owner,);
}
