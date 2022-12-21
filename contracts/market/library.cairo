%lang starknet
// market library

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_le
from starkware.cairo.common.bool import TRUE, FALSE

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_add,
    uint256_sub,
    uint256_mul,
    uint256_unsigned_div_rem,
    uint256_le,
    uint256_lt,
    uint256_eq,
)

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

from openzeppelin.security.safemath.library import SafeUint256

from openzeppelin.token.erc20.IERC20 import IERC20

from openzeppelin.token.erc721.IERC721 import IERC721

from contracts.erc1155.IERC1155 import IERC1155

from contracts.util.Uin256_felt_conv import _uint_to_felt

//
// constant struct
//

const ERC721_TOKEN = 721;
const ERC1155_TOKEN = 1155;
const ERC20_TOKEN = 20;

struct Token {
    iswhite: felt,  // 0,false,1 true
    address: felt,  // token address
    type: felt,  // 721 erc721,1155 erc1155
}

struct Order {
    base_token_no: Uint256,  // implied which coin change into, erc20
    token_no: Uint256,  // implied which to sell,erc721 or erc1155
    id: Uint256,  // token id
    amount: Uint256,  // token amount to sell
    seller: felt,  // seller
    unit_price: Uint256,  // unit price
    startTime: felt,  // order time
}

//
// Storage
//

@storage_var
func Market_orders_len() -> (total: Uint256) {
}

@storage_var
func Market_orders(index: Uint256) -> (order: Order) {
}

// @storage_var
// func Op_history(owner: felt) -> (data:felt):
// end

@storage_var
func Market_token_len() -> (total: Uint256) {
}

@storage_var
func Market_token_info(index: Uint256) -> (token_info: Token) {
}

//
// getters
//

func Market_ordersLen{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    len: Uint256
) {
    let (len) = Market_orders_len.read();
    return (len,);
}

func Market_getOrder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: Uint256
) -> (order: Order) {
    alloc_locals;
    uint256_check(index);
    // Ensures index argument is less than orders_len
    let (len: Uint256) = Market_ordersLen();
    let (is_lt) = uint256_lt(index, len);
    with_attr error_message("Market: getOrder index out of bounds") {
        assert is_lt = TRUE;
    }
    let (order: Order) = Market_orders.read(index);
    return (order,);
}

func Market_getBatchOrder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    start: Uint256, last: Uint256
) -> (orders_len: felt, orders: Order*) {
    alloc_locals;
    let (diff: Uint256) = SafeUint256.sub_le(last, start);
    let (diff: Uint256) = SafeUint256.add(diff, Uint256(1, 0));
    let (left: felt) = _uint_to_felt(diff);
    let (local orders: Order*) = alloc();
    Market_getOrder_loop(start=start, orders=orders, left=left);
    return (orders_len=left, orders=orders);
}

func Market_tokensLen{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    len: Uint256
) {
    let (len) = Market_token_len.read();
    return (len,);
}

func Market_getToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: Uint256
) -> (token: Token) {
    alloc_locals;
    uint256_check(index);
    // Ensures index argument is less than orders_len
    let (len: Uint256) = Market_tokensLen();
    let (is_lt) = uint256_lt(index, len);
    with_attr error_message("Market: getToken index out of bounds") {
        assert is_lt = TRUE;
    }
    let (token: Token) = Market_token_info.read(index);
    return (token,);
}

//
// Externals
//

