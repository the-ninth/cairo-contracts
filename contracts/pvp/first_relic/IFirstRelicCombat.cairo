%lang starknet

// combat for first relic

from contracts.pvp.first_relic.structs import (
    Combat,
    Chest,
    Coordinate,
    Koma,
    KomaEquipments,
    Movment,
    Ore,
    Prop,
    RelicGate,
    ThirdStageAction,
)

@contract_interface
namespace IFirstRelicCombat {
    func newCombat() -> (combat_id: felt) {
    }

    func getCombatCount() -> (count: felt) {
    }

    func getCombat(combat_id: felt) -> (combat: Combat) {
    }

    func initPlayer(combat_id: felt, account: felt) {
    }

    func getPlayersCount() -> (combat_id: felt, count: felt) {
    }

    func getPlayers(combat_id: felt, offset: felt, length: felt) -> (
        players_len: felt, players: felt*
    ) {
    }

    func getKoma(combat_id: felt, account: felt) -> (koma: Koma) {
    }

    func getKomas(combat_id: felt, accounts_len: felt, accounts: felt*) -> (
        komas_len: felt, komas: Koma*
    ) {
    }

    func getPlayerScore(combat_id: felt, account: felt) -> (score: felt) {
    }

    func getPlayersScore(combat_id: felt, offset: felt, len: felt) -> (
        players_score_len: felt, players_score: felt*
    ) {
    }

    // first stage

    func getChestCount(combat_id: felt) -> (len: felt) {
    }

    func getChests(combat_id: felt, offset: felt, length: felt) -> (data_len: felt, data: Chest*) {
    }

    func getChestByCoordinate(combat_id, coordinate: Coordinate) -> (chest: Chest) {
    }

    func getOreCount(combat_id: felt) -> (len: felt) {
    }

    func getOres(combat_id: felt, offset: felt, length: felt) -> (ores_len: felt, ores: Ore*) {
    }

    func getOreByCoordinate(combat_id, coordinate: Coordinate) -> (ore: Ore) {
    }

    func move(combat_id: felt, account: felt, to: Coordinate) {
    }

    func getKomasMovments(combat_id: felt, accounts_len: felt, accounts: felt*) -> (
        movments_len: felt, movments: Movment*
    ) {
    }

    func openChest(combat_id: felt, account: felt, target: Coordinate) {
    }

    func selectChestOption(combat_id: felt, account: felt, target: Coordinate, option: felt) {
    }

    func mineOre(combat_id: felt, account: felt, target: Coordinate, workers_count: felt) {
    }

    func recallWorkers(commbat_id: felt, account: felt, target: Coordinate) {
    }

    func produceBot(combat_id: felt, account: felt, bot_type: felt, quantity: felt) {
    }

    func attack(combat_id: felt, account: felt, target_account: felt) {
    }

    func getKomaProps(combat_id: felt, account: felt) -> (props_len: felt, props: Prop*) {
    }

    func getProp(combat_id: felt, prop_id: felt) -> (res: (felt, Prop)) {
    }

    func getKomaEquipments(combat_id: felt, account: felt) -> (equipments: KomaEquipments) {
    }

    func useProp(combat_id: felt, account: felt, prop_id: felt) {
    }

    func equipProp(combat_id: felt, account: felt, prop_id: felt) {
    }

    func getAccountActualCoordinate(account: felt) -> (coordinate: Coordinate) {
    }

    func reachStage2Circle(account: felt, to: Coordinate) {
    }

    // second stage

    func enterRelicGate(combat_id: felt, account: felt, to: Coordinate, prop_id: felt) {
    }

    func getRelicGate(combat_id: felt, number: felt) -> (relic_gate: RelicGate) {
    }

    func getRelicGates(combat_id: felt) -> (relic_gates_len: felt, relic_gates: RelicGate*) {
    }

    // third stage

    func prepareAction(account: felt, action_hash: felt) {
    }

    func confirmAction(account: felt, action: ThirdStageAction) {
    }
}

//
// Events
//

@event
func CombatCreated(combat_id: felt, timestamp: felt) {
}

@event
func CombatPreparing(combat_id: felt, timestamp: felt) {
}

@event
func CombatFirstStageStart(combat_id: felt, timestamp: felt) {
}

@event
func CombatSecondStageStart(combat_id: felt, timestamp: felt) {
}

@event
func CombatThirdStageStart(combat_id: felt, timestamp: felt) {
}

@event
func CombatEnd(combat_id: felt, timestamp: felt) {
}

@event
func PlayerInit(combat_id: felt, account: felt, coordinate: Coordinate) {
}

@event
func PlayerMove(
    combat_id: felt, account: felt, from_: Coordinate, to: Coordinate, start_timestamp: felt
) {
}

@event
func PlayerArrival(
    combat_id: felt, account: felt, from_: Coordinate, to: Coordinate, timestamp: felt
) {
}

@event
func PlayerAttack(
    combat_id: felt, account: felt, target_account: felt, damage: felt, koma_attacked_status: felt
) {
}

@event
func PlayerDeath(combat_id: felt, account: felt) {
}

@event
func PlayerReachStage2(combat_id: felt, account: felt, hit_coordinate: felt) {
}

@event
func PlayerEnterRelicGate(combat_id: felt, account: felt, gate_id: felt) {
}

@event
func PlayerAction(combat_id: felt, account: felt, action_id: felt, action: ThirdStageAction) {
}

@event
func Stage3PlayerDeath(combat_id: felt, account: felt, killed_by: felt) {
}
