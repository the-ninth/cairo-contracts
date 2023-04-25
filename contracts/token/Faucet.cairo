// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.6.1 (token/erc20/presets/ERC20Mintable.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20

from contracts.proxy.two_step_upgrade.library import TwoStepUpgradeProxy

@storage_var
func Faucet_token_address() -> (address: felt) {
}

@storage_var
func Faucet_amount() -> (amount: Uint256) {
}

@storage_var
func Faucet_status(account: felt) -> (claimed: felt) {
}

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt, claim_amount: Uint256, owner: felt
) {
    Faucet_token_address.write(token_address);
    Faucet_amount.write(claim_amount);
    Ownable.initializer(owner);
    return ();
}

// Upgrade

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

//
// Getters
//

@view
func claimStatus{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (claimed: felt) {
    return Faucet_status.read(account);
}

@view
func claimAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    amount: Uint256
) {
    return Faucet_amount.read();
}

//
// Externals
//

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

@external
func claim{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assert_no_claimed();
    let (amount: Uint256) = Faucet_amount.read();
    let (caller) = get_caller_address();
    let (contract_address: felt) = Faucet_token_address.read();
    IERC20.transfer(contract_address=contract_address, recipient=caller, amount=amount);
    Faucet_status.write(caller, TRUE);
    return ();
}

@external
func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    let (caller) = get_caller_address();
    let (contract_address: felt) = Faucet_token_address.read();
    let (self) = get_contract_address();
    let (balance) = IERC20.balanceOf(contract_address=contract_address, account=self);
    IERC20.transfer(contract_address=contract_address, recipient=caller, amount=balance);
    return ();
}

// internal
func assert_no_claimed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (claimed: felt) = Faucet_status.read(account=caller);
    with_attr error_message("Ownable: caller claimed") {
        assert claimed = FALSE;
    }
    return ();
}
