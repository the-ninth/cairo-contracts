%lang starknet

@contract_interface
namespace IAccessControl:

    func hasRole(role: felt, account: felt) -> (res: felt):
    end

    func onlyRole(role: felt, account: felt):
    end

    func coinContract() -> (contract: felt):
    end

    func diamondContract() -> (contract: felt):
    end

    func oreContract() -> (contract: felt):
    end

    func farmerContract() -> (contract: felt):
    end

    func landContract() -> (contract: felt):
    end

end