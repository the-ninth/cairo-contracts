%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFarmer {
    func mint(to: felt) -> (tokenId: Uint256) {
    }
}
