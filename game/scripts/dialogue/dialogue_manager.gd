extends Node

## Dialogue system. Handles branching dialogue trees, stat checks,
## market-mood-modified NPC responses, and the manosphere phrase book.
## 80% scripted dialogue from JSON files, 20% AI-generated ambient chatter.

signal dialogue_started(npc_id: String)
signal dialogue_line(speaker: String, text: String, options: Array)
signal dialogue_ended(npc_id: String, outcome: String)
signal stat_check_result(stat: String, required: int, actual: int, passed: bool)
signal phrase_learned(phrase: String, tier: int)

enum DialogueOutcome { SUCCESS, PARTIAL, FAIL, CRINGE_FAIL }

# Loaded dialogue trees: npc_id -> dialogue data
var dialogue_trees: Dictionary = {}
var current_dialogue: Dictionary = {}
var current_node_id: String = ""
var is_in_dialogue: bool = false

# Manosphere phrase book (unlocked progressively)
var unlocked_phrases: Array[Dictionary] = []
const PHRASE_BOOK := {
	1: [  # Consett tier
		{"phrase": "I'm on my grindset", "charm": 1, "cringe": 2, "works_on": ["impressed_by_money"]},
		{"phrase": "You should invest in yourself", "charm": 2, "cringe": 1, "works_on": ["wannabe"]},
		{"phrase": "I don't watch TV, I watch market charts", "charm": 0, "cringe": 3, "works_on": ["impressed_by_money"]},
		{"phrase": "Early bird gets the worm, queen", "charm": 1, "cringe": 3, "works_on": []},
	],
	2: [  # London tier
		{"phrase": "Frame control is everything", "charm": 2, "cringe": 2, "works_on": ["impressed_by_money", "party_animal"]},
		{"phrase": "I'm a high-value individual", "charm": 1, "cringe": 4, "works_on": []},
		{"phrase": "My morning routine starts at 4am", "charm": 1, "cringe": 2, "works_on": ["wannabe"]},
		{"phrase": "Time is my most valuable asset", "charm": 2, "cringe": 1, "works_on": ["intellectual"]},
	],
	3: [  # Miami tier
		{"phrase": "I don't chase, I attract", "charm": 3, "cringe": 3, "works_on": ["party_animal"]},
		{"phrase": "Alpha energy, queen", "charm": 1, "cringe": 5, "works_on": []},
		{"phrase": "My passive income exceeds your salary", "charm": 0, "cringe": 5, "works_on": ["impressed_by_money"]},
		{"phrase": "Confidence isn't arrogance, it's awareness", "charm": 3, "cringe": 1, "works_on": ["intellectual", "skeptic"]},
	],
	4: [  # Dubai tier
		{"phrase": "What colour is YOUR Bugatti?", "charm": 0, "cringe": 10, "works_on": []},
		{"phrase": "I'm not arrogant, I'm aware of my value", "charm": 2, "cringe": 3, "works_on": ["impressed_by_money"]},
		{"phrase": "Breathing is a side hustle if you do it right", "charm": 0, "cringe": 8, "works_on": []},
		{"phrase": "The view's better from the top", "charm": 3, "cringe": 2, "works_on": ["party_animal", "wannabe"]},
	],
}

# NPC personality types and their responses
enum NpcPersonality { IMPRESSED_BY_MONEY, HATES_SHOWOFFS, INTELLECTUAL, PARTY_ANIMAL, SKEPTIC }

const PERSONALITY_REACTIONS := {
	NpcPersonality.IMPRESSED_BY_MONEY: {
		"weak_to": ["wealth_flex", "success_story", "crypto_talk"],
		"strong_against": ["emotional", "humble", "self_deprecating"],
	},
	NpcPersonality.HATES_SHOWOFFS: {
		"weak_to": ["humble", "humour", "self_deprecating"],
		"strong_against": ["wealth_flex", "bragging", "name_dropping"],
	},
	NpcPersonality.INTELLECTUAL: {
		"weak_to": ["smart_conversation", "philosophy", "self_aware"],
		"strong_against": ["gym_talk", "crypto_talk", "manosphere_script"],
	},
	NpcPersonality.PARTY_ANIMAL: {
		"weak_to": ["energy", "confidence", "fun"],
		"strong_against": ["serious", "philosophy", "business_pitch"],
	},
	NpcPersonality.SKEPTIC: {
		"weak_to": ["honesty", "self_aware", "vulnerability"],
		"strong_against": ["manosphere_script", "bragging", "pickup_line"],
	},
}


func _ready() -> void:
	_load_all_dialogue_files()


