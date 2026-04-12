extends Node

## Bot scripting engine. Runs player-written Lua scripts via embedded
## LuaJIT runtime with a sandboxed CraptoScript API layer.
## Supports backtesting, paper trading, and live execution.

signal bot_started(bot_name: String)
signal bot_stopped(bot_name: String)
signal bot_error(bot_name: String, error: String)
signal bot_trade(bot_name: String, action: String, ticker: String, amount: float)

enum BotMode { LIVE, PAPER, BACKTEST }

const BOT_DIR := "user://bots/"
const MAX_ACTIVE_BOTS := 5
const BOT_TICK_INTERVAL := 5.0  # seconds between bot evaluations

var active_bots: Dictionary = {}  # name -> {script, mode, paper_portfolio, state}
var bot_timer: float = 0.0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(BOT_DIR)


func _process(delta: float) -> void:
	bot_timer += delta
	if bot_timer >= BOT_TICK_INTERVAL:
		bot_timer = 0.0
		_tick_all_bots()


func load_bot(bot_name: String) -> String:
	var path := BOT_DIR + bot_name + ".lua"
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	var script := file.get_as_text()
	file.close()
	return script


func save_bot(bot_name: String, script: String) -> void:
	var path := BOT_DIR + bot_name + ".lua"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(script)
	file.close()


func start_bot(bot_name: String, mode: BotMode = BotMode.PAPER) -> bool:
	if active_bots.size() >= MAX_ACTIVE_BOTS:
		bot_error.emit(bot_name, "Max active bots reached (%d)" % MAX_ACTIVE_BOTS)
		return false

	var script := load_bot(bot_name)
	if script == "":
		bot_error.emit(bot_name, "Bot script not found")
		return false

	active_bots[bot_name] = {
		"script": script,
		"mode": mode,
		"paper_portfolio": {},
		"paper_cash": GameState.cash if mode == BotMode.PAPER else 0.0,
		"state": {},
		"trades": [],
		"pnl": 0.0,
	}

	bot_started.emit(bot_name)
	return true


func stop_bot(bot_name: String) -> void:
	if active_bots.has(bot_name):
		active_bots.erase(bot_name)
		bot_stopped.emit(bot_name)


func _tick_all_bots() -> void:
	for bot_name in active_bots:
		_execute_bot(bot_name)


func _execute_bot(bot_name: String) -> void:
	var bot: Dictionary = active_bots[bot_name]
	# TODO: integrate LuaJIT runtime (via GDExtension addon)
	# For now, evaluate simple condition-action rules parsed from script
	var result := _parse_and_evaluate(bot["script"], bot["state"])
	for action in result.get("actions", []):
		_execute_action(bot_name, action)


func _parse_and_evaluate(script: String, state: Dictionary) -> Dictionary:
	# Simplified rule parser for pre-Lua prototype
	# Parses CraptoScript-style rules:
	#   ON ema(50) CROSSES_ABOVE ema(200): BUY 10% OF PORTFOLIO
	#   ON rsi(14) > 80: SELL 50% OF $BCON
	var actions: Array[Dictionary] = []
	# TODO: implement full Lua VM integration
	return {"actions": actions, "state": state}


func _execute_action(bot_name: String, action: Dictionary) -> void:
	var bot: Dictionary = active_bots[bot_name]
	var mode: BotMode = bot["mode"]

	match action.get("type", ""):
		"buy":
			if mode == BotMode.LIVE:
				if CraptoFeed.buy(action["ticker"], action["amount"]):
					bot_trade.emit(bot_name, "BUY", action["ticker"], action["amount"])
			else:
				bot_trade.emit(bot_name, "PAPER_BUY", action["ticker"], action["amount"])
		"sell":
			if mode == BotMode.LIVE:
				if CraptoFeed.sell(action["ticker"], action["amount"]):
					bot_trade.emit(bot_name, "SELL", action["ticker"], action["amount"])
			else:
				bot_trade.emit(bot_name, "PAPER_SELL", action["ticker"], action["amount"])


# --- Technical Indicator Calculations (exposed to Lua as CraptoScript API) ---

func calculate_ema(ticker: String, period: int) -> float:
	var history: Array = CraptoFeed.price_history.get(ticker, [])
	if history.size() < period:
		return 0.0

	var multiplier := 2.0 / (period + 1.0)
	var ema: float = history[-period]["close"]
	for i in range(history.size() - period + 1, history.size()):
		ema = (history[i]["close"] - ema) * multiplier + ema
	return ema


func calculate_sma(ticker: String, period: int) -> float:
	var history: Array = CraptoFeed.price_history.get(ticker, [])
	if history.size() < period:
		return 0.0

	var total := 0.0
	for i in range(history.size() - period, history.size()):
		total += history[i]["close"]
	return total / period


func calculate_rsi(ticker: String, period: int = 14) -> float:
	var history: Array = CraptoFeed.price_history.get(ticker, [])
	if history.size() < period + 1:
		return 50.0

	var gains := 0.0
	var losses := 0.0
	for i in range(history.size() - period, history.size()):
		var change: float = history[i]["close"] - history[i - 1]["close"]
		if change > 0:
			gains += change
		else:
			losses += abs(change)

	if losses == 0:
		return 100.0
	var rs := (gains / period) / (losses / period)
	return 100.0 - (100.0 / (1.0 + rs))


func calculate_macd(ticker: String, fast: int = 12, slow: int = 26, signal_period: int = 9) -> Dictionary:
	var fast_ema := calculate_ema(ticker, fast)
	var slow_ema := calculate_ema(ticker, slow)
	var macd_line := fast_ema - slow_ema
	# Signal line would need its own EMA history; simplified for now
	return {"macd": macd_line, "signal": 0.0, "histogram": macd_line}


func calculate_bollinger(ticker: String, period: int = 20, std_dev: float = 2.0) -> Dictionary:
	var history: Array = CraptoFeed.price_history.get(ticker, [])
	if history.size() < period:
		return {"upper": 0.0, "middle": 0.0, "lower": 0.0}

	var sma := calculate_sma(ticker, period)
	var variance := 0.0
	for i in range(history.size() - period, history.size()):
		variance += pow(history[i]["close"] - sma, 2)
	variance /= period
	var sd := sqrt(variance)

	return {
		"upper": sma + std_dev * sd,
		"middle": sma,
		"lower": sma - std_dev * sd,
	}


func get_bot_list() -> Array[String]:
	var bots: Array[String] = []
	var dir := DirAccess.open(BOT_DIR)
	if not dir:
		return bots
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".lua"):
			bots.append(file_name.trim_suffix(".lua"))
		file_name = dir.get_next()
	dir.list_dir_end()
	return bots
