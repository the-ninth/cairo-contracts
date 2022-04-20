%lang starknet

@contract_interface
namespace IRandoomProducer:

    func requestRandom() -> (request_id: felt):
    end

    func triggerFulfill(request_id: felt):
    end

end