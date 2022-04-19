%lang starknet

# combat register for first relic combat

@contract_interface
namespace IFirstRelicCombatRegister:

    func register(combat_id: felt):
    end

    func getTotalRewards(combat_id: felt) -> ():
    end

    func distribute_rewards(combat_id: felt, )

end