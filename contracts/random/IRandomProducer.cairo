%lang starknet

@contract_interface
namespace IRandomProducer:

    func requestRandom() -> (request_id: felt):
    end

    func triggerFulfill(request_id: felt):
    end

end