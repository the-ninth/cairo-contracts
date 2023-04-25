%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (
    assert_nn_le,
    assert_in_range,
    unsigned_div_rem,
    assert_not_zero,
)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_eq,
    uint256_lt,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from starkware.starknet.common.syscalls import (
    get_block_number,
    get_block_timestamp,
    get_caller_address,
    get_contract_address,
)

from openzeppelin.token.erc20.IERC20 import IERC20

from contracts.util.math import sort_asc
from contracts.random.IRandomProducer import IRandomProducer
from contracts.token.interfaces.IMintable import IMintable

const ConflictOptionFail = 0;
const ConflictOptionNewPentagram = 1;

const PentagramStatusNone = 0;
const PentagramStatusPlaying = 1;
const PentagramStatusDone = 2;
const PentagramStatusEnd = 3;
const PentagramStatusCancel = 4;

const ExpireDuration = 3600;

@event
func Pray(
    pentagramNum: felt,
    tokenAddress: felt,
    prayerAddress: felt,
    value: Uint256,
    positon: felt,
    numberLower: felt,
    numberHigher: felt,
) {
}

@event
func PentagramDone(pentagramNum: felt, requestId: felt) {
}

@event
func PentagramEnd(pentagramNum: felt, seed: felt, hitNumber: felt, hitPrayer) {
}

struct Pentagram {
    token: felt,
    pentagramNum: felt,
    value: Uint256,
    status: felt,
    seed: felt,
    requestId: felt,
    hitNumber: felt,
    hitPrayerPosition: felt,
    expireTime: felt,
}

struct PentagramPrayer {
    prayerAddress: felt,
    position: felt,
    numberLower: felt,
    numberHigher: felt,
}

struct EndReward {
    rewardToken: felt,
    amount: Uint256,
}

@storage_var
func Seance_owner() -> (operator: felt) {
}

@storage_var
func Seance_operator() -> (operator: felt) {
}

@storage_var
func Seance_token_option_enabled(tokenAddress: felt) -> (enabled: felt) {
}

@storage_var
func Seance_token_option_values_length(tokenAddress: felt) -> (length: felt) {
}

@storage_var
func Seance_token_option_values(tokenAddress: felt, index: felt) -> (value: Uint256) {
}

@storage_var
func Seance_pentagram_counter() -> (count: felt) {
}

@storage_var
func Seance_pentagrams(pentagramNum: felt) -> (pentagram: Pentagram) {
}

@storage_var
func Seance_pentagram_prayers_length(pentagramNum: felt) -> (length: felt) {
}

@storage_var
func Seance_pentagram_prayers_by_position(pentagramNum: felt, position: felt) -> (
    prayer: PentagramPrayer
) {
}

@storage_var
func Seance_pentagram_num_by_request_id(requestId: felt) -> (pentagramNum: felt) {
}

@storage_var
func Seance_random_producer() -> (randomProducer: felt) {
}

@storage_var
func Seance_end_reward(tokenAddress: felt) -> (endReward: EndReward) {
}

@storage_var
func Seance_account_end_rewards(account: felt, rewardToken: felt) -> (amount: Uint256) {
}

