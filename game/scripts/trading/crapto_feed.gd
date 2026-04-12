extends Node

## Crapto price feed engine. Fetches real crypto prices via CoinGecko API,
## transforms them into in-game parody coin prices, and provides the data
## backbone for the trading terminal, market mood, and NPC behaviour.
##
## Offline mode: generates convincing Brownian motion price action seeded
## from the last known real price state.

signal prices_updated
signal connection_status_changed(online: bool)

const API_BASE := "https://api.coingecko.com/api/v3"
const UPDATE_INTERVAL := 30.0  # seconds between price fetches
const HISTORY_LENGTH := 1440   # 24 hours of minute candles

# Real coin -> In-game coin mapping
const COIN_MAP := {
	"bitcoin":       {"name": "BitCon",       "ticker": "BCON",  "scale": 0.001,  "unlock_region": GameState.Region.CONSETT},
	"ethereum":      {"name": "Etherium",     "ticker": "EETH",  "scale": 0.01,   "unlock_region": GameState.Region.CONSETT},
	"solana":        {"name": "Solame",        "ticker": "SLME",  "scale": 0.1,    "unlock_region": GameState.Region.CONSETT},
	"dogecoin":      {"name": "Dogshit",       "ticker": "DGST",  "scale": 10.0,   "unlock_region": GameState.Region.LONDON},
	"ripple":        {"name": "ExRipOff",      "ticker": "XRPO",  "scale": 1.0,    "unlock_region": GameState.Region.LONDON},
	"shiba-inu":     {"name": "Shiba Scamu",   "ticker": "SSCM",  "scale": 100000, "unlock_region": GameState.Region.MIAMI},
	"cardano":       {"name": "Cardaknow",     "ticker": "CKNW",  "scale": 1.0,    "unlock_region": GameState.Region.MIAMI},
	"polkadot":      {"name": "Polkascam",     "ticker": "PSCM",  "scale": 0.5,    "unlock_region": GameState.Region.DUBAI},
}

var http_request: HTTPRequest
var update_timer: float = 0.0
var is_online: bool = false

# Current prices: ticker -> {price, change_1h, change_24h, change_7d, volume}
var current_prices: Dictionary = {}
# Price history: ticker -> Array of {timestamp, open, high, low, close, volume}
var price_history: Dictionary = {}
# Player portfolio: ticker -> {amount, avg_buy_price}
var portfolio: Dictionary = {}
# Order book: Array of {type, ticker, amount, price, stop_loss, take_profit}
var open_orders: Array[Dictionary] = []

# Offline simulation state
var offline_prices: Dictionary = {}
var offline_seed: int = 0
var volatility_multiplier: float = 1.0


func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	for coin_id in COIN_MAP:
		var info: Dictionary = COIN_MAP[coin_id]
		current_prices[info["ticker"]] = {"price": 0.0, "change_1h": 0.0, "change_24h": 0.0, "change_7d": 0.0}
		price_history[info["ticker"]] = []
		portfolio[info["ticker"]] = {"amount": 0.0, "avg_buy_price": 0.0}

	_fetch_prices()


func _process(delta: float) -> void:
	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		if is_online:
			_fetch_prices()
		else:
			_simulate_offline_tick()


func _fetch_prices() -> void:
	var coin_ids := ",".join(COIN_MAP.keys())
	var url := "%s/simple/price?ids=%s&vs_currencies=gbp&include_24hr_change=true&include_7d_change=true&include_1hr_change=true" % [API_BASE, coin_ids]
	http_request.request(url)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		if is_online:
			is_online = false
			connection_status_changed.emit(false)
			_init_offline_simulation()
		return

	if not is_online:
		is_online = true
		connection_status_changed.emit(true)

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return

	var data: Dictionary = json.data
	for coin_id in data:
		if not COIN_MAP.has(coin_id):
			continue
		var info: Dictionary = COIN_MAP[coin_id]
		var ticker: String = info["ticker"]
		var real_price: float = data[coin_id].get("gbp", 0.0)
		var scale: float = info["scale"]

		var game_price: float = real_price * scale * volatility_multiplier
		game_price += _noise(ticker.hash())

		current_prices[ticker] = {
			"price": game_price,
			"change_1h": data[coin_id].get("gbp_1h_change", 0.0),
			"change_24h": data[coin_id].get("gbp_24h_change", 0.0),
			"change_7d": data[coin_id].get("gbp_7d_change", 0.0),
		}

		_add_candle(ticker, game_price)

	_process_open_orders()
	prices_updated.emit()


