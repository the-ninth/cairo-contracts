%lang starknet

// combat register for first relic combat

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFirstRelicCombatRegister {
    func register(combat_id: felt) {
    }

    func getTotalNinthRewards(combat_id: felt) -> (rewards: Uint256) {
    }

    func distribute_rewards(combat_id: felt) {
    }
}