namespace Seance {
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner, operator: felt
    ) {
        setOwner(owner);
        setOperator(operator);
        return ();
    }

    func assertOnlyOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (caller) = get_caller_address();
        let (owner) = Seance_owner.read();
        with_attr error_message("Seance: caller is not owner") {
            assert owner = caller;
        }
        return ();
    }

    func assertOnlyOperator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (caller) = get_caller_address();
        let (operator) = Seance_operator.read();
        with_attr error_message("Seance: caller is not operator") {
            assert operator = caller;
        }
        return ();
    }

    func assertTokenEnabled{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenAddress: felt
    ) {
        let (enabled) = Seance_token_option_enabled.read(tokenAddress);
        with_attr error_message("Seance: token not enabled") {
            assert enabled = TRUE;
        }
        return ();
    }

    func assertTokenValueEnabled{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenAddress: felt, value: Uint256
    ) {
        let (enabled) = tokenValueEnabled(tokenAddress, value);
        with_attr error_message("Seance: token value not enabled") {
            assert enabled = TRUE;
        }
        return ();
    }

    func setOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) {
        Seance_owner.write(owner);
        return ();
    }

    func setOperator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        operator: felt
    ) {
        Seance_operator.write(operator);
        return ();
    }

    func setTokenEnabled{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenAddress, enabled: felt
    ) -> () {
        with_attr error_message("Seance: invalid value") {
            assert_in_range(enabled, 0, 2);
        }
        Seance_token_option_enabled.write(tokenAddress, enabled);
        return ();
    }

    func setTokenOptionValues{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenAddress, values_len: felt, values: Uint256*
    ) {
        assert_nn_le(1, values_len);
        _setTokenOptionValuesLoop(tokenAddress, values, 0, values_len);
        Seance_token_option_values_length.write(tokenAddress, values_len);
        return ();
    }

    func pray{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenAddress: felt,
        value: Uint256,
        pentagramNum: felt,
        newPentagramWhenConflict: felt,
        numberLower: felt,
        numberHigher: felt,
    ) -> (pentagramNum: felt) {
        alloc_locals;
        assertTokenEnabled(tokenAddress);
        assertTokenValueEnabled(tokenAddress, value);
        let (numberLower, numberHigher) = sort_asc(numberLower, numberHigher);
        let (pentagram) = _findOrNewPentagram(
            tokenAddress, pentagramNum, value, numberLower, numberHigher, newPentagramWhenConflict
        );
        let (caller) = get_caller_address();
        let (self) = get_contract_address();
        IERC20.transferFrom(
            contract_address=tokenAddress, sender=caller, recipient=self, amount=value
        );
        let (length) = Seance_pentagram_prayers_length.read(pentagram.pentagramNum);
        let position = length + 1;
        let pentagramPrayer = PentagramPrayer(
            prayerAddress=caller,
            position=position,
            numberLower=numberLower,
            numberHigher=numberHigher,
        );
        Seance_pentagram_prayers_by_position.write(
            pentagram.pentagramNum, position, pentagramPrayer
        );
        Seance_pentagram_prayers_length.write(pentagram.pentagramNum, position);
        Pray.emit(
            pentagram.pentagramNum, tokenAddress, caller, value, position, numberLower, numberHigher
        );

        local status: felt;
        local requestId: felt;
        if (length == 4) {
            status = PentagramStatusDone;
            let (randomProducer) = Seance_random_producer.read();
            let (res) = IRandomProducer.requestRandom(contract_address=randomProducer);
            requestId = res;
            with_attr error_message("request id is zero") {
                assert_not_zero(requestId);
            }
            Seance_pentagram_num_by_request_id.write(requestId, pentagram.pentagramNum);
            PentagramDone.emit(pentagram.pentagramNum, requestId);
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            status = PentagramStatusPlaying;
            requestId = 0;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        let (blockTime) = get_block_timestamp();
        let pentagramUpdated = Pentagram(
            token=pentagram.token,
            pentagramNum=pentagram.pentagramNum,
            value=pentagram.value,
            status=status,
            seed=pentagram.seed,
            requestId=requestId,
            hitNumber=pentagram.hitNumber,
            hitPrayerPosition=pentagram.hitPrayerPosition,
            expireTime=blockTime + ExpireDuration,
        );
        Seance_pentagrams.write(pentagram.pentagramNum, pentagramUpdated);
        return (pentagram.pentagramNum,);
    }

    func setRandomProducer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        random_producer: felt
    ) {
        Seance_random_producer.write(random_producer);
        return ();
    }

    func reveal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        pentagramNum, seed
    ) {
        alloc_locals;
        let (local pentagram) = Seance_pentagrams.read(pentagramNum);
        with_attr error_message("Seance: invalid pentagram status") {
            assert pentagram.status = PentagramStatusDone;
        }
        let (q, hitNumber) = unsigned_div_rem(seed, 10);
        let (hitPrayer, hitPrayerPosition) = _findHitPrayerLoop(pentagramNum, hitNumber, 1, 5);
        let (totalValue, _) = uint256_mul(pentagram.value, Uint256(low=5, high=0));
        let (distributeValue, _) = uint256_unsigned_div_rem(totalValue, Uint256(low=4, high=0));
        _distributeTokenToPrayersLoop(
            pentagramNum, pentagram.token, hitPrayerPosition, distributeValue, 1, 5
        );
        let pentagramUpdated = Pentagram(
            token=pentagram.token,
            pentagramNum=pentagram.pentagramNum,
            value=pentagram.value,
            status=PentagramStatusEnd,
            seed=seed,
            requestId=pentagram.requestId,
            hitNumber=hitNumber,
            hitPrayerPosition=hitPrayerPosition,
            expireTime=pentagram.expireTime,
        );
        Seance_pentagrams.write(pentagramNum, pentagramUpdated);
        PentagramEnd.emit(pentagramNum, seed, hitNumber, hitPrayer);

        let (endReward) = Seance_end_reward.read(pentagram.token);
        if (endReward.rewardToken == 0) {
            return ();
        }
        let (res) = uint256_eq(Uint256(0, 0), endReward.amount);
        if (res == TRUE) {
            return ();
        }
        let (totalReward) = Seance_account_end_rewards.read(hitPrayer, endReward.rewardToken);
        let (totalRewardUpdated, _) = uint256_add(totalReward, endReward.amount);
        Seance_account_end_rewards.write(hitPrayer, endReward.rewardToken, totalRewardUpdated);
        return ();
    }

    // Chainlink VRF will be used instead in the future
    func fulfillRandomness{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        requestId: felt, randomness: felt
    ) {
        let (caller) = get_caller_address();
        let (randomProducer) = Seance_random_producer.read();
        with_attr error_message("Seance: invalid random producer") {
            assert caller = randomProducer;
        }
        let (pentagramNum) = Seance_pentagram_num_by_request_id.read(requestId);
        with_attr error_message("Seance: request id missing") {
            assert_not_zero(pentagramNum);
        }
        reveal(pentagramNum, randomness);
        return ();
    }

    func setEndReward{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenAddress: felt, endReward: EndReward
    ) {
        Seance_end_reward.write(tokenAddress, endReward);
        return ();
    }

    func claimEndReward{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        rewardToken: felt
    ) {
        let (caller) = get_caller_address();
        let (amount) = Seance_account_end_rewards.read(caller, rewardToken);
        with_attr error_message("not enough balance") {
            let (res) = uint256_lt(Uint256(0, 0), amount);
            assert res = TRUE;
        }
        IMintable.mint(contract_address=rewardToken, to=caller, amount=amount);
        Seance_account_end_rewards.write(caller, rewardToken, Uint256(0, 0));
        return ();
    }

    func getPentagram{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        pentagramNum
    ) -> (pentagram: Pentagram, prayers_len: felt, prayers: PentagramPrayer*) {
        alloc_locals;
        let (pentagram) = Seance_pentagrams.read(pentagramNum);
        let (local prayers: PentagramPrayer*) = alloc();
        let (prayersLength) = Seance_pentagram_prayers_length.read(pentagramNum);
        _getPentagramPrayersLoop(pentagramNum, 1, prayersLength, prayers);
        return (pentagram, prayersLength, prayers);
    }

    func getTokenEnabled{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenAddress
    ) -> (enabled: felt) {
        let (enabled) = Seance_token_option_enabled.read(tokenAddress);
        return (enabled,);
    }

    func getTokenOptionValues{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenAddress
    ) -> (values_len: felt, values: Uint256*) {
        alloc_locals;
        let (values: Uint256*) = alloc();
        let (values_len) = Seance_token_option_values_length.read(tokenAddress);
        _getTokenOptionValuesLoop(tokenAddress, 0, values_len, values);
        return (values_len, values);
    }

    func getEndReward{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenAddress: felt
    ) -> (endReward: EndReward) {
        let (endReward) = Seance_end_reward.read(tokenAddress);
        return (endReward,);
    }

    func getAccountEndReward{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, rewardToken: felt
    ) -> (amount: Uint256) {
        let (amount) = Seance_account_end_rewards.read(account, rewardToken);
        return (amount,);
    }

    func getRandomProducer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        randomProducer: felt
    ) {
        let (randomProducer) = Seance_random_producer.read();
        return (randomProducer,);
    }

    func getOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        owner: felt
    ) {
        let (owner) = Seance_owner.read();
        return (owner,);
    }

    func getOperator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        operator: felt
    ) {
        let (operator) = Seance_operator.read();
        return (operator,);
    }
}

