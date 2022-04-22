%lang starknet

@contract_interface
namespace IAccessControl:

    func hasRole(role: felt, account: felt) -> (res: felt):
    end

    func onlyRole(role: felt, account: felt):
    end

    func ninthContract() -> (contract: felt):
    end

    func noahContract() -> (contract: felt):
    end

    func stoneContract() -> (contract: felt):
    end

    func farmerContract() -> (contract: felt):
    end

    func landContract() -> (contract: felt):
    end

    func randomProducerContract() -> (contract: felt):
    end

    func frCombatRegisterContract() -> (contract: felt):
    end

    func frCombatContract() -> (contract: felt):
    end

end