func _load_all_dialogue_files() -> void:
	var regions := ["consett", "london", "miami", "dubai", "shared"]
	for region in regions:
		var dir_path := "res://data/dialogue/%s/" % region
		var dir := DirAccess.open(dir_path)
		if not dir:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				_load_dialogue_file(dir_path + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()


func _load_dialogue_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Failed to parse dialogue: %s" % path)
		file.close()
		return
	file.close()

	var data: Dictionary = json.data
	var npc_id: String = data.get("npc_id", "")
	if npc_id != "":
		dialogue_trees[npc_id] = data


func start_dialogue(npc_id: String) -> void:
	if not dialogue_trees.has(npc_id):
		push_warning("No dialogue tree for NPC: %s" % npc_id)
		return

	current_dialogue = dialogue_trees[npc_id]
	current_node_id = current_dialogue.get("start_node", "start")
	is_in_dialogue = true
	dialogue_started.emit(npc_id)
	_present_current_node()


func select_option(option_index: int) -> void:
	if not is_in_dialogue:
		return

	var node: Dictionary = current_dialogue.get("nodes", {}).get(current_node_id, {})
	var options: Array = node.get("options", [])
	if option_index < 0 or option_index >= options.size():
		return

	var selected: Dictionary = options[option_index]

	# Apply stat effects
	if selected.has("stat_effects"):
		_apply_stat_effects(selected["stat_effects"])

	# Check for stat requirements
	if selected.has("requires"):
		var check := selected["requires"]
		var stat_name: String = check.get("stat", "")
		var required: int = check.get("value", 0)
		var actual: int = _get_stat_value(stat_name)
		var passed := actual >= required

		# Market mood modifies the check
		var mood_modifier: float = MarketMood.get_npc_modifier("difficulty")
		passed = actual >= int(required * mood_modifier)

		stat_check_result.emit(stat_name, required, actual, passed)

		if passed:
			current_node_id = selected.get("next_pass", selected.get("next", "end"))
		else:
			current_node_id = selected.get("next_fail", "end")
	else:
		current_node_id = selected.get("next", "end")

	# Track quest choices
	if selected.has("choice_id"):
		GameState.quest_choices[current_dialogue.get("quest_id", "")] = selected["choice_id"]

	# Track karma
	if selected.has("karma"):
		GameState.karma += selected["karma"]

	if current_node_id == "end" or not current_dialogue.get("nodes", {}).has(current_node_id):
		_end_dialogue(selected.get("outcome", "success"))
	else:
		_present_current_node()


func _present_current_node() -> void:
	var node: Dictionary = current_dialogue.get("nodes", {}).get(current_node_id, {})
	var speaker: String = node.get("speaker", "")
	var text: String = _apply_mood_variant(node)

	var options: Array[Dictionary] = []
	for opt in node.get("options", []):
		# Filter options based on unlocked phrases and stats
		if opt.has("requires_phrase_tier"):
			if GameState.pyramid_tier < opt["requires_phrase_tier"]:
				continue
		options.append({
			"text": opt.get("text", ""),
			"tags": opt.get("tags", []),
		})

	dialogue_line.emit(speaker, text, options)


func _apply_mood_variant(node: Dictionary) -> String:
	var mood_key: String = MarketMood.Mood.keys()[MarketMood.current_mood].to_lower()
	var variants: Dictionary = node.get("mood_variants", {})
	if variants.has(mood_key):
		return variants[mood_key]
	return node.get("text", "")


func _apply_stat_effects(effects: Dictionary) -> void:
	for stat in effects:
		match stat:
			"cash": GameState.add_cash(effects[stat])
			"respect": GameState.add_respect(effects[stat])
			"clout": GameState.add_clout(effects[stat])
			"awareness": GameState.awareness += effects[stat]
			"grotty_trust": GameState.grotty_trust += effects[stat]
			"real_one_relationship": GameState.real_one_relationship += effects[stat]


func _get_stat_value(stat_name: String) -> int:
	match stat_name:
		"cash": return int(GameState.cash)
		"respect": return GameState.respect
		"clout": return GameState.clout
		"testosterone": return int(GameState.testosterone_level)
		"hustle_knowledge": return GameState.hustle_knowledge
		"awareness": return GameState.awareness
		"pyramid_tier": return GameState.pyramid_tier
	return 0


func _end_dialogue(outcome: String) -> void:
	is_in_dialogue = false
	var npc_id: String = current_dialogue.get("npc_id", "")
	dialogue_ended.emit(npc_id, outcome)
	current_dialogue = {}
	current_node_id = ""


func get_unlocked_phrases() -> Array[Dictionary]:
	var phrases: Array[Dictionary] = []
	for tier in PHRASE_BOOK:
		if GameState.pyramid_tier >= tier:
			phrases.append_array(PHRASE_BOOK[tier])
	return phrases


func evaluate_phrase_on_npc(phrase: Dictionary, npc_personality: NpcPersonality) -> Dictionary:
	var charm: int = phrase.get("charm", 0)
	var cringe: int = phrase.get("cringe", 0)
	var personality_name: String = NpcPersonality.keys()[npc_personality].to_lower()

	var effectiveness := 0.0

	if personality_name in phrase.get("works_on", []):
		effectiveness = charm * 2.0 - cringe * 0.5
	else:
		effectiveness = charm * 0.5 - cringe * 2.0

	# Market mood affects NPC tolerance
	var confidence_mod: float = MarketMood.get_npc_modifier("confidence")
	effectiveness *= confidence_mod

	return {
		"score": effectiveness,
		"outcome": "success" if effectiveness > 3 else ("partial" if effectiveness > 0 else "cringe_fail"),
	}