func tokenValueEnabled{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress: felt, value: Uint256
) -> (enabled: felt) {
    let (length) = Seance_token_option_values_length.read(tokenAddress);
    let (tokenValueEnabled) = _tokenValueEnabledLoop(tokenAddress, value, 0, length);
    return (tokenValueEnabled,);
}

func _tokenValueEnabledLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress: felt, value: Uint256, index: felt, length: felt
) -> (enabled: felt) {
    alloc_locals;
    if (length == 0) {
        return (FALSE,);
    }
    let (valueByIndex) = Seance_token_option_values.read(tokenAddress, index);
    let (res) = uint256_eq(value, valueByIndex);
    if (res == TRUE) {
        return (TRUE,);
    }
    return _tokenValueEnabledLoop(tokenAddress, value, index + 1, length - 1);
}

func _findOrNewPentagram{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress,
    pentagramNum: felt,
    value: Uint256,
    numberLower,
    numberHigher,
    newPentagramWhenConflict,
) -> (pentagram: Pentagram) {
    alloc_locals;
    with_attr error_message("Seance: invalid numbers") {
        assert_in_range(numberLower, 0, 10);
        assert_in_range(numberHigher, 0, 10);
    }
    if (pentagramNum == 0) {
        return _newPentagram(tokenAddress, value);
    }
    let (local pentagram) = Seance_pentagrams.read(pentagramNum);
    with_attr error_message("Seance: invalid pentagram status") {
        assert pentagram.status = PentagramStatusPlaying;
    }
    with_attr error_message("Seance: invalid pentagram value") {
        assert pentagram.value = value;
    }
    let (hasConflict) = _hasConflictPray(pentagramNum, numberLower, numberHigher);
    if (hasConflict == TRUE and newPentagramWhenConflict == ConflictOptionNewPentagram) {
        return _newPentagram(tokenAddress, value);
    }
    with_attr error_message("Seance: pentagram conflict") {
        assert hasConflict = FALSE;
    }
    return (pentagram,);
}

