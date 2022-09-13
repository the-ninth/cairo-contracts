%lang starknet

struct Hero {
    address: felt,  // if address is 0 ,hero is boss
    health: felt,
    bear_from_hero: felt,
    bear_from_boss: felt,
    damage_to_hero: felt,
    damage_to_boss: felt,
    agility_next_hero: felt,  // agility_next_hero index
    damage_to_boss_next_hero: felt,  // damage_to_boss_next_hero index
    reward: felt,  // reward
}

struct Combat {
    combat_id: felt,
    meta_id: felt,
    boss_id: felt,
    round: felt,  // current round
    action_count: felt,  //
    init_hero_count: felt,  // init hero num
    cur_hero_count: felt,  // current hero num
    agility_1st: felt,
    damage_to_boss_1st: felt,
    start_time: felt,  // start time
    last_round_time: felt,  // start time
    end_info: felt,
}

struct Combat_meta {
    total_reward: felt,
    max_round_time: felt,
    max_round: felt,
    max_hero: felt,
}

struct Boss_meta {
    health: felt,
    defense: felt,
    agility: felt,
    atk: felt,
}

struct Action {
    hero_index: felt,
    type: felt,  // 1 hero->boss 2->hero-> hero 3. hero use game prop 4:boss->hero
    target: felt,  // type =1 :hero address type =2: prop type .
    damage: felt,
}