// sell
func Market_sell{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    base_token_no: Uint256, token_no: Uint256, id: Uint256, amount: Uint256, unit_price: Uint256
) {
    alloc_locals;

    // check whether coin is legal
    _check_token(base_token_no);
    let (token_info: Token) = _check_token(token_no);

    // check unit price
    with_attr error_message("sell: amount or price error") {
        SafeUint256.mul(unit_price, amount);
    }

    // get sender
    let (sender) = get_caller_address();

    // get contract address
    let (self) = get_contract_address();

    // getblock time
    let (block_timestamp) = get_block_timestamp();

    // transfer tokens
    let (data: felt*) = alloc();
    assert [data] = 0;
    if (token_info.type == ERC721_TOKEN) {
        let (is_one) = uint256_eq(amount, Uint256(1, 0));
        with_attr error_message("Market_sell: 721 amount error") {
            assert is_one = TRUE;
        }
        IERC721.safeTransferFrom(
            contract_address=token_info.address,
            from_=sender,
            to=self,
            tokenId=id,
            data_len=1,
            data=data,
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        let (id_felt: felt) = _uint_to_felt(id);
        IERC1155.safeTransferFrom(
            contract_address=token_info.address,
            from_=sender,
            to=self,
            id=id_felt,
            amount=amount,
            data=0,
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // add order
    local order: Order;
    assert order.base_token_no = base_token_no;
    assert order.token_no = token_no;
    assert order.id = id;
    assert order.amount = amount;
    assert order.seller = sender;
    assert order.unit_price = unit_price;
    assert order.startTime = block_timestamp;

    _add_order(order);

    // todo add op history
    return ();
}

// buy
func Market_buy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    order_index: Uint256, amount: Uint256
) {
    alloc_locals;

    let (order: Order) = Market_getOrder(order_index);

    // check amount
    let (is_le) = uint256_le(amount, order.amount);
    with_attr error_message("buy: amount error") {
        assert is_le = TRUE;
    }

    // get sender
    let (sender) = get_caller_address();
    let (token_info: Token) = Market_getToken(order.token_no);
    let (base_token_info: Token) = Market_getToken(order.base_token_no);
    let (total_amount: Uint256) = SafeUint256.mul(order.unit_price, amount);

    // transfer tokens from caller to seller
    let (res) = IERC20.transferFrom(
        contract_address=base_token_info.address,
        sender=sender,
        recipient=order.seller,
        amount=total_amount,
    );
    with_attr error_message("buy: token transferFrom error") {
        assert res = TRUE;
    }

    // get contract address
    let (self) = get_contract_address();

    // transfer tokens to caller
    let (data: felt*) = alloc();
    assert [data] = 0;
    if (token_info.type == ERC721_TOKEN) {
        IERC721.safeTransferFrom(
            contract_address=token_info.address,
            from_=self,
            to=sender,
            tokenId=order.id,
            data_len=1,
            data=data,
        );
        _discard_order(order_index);
    } else {
        let (id: felt) = _uint_to_felt(order.id);
        IERC1155.safeTransferFrom(
            contract_address=token_info.address, from_=self, to=sender, id=id, amount=amount, data=0
        );
        let (is_eq) = uint256_eq(amount, order.amount);
        if (is_eq == TRUE) {
            _discard_order(order_index);
        } else {
            // check order amount
            with_attr error_message("Market_buy: new_amount error") {
                let (left_amount: Uint256) = SafeUint256.sub_lt(order.amount, amount);
            }
            _update_order_amount(order_index, order, left_amount);
        }
    }

    return ();
}

// cancel
func Market_cancel{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    order_index: Uint256
) {
    alloc_locals;
    let (order: Order) = Market_getOrder(order_index);

    // check sender is seller
    let (sender) = get_caller_address();
    with_attr error_message("calcel: sender error") {
        assert sender = order.seller;
    }

    let (token_info: Token) = Market_getToken(order.token_no);

    // get contract address
    let (self) = get_contract_address();

    // transfer tokens to caller
    let (data: felt*) = alloc();
    assert [data] = 0;
    if (token_info.type == ERC721_TOKEN) {
        IERC721.safeTransferFrom(
            contract_address=token_info.address,
            from_=self,
            to=order.seller,
            tokenId=order.id,
            data_len=1,
            data=data,
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        let (id: felt) = _uint_to_felt(order.id);
        IERC1155.safeTransferFrom(
            contract_address=token_info.address,
            from_=self,
            to=order.seller,
            id=id,
            amount=order.amount,
            data=0,
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    _discard_order(order_index);
    return ();
}

// add config token
func Market_add_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt, type: felt
) {
    alloc_locals;

    // check address
    with_attr error_message("add_token: address error") {
        assert_not_zero(address);
    }

    // check type
    with_attr error_message("sell: amount or price error") {
        assert (type - ERC1155_TOKEN) * (type - ERC721_TOKEN) * (type - ERC20_TOKEN) = 0;
    }

    // add token
    local token: Token;
    assert token.address = address;
    assert token.type = type;
    assert token.iswhite = TRUE;

    let (len: Uint256) = Market_token_len.read();
    Market_token_info.write(len, token);
    let (new_len: Uint256) = SafeUint256.add(len, Uint256(1, 0));
    // update all token length
    Market_token_len.write(new_len);
    return ();
}

//
// Internals
//

func Market_getOrder_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    start: Uint256, orders: Order*, left
) -> () {
    alloc_locals;
    if (left == 0) {
        return ();
    }
    let (local order) = Market_orders.read(start);
    assert [orders] = order;
    let (new_start) = SafeUint256.add(start, Uint256(1, 0));
    Market_getOrder_loop(start=new_start, orders=orders + Order.SIZE, left=left - 1);
    return ();
}

func _add_order{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(order: Order) {
    alloc_locals;
    let (len: Uint256) = Market_orders_len.read();
    // add order
    Market_orders.write(len, order);
    let (new_len: Uint256) = SafeUint256.add(len, Uint256(1, 0));
    // update all order length
    Market_orders_len.write(new_len);
    return ();
}

func _discard_order{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    order_index: Uint256
) {
    alloc_locals;
    let (len: Uint256) = Market_orders_len.read();

    let (new_len: Uint256) = uint256_sub(len, Uint256(1, 0));
    // update all order length
    Market_orders_len.write(new_len);

    // update order
    // if the order is the last
    let (is_last) = uint256_eq(order_index, new_len);
    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;
    if (is_last == FALSE) {
        // update order index
        let (last_order: Order) = Market_orders.read(new_len);
        Market_orders.write(order_index, last_order);
    }
    // todo add op history
    return ();
}

func _update_order_amount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    order_index: Uint256, order: Order, left_amount: Uint256
) -> () {
    alloc_locals;
    local new_order: Order;
    assert new_order.base_token_no = order.base_token_no;
    assert new_order.token_no = order.token_no;
    assert new_order.id = order.id;
    assert new_order.amount = left_amount;
    assert new_order.seller = order.seller;
    assert new_order.unit_price = order.unit_price;
    assert new_order.startTime = order.startTime;
    Market_orders.write(order_index, new_order);
    return ();
}

func _check_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_no: Uint256
) -> (token: Token) {
    alloc_locals;
    // check whether token_no is legal
    let (token: Token) = Market_getToken(token_no);
    with_attr error_message("sell: anchor error") {
        assert token.iswhite = 1;
    }
    return (token,);
}
