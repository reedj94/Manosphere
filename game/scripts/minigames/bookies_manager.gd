extends Node

## Bookies minigame system — horse racing and Extreme Sumo Showdown.
## Called by POI interaction when player enters a bookies.

signal race_started(race_type: String)
signal race_finished(race_type: String, winner: String, player_won: bool)
signal bet_placed(race_type: String, selection: String, amount: float)

enum RaceType { HORSE_RACING, SUMO_WRESTLING }

const HORSE_NAMES: Array[String] = [
	"Grindset Gary", "Sigma Stallion", "Passive Income Pete",
	"Hustle Horse", "Diamond Hooves", "Side Hustle Sally",
	"Crypto Canter", "Alpha Trot", "Leverage Larry",
	"Pump N Dump", "Moon Runner", "Bear Market Bob",
]

const SUMO_NAMES: Array[String] = [
	"The Absolute Unit", "Belly of the Beast", "Protein Tsunami",
	"Bulk Buy Barry", "The Flabbergaster", "Creatine Thunder",
	"Gut Feeling", "Mass Gainer Mike", "The Wide Boy",
	"Sumo Salesforce", "Heavy Leverage", "The Big Short",
]

var current_bet_amount: float = 0.0
var current_bet_selection: String = ""
var current_race_type: int = -1
var race_in_progress: bool = false


func get_race_runners(race_type: int, count: int = 6) -> Array[Dictionary]:
	var names: Array[String] = HORSE_NAMES if race_type == RaceType.HORSE_RACING else SUMO_NAMES
	var pool := names.duplicate()
	pool.shuffle()

	var runners: Array[Dictionary] = []
	for i in range(mini(count, pool.size())):
		var base_speed: float = randf_range(0.6, 1.4)
		var odds: float = _calculate_odds(base_speed)
		runners.append({
			"name": pool[i],
			"base_speed": base_speed,
			"odds": odds,
			"odds_display": _format_odds(odds),
			"form": _generate_form(),
		})

	runners.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["odds"] < b["odds"])
	return runners


func place_bet(race_type: int, selection: String, amount: float) -> bool:
	if amount <= 0.0 or amount > GameState.cash:
		return false
	if race_in_progress:
		return false

	current_race_type = race_type
	current_bet_selection = selection
	current_bet_amount = amount
	GameState.add_cash(-amount)
	bet_placed.emit(RaceType.keys()[race_type], selection, amount)
	return true


func run_race(runners: Array[Dictionary]) -> Dictionary:
	race_in_progress = true
	var race_type_name: String = RaceType.keys()[current_race_type]
	race_started.emit(race_type_name)

	var results: Array[Dictionary] = []
	for runner in runners:
		var base: float = runner["base_speed"]
		var luck: float = randf_range(0.5, 1.5)
		var mood_mod: float = MarketMood.get_npc_modifier("confidence")
		var final_score: float = base * luck * mood_mod
		results.append({
			"name": runner["name"],
			"score": final_score,
			"odds": runner["odds"],
		})

	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])

	var winner_name: String = results[0]["name"]
	var player_won := winner_name == current_bet_selection

	if player_won:
		var winner_odds: float = results[0]["odds"]
		var winnings: float = current_bet_amount * winner_odds
		GameState.add_cash(winnings)
		GameState.add_respect(int(winnings * 0.1))

	race_in_progress = false
	race_finished.emit(race_type_name, winner_name, player_won)

	return {
		"results": results,
		"winner": winner_name,
		"player_won": player_won,
		"payout": current_bet_amount * results[0]["odds"] if player_won else 0.0,
		"bet_amount": current_bet_amount,
	}


func _calculate_odds(base_speed: float) -> float:
	var raw: float = 1.0 / base_speed
	return snapped(clampf(raw * 3.0, 1.5, 25.0), 0.5)


func _format_odds(odds: float) -> String:
	if odds <= 2.0:
		return "%d/%d" % [int(odds - 1.0) * 1, 1]
	elif odds <= 5.0:
		return "%d/1" % [int(odds - 1.0)]
	else:
		return "%d/1" % [int(odds)]


func _generate_form() -> String:
	var chars := ["W", "W", "L", "L", "P", "P", "-"]
	var form := ""
	for i in range(5):
		form += chars[randi() % chars.size()]
	return form
