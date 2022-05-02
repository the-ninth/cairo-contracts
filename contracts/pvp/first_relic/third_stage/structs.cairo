%lang starknet

struct Hero:
    member address : felt  # if address is 0 ,hero is boss
    member health : felt
    member defense : felt
    member agility : felt
    member bear_from_hero : felt
    member bear_from_boss : felt
    member damage_to_hero : felt
    member damage_to_boss : felt
    member next_hero_index : felt
    member robots : felt
end

struct Combat:
    member combat_id : felt
    member meta_id : felt
    member boss_id : felt
    member total_reward : felt  #
    member round : felt  # current round
    member action_count : felt  #
    member hero_count : felt  # current hero num
    member hero_1th : felt
    member start_time : felt  # start time
    member last_combat_time : felt  # start time
    member end_info : felt
end

struct Combat_meta:
    member total_reward : felt
    member max_round_time : felt
    member max_round : felt
    member max_hero : felt
end

struct Boss_meta:
    member health : felt
    member defense : felt
    member agility : felt
end

struct Action:
    member hero_index : felt
    member type : felt  # 1 hero->boss 2->hero-> hero 3. hero use game prop 4:boss->hero
    member target : felt  # type =1 :hero address type =2: prop type .
    member damage : felt
end