func _noise(seed_val: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val + Time.get_ticks_msec()
	return rng.randf_range(-0.5, 0.5)


func _add_candle(ticker: String, price: float) -> void:
	var candle := {
		"timestamp": Time.get_unix_time_from_system(),
		"open": price,
		"high": price,
		"low": price,
		"close": price,
		"volume": randf_range(100, 10000),
	}

	var history: Array = price_history.get(ticker, [])
	if history.size() > 0:
		var last: Dictionary = history[-1]
		candle["open"] = last["close"]
		candle["high"] = maxf(candle["open"], price)
		candle["low"] = minf(candle["open"], price)

	history.append(candle)
	if history.size() > HISTORY_LENGTH:
		history.pop_front()
	price_history[ticker] = history


# --- Offline simulation (Geometric Brownian Motion) ---

func _init_offline_simulation() -> void:
	offline_seed = Time.get_ticks_msec()
	for ticker in current_prices:
		offline_prices[ticker] = current_prices[ticker]["price"]


func _simulate_offline_tick() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = offline_seed
	offline_seed += 1

	for ticker in offline_prices:
		var price: float = offline_prices[ticker]
		var drift := 0.0001
		var vol := 0.02 * volatility_multiplier
		var dt := UPDATE_INTERVAL / 86400.0
		var z := rng.randfn(0.0, 1.0)
		price *= exp((drift - 0.5 * vol * vol) * dt + vol * sqrt(dt) * z)
		price = maxf(price, 0.01)

		offline_prices[ticker] = price
		current_prices[ticker]["price"] = price
		_add_candle(ticker, price)

	prices_updated.emit()


# --- Trading interface ---

func buy(ticker: String, amount: float) -> bool:
	var price: float = current_prices.get(ticker, {}).get("price", 0.0)
	if price <= 0 or amount <= 0:
		return false
	var cost := price * amount
	if cost > GameState.cash:
		return false

	GameState.add_cash(-cost)
	var pos: Dictionary = portfolio.get(ticker, {"amount": 0.0, "avg_buy_price": 0.0})
	var total_cost := pos["avg_buy_price"] * pos["amount"] + cost
	pos["amount"] += amount
	pos["avg_buy_price"] = total_cost / pos["amount"] if pos["amount"] > 0 else 0.0
	portfolio[ticker] = pos
	return true


func sell(ticker: String, amount: float) -> bool:
	var price: float = current_prices.get(ticker, {}).get("price", 0.0)
	var pos: Dictionary = portfolio.get(ticker, {"amount": 0.0, "avg_buy_price": 0.0})
	if price <= 0 or amount <= 0 or amount > pos["amount"]:
		return false

	var revenue := price * amount
	GameState.add_cash(revenue)
	pos["amount"] -= amount
	if pos["amount"] <= 0.001:
		pos["amount"] = 0.0
		pos["avg_buy_price"] = 0.0
	portfolio[ticker] = pos
	return true


func place_order(type: String, ticker: String, amount: float, trigger_price: float, stop_loss: float = 0.0, take_profit: float = 0.0) -> void:
	open_orders.append({
		"type": type,
		"ticker": ticker,
		"amount": amount,
		"trigger_price": trigger_price,
		"stop_loss": stop_loss,
		"take_profit": take_profit,
	})


func _process_open_orders() -> void:
	var filled: Array[int] = []
	for i in open_orders.size():
		var order: Dictionary = open_orders[i]
		var price: float = current_prices.get(order["ticker"], {}).get("price", 0.0)
		if order["type"] == "limit_buy" and price <= order["trigger_price"]:
			if buy(order["ticker"], order["amount"]):
				filled.append(i)
		elif order["type"] == "limit_sell" and price >= order["trigger_price"]:
			if sell(order["ticker"], order["amount"]):
				filled.append(i)
		elif order["type"] == "stop_loss" and price <= order["trigger_price"]:
			if sell(order["ticker"], order["amount"]):
				filled.append(i)

	filled.reverse()
	for idx in filled:
		open_orders.remove_at(idx)


func get_portfolio_value() -> float:
	var total := 0.0
	for ticker in portfolio:
		total += portfolio[ticker]["amount"] * current_prices.get(ticker, {}).get("price", 0.0)
	return total


func get_portfolio_pnl() -> float:
	var pnl := 0.0
	for ticker in portfolio:
		var pos: Dictionary = portfolio[ticker]
		if pos["amount"] > 0:
			var current_val := pos["amount"] * current_prices.get(ticker, {}).get("price", 0.0)
			var cost_basis := pos["amount"] * pos["avg_buy_price"]
			pnl += current_val - cost_basis
	return pnl


func get_btc_weekly_change() -> float:
	return current_prices.get("BCON", {}).get("change_7d", 0.0) / 100.0


func get_available_coins() -> Array[String]:
	var available: Array[String] = []
	for coin_id in COIN_MAP:
		var info: Dictionary = COIN_MAP[coin_id]
		if info["unlock_region"] in GameState.unlocked_regions:
			available.append(info["ticker"])
	return available


func get_coin_name(ticker: String) -> String:
	for coin_id in COIN_MAP:
		if COIN_MAP[coin_id]["ticker"] == ticker:
			return COIN_MAP[coin_id]["name"]
	return ticker


func get_portfolio_data() -> Dictionary:
	return {
		"portfolio": portfolio,
		"open_orders": open_orders,
	}
