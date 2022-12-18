%lang starknet

@contract_interface
namespace IRandomConsumer {
    func fulfillRandom(request_id: felt, random: felt) {
    }
}
