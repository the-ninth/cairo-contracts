%lang starknet

@contract_interface
namespace IRandomConsumer {
    func fulfillRandomness(request_id: felt, randomness: felt) {
    }
}
