%lang starknet

@contract_interface
namespace IRandomProducer {
    func requestRandom() -> (request_id: felt) {
    }

    func triggerFulfill(request_id: felt) {
    }
}
