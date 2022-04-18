%lang starknet

@contract_interface
namespace IDelegateAccountRegistry:

    func setDelegateAccount(delegate_account: felt):
    end

    func getDelegateAccount(account: felt) -> (delegate_account: felt):
    end

    func getAccount(delegate_account: felt) -> (account: felt):
    end

    func removeDelegateAccount():
    end

    func authorized(account: felt, delegate_account: felt, action: felt) -> felt:
    end

end