func _hasConflictPray{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pentagramNum, numberLower, numberHigher
) -> (hasConflict: felt) {
    let (length) = Seance_pentagram_prayers_length.read(pentagramNum);
    return _hasConflictPrayLoop(pentagramNum, numberLower, numberHigher, 1, length);
}

func _hasConflictPrayLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pentagramNum, numberLower, numberHigher, positionInLoop, length
) -> (hasConflict: felt) {
    if (length == 0) {
        return (FALSE,);
    }
    let (pentagramPrayer) = Seance_pentagram_prayers_by_position.read(pentagramNum, positionInLoop);
    if (pentagramPrayer.prayerAddress == 0) {
        return _hasConflictPrayLoop(
            pentagramNum, numberLower, numberHigher, positionInLoop + 1, length - 1
        );
    }
    if (pentagramPrayer.numberLower == numberLower) {
        return (TRUE,);
    }
    if (pentagramPrayer.numberLower == numberHigher) {
        return (TRUE,);
    }
    if (pentagramPrayer.numberHigher == numberLower) {
        return (TRUE,);
    }
    if (pentagramPrayer.numberHigher == numberHigher) {
        return (TRUE,);
    }
    return _hasConflictPrayLoop(
        pentagramNum, numberLower, numberHigher, positionInLoop + 1, length - 1
    );
}

func _newPentagram{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress, value: Uint256
) -> (pentagram: Pentagram) {
    let (pentagramNum) = Seance_pentagram_counter.read();
    let pentagramNum = pentagramNum + 1;
    Seance_pentagram_counter.write(pentagramNum);
    let (blockTime) = get_block_timestamp();
    let pentagram = Pentagram(
        token=tokenAddress,
        pentagramNum=pentagramNum,
        value=value,
        status=PentagramStatusPlaying,
        seed=0,
        requestId=0,
        hitNumber=0,
        hitPrayerPosition=0,
        expireTime=blockTime + ExpireDuration,
    );
    return (pentagram,);
}

func _findHitPrayerLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pentagramNum, hitNumber, position, length
) -> (hitPrayer: felt, hitPrayerPosition: felt) {
    if (length == 0) {
        return (0, 0);
    }
    let (pentagramPrayer) = Seance_pentagram_prayers_by_position.read(pentagramNum, position);
    if (hitNumber == pentagramPrayer.numberLower) {
        return (pentagramPrayer.prayerAddress, position);
    }
    if (hitNumber == pentagramPrayer.numberHigher) {
        return (pentagramPrayer.prayerAddress, position);
    }
    return _findHitPrayerLoop(pentagramNum, hitNumber, position + 1, length - 1);
}

func _distributeTokenToPrayersLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pentagramNum: felt,
    tokenAddress: felt,
    hitPrayerPosition: felt,
    distributeValue: Uint256,
    position,
    length,
) -> () {
    if (length == 0) {
        return ();
    }
    if (position == hitPrayerPosition) {
        return _distributeTokenToPrayersLoop(
            pentagramNum, tokenAddress, hitPrayerPosition, distributeValue, position + 1, length - 1
        );
    }
    let (prayer) = Seance_pentagram_prayers_by_position.read(pentagramNum, position);
    IERC20.transfer(
        contract_address=tokenAddress, recipient=prayer.prayerAddress, amount=distributeValue
    );
    return _distributeTokenToPrayersLoop(
        pentagramNum, tokenAddress, hitPrayerPosition, distributeValue, position + 1, length - 1
    );
}

func _getPentagramPrayersLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pentagramNum, position, length, prayers: PentagramPrayer*
) {
    if (length == 0) {
        return ();
    }
    let (pentagramPrayer) = Seance_pentagram_prayers_by_position.read(pentagramNum, position);
    assert prayers[position - 1] = pentagramPrayer;
    return _getPentagramPrayersLoop(pentagramNum, position + 1, length - 1, prayers);
}

func _setTokenOptionValuesLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress, values: Uint256*, index, length
) {
    if (index == length) {
        return ();
    }
    Seance_token_option_values.write(tokenAddress, index, values[index]);
    _setTokenOptionValuesLoop(tokenAddress, values, index + 1, length);
    return ();
}

func _getTokenOptionValuesLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress, index, values_len: felt, values: Uint256*
) -> () {
    if (index == values_len) {
        return ();
    }
    let (value) = Seance_token_option_values.read(tokenAddress, index);
    assert values[index] = value;
    _getTokenOptionValuesLoop(tokenAddress, index + 1, values_len, values);
    return ();
}
