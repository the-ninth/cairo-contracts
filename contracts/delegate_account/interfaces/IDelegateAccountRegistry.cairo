%lang starknet

@contract_interface
namespace IDelegateAccountRegistry {
    func setDelegateAccount(delegate_account: felt, actions_len: felt, actions: felt*) {
    }

    func getDelegateAccount(account: felt) -> (delegate_account: felt) {
    }

    func getAccount(delegate_account: felt) -> (account: felt) {
    }

    func removeDelegateAccount() {
    }

    func authorized(account: felt, delegate_account: felt, action: felt) -> (res: felt) {
    }
}
