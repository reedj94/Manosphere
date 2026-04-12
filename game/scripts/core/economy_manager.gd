extends Node

## Manages the dual currency economy, expenses, income sources,
## and the financial pressure that drives gameplay tension.

signal rent_due(amount: float, region: String)
signal expense_charged(category: String, amount: float)
signal income_received(source: String, amount: float)

const RENT_BY_REGION := {
	GameState.Region.CONSETT: 200.0,   # weekly bedsit
	GameState.Region.LONDON: 800.0,    # weekly flatshare
	GameState.Region.MIAMI: 2000.0,    # weekly condo
	GameState.Region.DUBAI: 8000.0,    # weekly penthouse
}

const TRAVEL_COSTS := {
	"consett_to_london": 200.0,
	"london_to_miami": 1500.0,
	"miami_to_dubai": 5000.0,
}

const RETURN_DISCOUNT := 0.5

# Currency symbols per region
const CURRENCY_SYMBOL := {
	GameState.Region.CONSETT: "£",
	GameState.Region.LONDON: "£",
	GameState.Region.MIAMI: "$",
	GameState.Region.DUBAI: "AED",
}

# Exchange rates (relative to GBP base)
const EXCHANGE_RATES := {
	GameState.Region.CONSETT: 1.0,
	GameState.Region.LONDON: 1.0,
	GameState.Region.MIAMI: 1.27,
	GameState.Region.DUBAI: 4.67,
}

var rent_timer: float = 0.0
const RENT_INTERVAL := 420.0  # 7 in-game days in seconds (scaled)


func _process(delta: float) -> void:
	rent_timer += delta
	if rent_timer >= RENT_INTERVAL:
		rent_timer = 0.0
		_charge_rent()


func _charge_rent() -> void:
	var region := GameState.current_region
	var amount: float = RENT_BY_REGION.get(region, 200.0)
	GameState.add_cash(-amount)
	rent_due.emit(amount, GameState.Region.keys()[region])
	expense_charged.emit("rent", amount)


func charge_expense(category: String, amount: float) -> void:
	GameState.add_cash(-amount)
	expense_charged.emit(category, amount)


func receive_income(source: String, amount: float) -> void:
	GameState.add_cash(amount)
	income_received.emit(source, amount)


func get_travel_cost(from_region: GameState.Region, to_region: GameState.Region) -> float:
	var key := "%s_to_%s" % [
		GameState.Region.keys()[from_region].to_lower(),
		GameState.Region.keys()[to_region].to_lower()
	]
	var reverse_key := "%s_to_%s" % [
		GameState.Region.keys()[to_region].to_lower(),
		GameState.Region.keys()[from_region].to_lower()
	]
	if TRAVEL_COSTS.has(key):
		return TRAVEL_COSTS[key]
	elif TRAVEL_COSTS.has(reverse_key):
		return TRAVEL_COSTS[reverse_key] * RETURN_DISCOUNT
	return 0.0


func format_currency(amount: float) -> String:
	var symbol: String = CURRENCY_SYMBOL.get(GameState.current_region, "£")
	if symbol == "AED":
		return "%s %.0f" % [symbol, amount * EXCHANGE_RATES[GameState.current_region]]
	return "%s%.0f" % [symbol, amount]
