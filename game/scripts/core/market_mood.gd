extends Node

## Market Mood Engine. Reads real crypto price data from CraptoFeed
## and computes a global mood that affects NPC dialogue, economy tuning,
## and game difficulty. The heartbeat of the living world.

signal mood_changed(new_mood: String, severity: float)

enum Mood { EXTREME_BULL, BULL, NEUTRAL, BEAR, EXTREME_BEAR }

const MOOD_THRESHOLDS := {
	"extreme_bull": 0.20,   # +20% weekly
	"bull": 0.05,           # +5% weekly
	"neutral_upper": 0.05,
	"neutral_lower": -0.05,
	"bear": -0.20,          # -20% weekly
}

var current_mood: Mood = Mood.NEUTRAL
var mood_severity: float = 0.0  # -1.0 (extreme bear) to 1.0 (extreme bull)
var weekly_change_pct: float = 0.0

# NPC stat modifiers per mood
const NPC_MODIFIERS := {
	Mood.EXTREME_BULL: {"confidence": 1.5, "aggression": 0.7, "generosity": 1.8, "difficulty": 0.7},
	Mood.BULL: {"confidence": 1.2, "aggression": 0.9, "generosity": 1.3, "difficulty": 0.9},
	Mood.NEUTRAL: {"confidence": 1.0, "aggression": 1.0, "generosity": 1.0, "difficulty": 1.0},
	Mood.BEAR: {"confidence": 0.7, "aggression": 1.3, "generosity": 0.6, "difficulty": 1.2},
	Mood.EXTREME_BEAR: {"confidence": 0.3, "aggression": 1.8, "generosity": 0.2, "difficulty": 1.5},
}

# Dialogue mood tags
const DIALOGUE_TAGS := {
	Mood.EXTREME_BULL: ["manic", "reckless", "cocky", "invincible", "spending_freely"],
	Mood.BULL: ["optimistic", "hustling", "confident", "active"],
	Mood.NEUTRAL: ["standard", "normal", "steady"],
	Mood.BEAR: ["anxious", "defensive", "worried", "blaming", "paranoid"],
	Mood.EXTREME_BEAR: ["depressed", "hostile", "angry", "threatening", "desperate"],
}


func _ready() -> void:
	CraptoFeed.prices_updated.connect(_on_prices_updated)


func _on_prices_updated() -> void:
	weekly_change_pct = CraptoFeed.get_btc_weekly_change()
	_recalculate_mood()


func _recalculate_mood() -> void:
	var old_mood := current_mood

	if weekly_change_pct >= MOOD_THRESHOLDS["extreme_bull"]:
		current_mood = Mood.EXTREME_BULL
		mood_severity = clampf(weekly_change_pct / 0.4, 0.5, 1.0)
	elif weekly_change_pct >= MOOD_THRESHOLDS["bull"]:
		current_mood = Mood.BULL
		mood_severity = remap(weekly_change_pct, 0.05, 0.20, 0.1, 0.5)
	elif weekly_change_pct > MOOD_THRESHOLDS["neutral_lower"]:
		current_mood = Mood.NEUTRAL
		mood_severity = 0.0
	elif weekly_change_pct > MOOD_THRESHOLDS["bear"]:
		current_mood = Mood.BEAR
		mood_severity = remap(weekly_change_pct, -0.20, -0.05, -0.5, -0.1)
	else:
		current_mood = Mood.EXTREME_BEAR
		mood_severity = clampf(weekly_change_pct / -0.4, -1.0, -0.5)

	if current_mood != old_mood:
		mood_changed.emit(Mood.keys()[current_mood], mood_severity)


func get_npc_modifier(stat: String) -> float:
	var mods: Dictionary = NPC_MODIFIERS.get(current_mood, NPC_MODIFIERS[Mood.NEUTRAL])
	return mods.get(stat, 1.0)


func get_dialogue_tags() -> Array:
	return DIALOGUE_TAGS.get(current_mood, ["standard"])


func get_mood_name() -> String:
	return Mood.keys()[current_mood].to_lower().replace("_", " ")
