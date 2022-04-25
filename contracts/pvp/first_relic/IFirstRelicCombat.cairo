%lang starknet

# combat for first relic

from contracts.pvp.first_relic.structs import Combat, Chest, Coordinate, Koma, ThirdStageAction

@contract_interface
namespace IFirstRelicCombat:

    func newCombat() -> (combat_id: felt):
    end

    func getCombatCount() -> (count: felt):
    end

    func getCombat(combat_id: felt) -> (combat: Combat):
    end

    func initPlayer(combat_id: felt, account: felt):
    end

    func getPlayersCount() -> (combat_id: felt, count: felt):
    end

    func getPlayers(combat_id: felt, offset: felt, length: felt) -> (players_len: felt, players: felt*):
    end

    func getKoma(combat_id: felt, account: felt) -> (koma: Koma):
    end

    func getKomas(combat_id: felt, accounts_len: felt, accounts: felt*) -> (komas_len: felt, komas: Koma*):
    end

    func getPlayerScore(combat_id: felt, account: felt) -> (score: felt):
    end

    func getPlayersScore(combat_id: felt, offset: felt, len: felt) -> (players_score_len: felt, players_score: felt*):
    end

    # first stage

    func getChestCount(combat_id: felt) -> (len: felt):
    end

    func getChests(combat_id: felt, offset: felt, length: felt) -> (data_len: felt, data: Chest*):
    end

    func getChestByCoordinate(combat_id, coordinate: Coordinate) -> (chest: Chest):
    end

    func move(combat_id: felt, account: felt, to: Coordinate):
    end

    func openChest(combat_id: felt, account: felt, target: Coordinate):
    end

    func mineOre(combat_id: felt, account: felt, target: Coordinate, workers_count: felt):
    end

    func recallWorks(commbat_id: felt, account: felt, target: Coordinate):
    end

    func attack(combat_id: felt, account: felt, target_account: felt):
    end

    func useProp(combat_id: felt, account: felt, prop_id: felt):
    end

    func produceWorkers(combat_id: felt, account: felt, quantity: felt):
    end

    func produceDrones(combat_id: felt, account: felt, quantity: felt):
    end

    func getAccountActualCoordinate(account: felt) -> (coordinate: Coordinate):
    end

    func reachStage2Circle(account: felt, to: Coordinate):
    end

    # second stage

    func enterRelicGate(account: felt, to: Coordinate):
    end

    # third stage

    func prepareAction(account: felt, action_hash: felt):
    end

    func confirmAction(account: felt, action: ThirdStageAction):
    end

end

#
# Events
#

@event
func CombatCreated(combat_id: felt, timestamp: felt):
end

@event
func CombatPreparing(combat_id: felt, timestamp: felt):
end

@event
func CombatFirstStageStart(combat_id: felt, timestamp: felt):
end

@event
func CombatSecondStageStart(combat_id: felt, timestamp: felt):
end

@event
func CombatThirdStageStart(combat_id: felt, timestamp: felt):
end

@event
func CombatEnd(combat_id: felt, timestamp: felt):
end

@event
func PlayerInit(combat_id: felt, account: felt, coordinate: Coordinate):
end

@event
func PlayerMove(combat_id: felt, account: felt, from_: Coordinate, to: Coordinate, start_timestamp: felt):
end

@event
func PlayerArrival(combat_id: felt, account: felt, from_: Coordinate, to: Coordinate, timestamp: felt):
end

@event
func PlayerAttack(combat_id: felt, account: felt, target_account: felt, hit_coordinate: felt):
end

@event
func PlayerDeath(combat_id: felt, account: felt, coordinate: felt):
end

@event
func PlayerReachStage2(combat_id: felt, account: felt, hit_coordinate: felt):
end

@event
func PlayerEnterRelicGate(combat_id: felt, account: felt, gate_id: felt):
end

@event
func PlayerAction(combat_id: felt, account: felt, action_id: felt, action: ThirdStageAction):
end

@event
func Stage3PlayerDeath(combat_id: felt, account: felt, killed_by: felt):
end