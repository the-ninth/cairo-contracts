%lang starknet

// combat register for first relic combat

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_add

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import NINTH_CONTRACT, FR_COMBAT_CONTRACT
from contracts.pvp.first_relic.IFirstRelicCombat import IFirstRelicCombat

const REGISTER_FEE = 5000000000000000000;  // charged in NINTH
const REWARD_PERCENT = 50;  // 50% for reard distribution

@storage_var
func access_contract() -> (access_contract: felt) {
}

@storage_var
func combat_register_fee(combat_id: felt) -> (total: Uint256) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    access_contract_: felt
) {
    access_contract.write(access_contract_);
    return ();
}

@external
func register{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(combat_id: felt) {
    let (caller) = get_caller_address();
    let (self) = get_contract_address();
    let (access_contract_address) = access_contract.read();
    let (ninth_contract_address) = IAccessControl.getContractAddress(
        contract_address=access_contract_address, contract_name=NINTH_CONTRACT
    );
    let register_fee = Uint256(REGISTER_FEE, 0);
    let (res) = IERC20.transferFrom(
        contract_address=ninth_contract_address, sender=caller, recipient=self, amount=register_fee
    );
    assert res = TRUE;
    let (total) = combat_register_fee.read(combat_id);
    let (new_total) = SafeUint256.add(total, register_fee);
    combat_register_fee.write(combat_id, new_total);

    let (combat_contract_address) = IAccessControl.getContractAddress(
        contract_address=access_contract_address, contract_name=FR_COMBAT_CONTRACT
    );
    IFirstRelicCombat.initPlayer(
        contract_address=combat_contract_address, combat_id=combat_id, account=caller
    );

    return ();
}

@view
func getTotalNinthRewards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt
) -> (rewards: Uint256) {
    // todo: calculate total rewards from register fee
    return (Uint256(0, 0),);
}

@external
func distributeNinthRewards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_id: felt
) {
    // todo: distribute NINTH rewards from register fee
    return ();
}
