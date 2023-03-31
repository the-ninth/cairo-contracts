%lang starknet

@contract_interface
namespace IRandomProducer {
    func requestRandom() -> (request_id: felt) {
    }

    func fulfill(request_id: felt, randomness: felt) {
    }
}
