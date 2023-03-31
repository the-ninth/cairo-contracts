// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import library_call, library_call_l1_handler

from contracts.proxy.two_step_upgrade.library import TwoStepUpgradeProxy
from contracts.seance.library import Seance, Pentagram, PentagramPrayer

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner, operator: felt
) {
    TwoStepUpgradeProxy.initialized();
    Seance.initializer(owner, operator);
    return ();
}

@view
func getUpgradeOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    owner: felt
) {
    let (owner) = TwoStepUpgradeProxy.get_owner();
    return (owner,);
}

@view
func getUpgradeAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    admin: felt
) {
    let (admin) = TwoStepUpgradeProxy.get_admin();
    return (admin,);
}

@view
func getUpgradeConfirmer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    confirmer: felt
) {
    let (confirmer) = TwoStepUpgradeProxy.get_confirmer();
    return (confirmer,);
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation_address: felt
) {
    TwoStepUpgradeProxy.assert_only_admin();
    TwoStepUpgradeProxy._upgrade_implemention(implementation_address);
    return ();
}

@external
func confirmUpgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation_address: felt
) {
    TwoStepUpgradeProxy.assert_only_confirmer();
    TwoStepUpgradeProxy._confirm_implementation(implementation_address);
    return ();
}

@external
func setUpgradeOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) {
    TwoStepUpgradeProxy.assert_only_owner();
    TwoStepUpgradeProxy._set_owner(owner);
    return ();
}

@external
func setUpgradeAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(admin: felt) {
    TwoStepUpgradeProxy.assert_only_owner();
    TwoStepUpgradeProxy._set_admin(admin);
    return ();
}

@external
func setUpgradeConfirmer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    confirmer: felt
) {
    TwoStepUpgradeProxy.assert_only_owner();
    TwoStepUpgradeProxy._set_confirmer(confirmer);
    return ();
}

@external
func setOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) {
    Seance.assertOnlyOwner();
    Seance.setOwner(owner);
    return ();
}

@external
func setOperator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(operator: felt) {
    Seance.assertOnlyOwner();
    Seance.setOperator(operator);
    return ();
}

@external
func setTokenEnabled{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress, enabled: felt
) -> () {
    Seance.assertOnlyOperator();
    Seance.setTokenEnabled(tokenAddress, enabled);
    return ();
}

@external
func setTokenOptionValues{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress, values_len: felt, values: Uint256*
) {
    Seance.assertOnlyOperator();
    Seance.setTokenOptionValues(tokenAddress, values_len, values);
    return ();
}

@external
func pray{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress: felt,
    value: Uint256,
    pentagramNum: felt,
    newPentagramWhenConflict: felt,
    numberLower: felt,
    numberHigher: felt,
) -> (pentagramNum: felt) {
    let (pentagramNum) = Seance.pray(
        tokenAddress, value, pentagramNum, newPentagramWhenConflict, numberLower, numberHigher
    );
    return (pentagramNum,);
}

@external
func reveal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(pentagramNum, seed) {
    Seance.reveal(pentagramNum, seed);
    return ();
}

@external
func fulfillRandomness{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    requestId, randomness
) {
    Seance.fulfillRandomness(requestId, randomness);
    return ();
}

@external
func setRandomProducer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    randomProducer: felt
) {
    Seance.assertOnlyOwner();
    Seance.setRandomProducer(randomProducer);
    return ();
}

@view
func getPentagram{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pentagramNum
) -> (pentagram: Pentagram, prayers_len: felt, prayers: PentagramPrayer*) {
    let (pentagram, prayers_len, prayers) = Seance.getPentagram(pentagramNum);
    return (pentagram, prayers_len, prayers);
}

@view
func getTokenEnabled{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress
) -> (enabled: felt) {
    let (enabled) = Seance.getTokenEnabled(tokenAddress);
    return (enabled,);
}

@view
func getTokenOptionValues{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenAddress
) -> (values_len: felt, values: Uint256*) {
    return Seance.getTokenOptionValues(tokenAddress);
}

@view
func getRandomProducer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    randomProducer: felt
) {
    let (randomProducer) = Seance.getRandomProducer();
    return (randomProducer,);
}

@view
func getOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner) = Seance.getOwner();
    return (owner,);
}

@view
func getOperator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    operator: felt
) {
    let (operator) = Seance.getOperator();
    return (operator,);
}
