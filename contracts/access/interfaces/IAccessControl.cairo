%lang starknet

@contract_interface
namespace IAccessControl:

    func hasRole(role: felt, account: felt) -> (res: felt):
    end

    func onlyRole(role: felt, account: felt):
    end

    func getContractAddress(contract_name: felt) -> (contract_address: felt):
    end

end