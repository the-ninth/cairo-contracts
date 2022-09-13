%lang starknet

@contract_interface
namespace IAccessControl {
    func hasRole(role: felt, account: felt) -> (res: felt) {
    }

    func onlyRole(role: felt, account: felt) {
    }

    func getContractAddress(contract_name: felt) -> (contract_address: felt) {
    }
}
