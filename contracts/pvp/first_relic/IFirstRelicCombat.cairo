%lang starknet

# combat for first relic

from contracts.pvp.first_relic.structs import (
    Combat,
    Chest,
    Coordinate,
    Koma,
    KomaEquipments,
    KomaMiningOre,
    Movment,
    Ore,
    Prop,
    RelicGate,
    ThirdStageAction
)

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

    func getOreCount(combat_id: felt) -> (len: felt):
    end

    func getOres(combat_id: felt, offset: felt, length: felt) -> (ores_len: felt, ores: Ore*):
    end

    func getOreByCoordinate(combat_id, coordinate: Coordinate) -> (ore: Ore):
    end

    func move(combat_id: felt, account: felt, to: Coordinate):
    end

    func getKomasMovments(combat_id: felt, accounts_len: felt, accounts: felt*) -> (movments_len: felt, movments: Movment*):
    end

    func openChest(combat_id: felt, account: felt, target: Coordinate):
    end

    func selectChestOption(combat_id: felt, account: felt, target: Coordinate, option: felt):
    end

    func mineOre(combat_id: felt, account: felt, target: Coordinate, workers_count: felt):
    end

    func recallWorkers(commbat_id: felt, account: felt, target: Coordinate):
    end

    func produceBot(combat_id: felt, account: felt, bot_type: felt, quantity: felt):
    end

    func getKomaMiningOres(combat_id: felt, account: felt) -> (mining_ores_len: felt, mining_ores: KomaMiningOre*):
    end

    func attack(combat_id: felt, account: felt, target_account: felt):
    end

    func getKomaProps(combat_id: felt, account: felt) -> (props_len: felt, props: Prop*):
    end

    func getProp(combat_id: felt, prop_id: felt) -> (res: (felt, Prop)):
    end

    func getKomaEquipments(combat_id: felt, account: felt) -> (equipments: KomaEquipments):
    end

    func useProp(combat_id: felt, account: felt, prop_id: felt):
    end

    func equipProp(combat_id: felt, account: felt, prop_id: felt):
    end

    func getAccountActualCoordinate(account: felt) -> (coordinate: Coordinate):
    end

    func reachStage2Circle(account: felt, to: Coordinate):
    end

    # second stage

    func enterRelicGate(combat_id: felt, account: felt, to: Coordinate, prop_id: felt):
    end

    func getRelicGate(combat_id: felt, number: felt) -> (relic_gate: RelicGate):
    end

    func getRelicGates(combat_id: felt) -> (relic_gates_len: felt, relic_gates: RelicGate*):
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
func PlayerAttack(combat_id: felt, account: felt, target_account: felt, damage: felt, koma_attacked_status: felt):
end

@event
func PlayerDeath(combat_id: felt, account: felt):
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