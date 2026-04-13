extends Node

## Character manager. Loads character definitions from JSON, generates
## random civilians from templates, and provides character data to the
## world scripts for spawning 3D models.

signal character_loaded(char_id: String)

const LEADERS_PATH := "res://data/characters/faction_leaders.json"
const KEY_NPCS_PATH := "res://data/characters/key_npcs.json"
const TEMPLATES_PATH := "res://data/characters/civilian_templates.json"

var characters: Dictionary = {}
var civilian_templates: Dictionary = {}


func _ready() -> void:
	_load_json_characters(LEADERS_PATH)
	_load_json_characters(KEY_NPCS_PATH)
	_load_templates(TEMPLATES_PATH)


func _load_json_characters(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("CharacterManager: Failed to parse %s" % path)
		file.close()
		return
	file.close()

	var data: Dictionary = json.data
	var char_list: Array = data.get("characters", [])
	for c in char_list:
		var cid: String = c.get("id", "")
		if cid != "":
			characters[cid] = c
			character_loaded.emit(cid)


func _load_templates(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	civilian_templates = json.data.get("templates", {})


func get_character(char_id: String) -> Dictionary:
	return characters.get(char_id, {})


func get_all_for_region(region_name: String) -> Array:
	var result: Array = []
	for cid in characters:
		var c: Dictionary = characters[cid]
		var r: String = c.get("region", "")
		if r == region_name or r == "all":
			result.append(c)
	return result


func generate_random_civilian(region_name: String) -> Dictionary:
	var templates: Array = civilian_templates.get(region_name, [])
	if templates.is_empty():
		return {}

	var tmpl: Dictionary = templates[0]
	var base_models: Array = tmpl.get("base_models", ["male_average"])
	var tops: Array = tmpl.get("tops", [])
	var top_colours: Array = tmpl.get("top_colours", [])
	var bottoms: Array = tmpl.get("bottoms", [])
	var bottom_colours: Array = tmpl.get("bottom_colours", [])
	var shoes: Array = tmpl.get("shoes", [])
	var hats: Array = tmpl.get("hats", [])
	var accessories: Array = tmpl.get("accessories", [])
	var hair_m: Array = tmpl.get("hair_m", ["buzz_cut"])
	var hair_f: Array = tmpl.get("hair_f", ["ponytail_tight"])
	var beards: Array = tmpl.get("beards", ["none"])
	var h_range: Array = tmpl.get("height_range", [0.9, 1.1])
	var w_range: Array = tmpl.get("width_range", [0.85, 1.15])

	var base: String = base_models[randi() % base_models.size()]
	var is_female := base.begins_with("female")
	var id_prefix: String = tmpl.get("id_prefix", "civ")

	return {
		"id": "%s_%d" % [id_prefix, randi() % 99999],
		"display_name": "",
		"role": "civilian",
		"region": region_name,
		"base_model": base,
		"body": {
			"height": randf_range(h_range[0], h_range[1]),
			"width": randf_range(w_range[0], w_range[1]),
			"head_scale": randf_range(1.0, 1.15),
			"arm_length": randf_range(0.95, 1.05),
			"leg_length": randf_range(0.95, 1.05),
		},
		"face": {
			"skin_tone": _random_skin_tone(),
			"beard": "none" if is_female else beards[randi() % beards.size()],
			"hair": (hair_f if is_female else hair_m)[randi() % (hair_f if is_female else hair_m).size()],
			"hair_colour": _random_hair_colour(),
			"brows": "natural",
			"eyes": "neutral",
			"nose_size": randf_range(0.8, 1.3),
			"jaw_width": randf_range(0.85, 1.2),
		},
		"outfit": {
			"top": tops[randi() % tops.size()] if not tops.is_empty() else "tshirt",
			"top_colour": top_colours[randi() % top_colours.size()] if not top_colours.is_empty() else [0.5, 0.5, 0.5],
			"bottom": bottoms[randi() % bottoms.size()] if not bottoms.is_empty() else "jeans",
			"bottom_colour": bottom_colours[randi() % bottom_colours.size()] if not bottom_colours.is_empty() else [0.3, 0.3, 0.35],
			"shoes": shoes[randi() % shoes.size()] if not shoes.is_empty() else "trainers",
			"hat": hats[randi() % hats.size()] if not hats.is_empty() else "none",
			"accessory": accessories[randi() % accessories.size()] if not accessories.is_empty() else "none",
		},
		"personality_tags": ["civilian"],
		"voice_pitch": randf_range(0.85, 1.15),
		"walk_style": "normal",
	}


func _random_skin_tone() -> Array:
	var tones := [
		[0.95, 0.82, 0.72], [0.88, 0.72, 0.6], [0.78, 0.62, 0.5],
		[0.65, 0.48, 0.35], [0.52, 0.38, 0.28], [0.4, 0.28, 0.2],
		[0.32, 0.22, 0.15],
	]
	return tones[randi() % tones.size()]


func _random_hair_colour() -> Array:
	var colours := [
		[0.08, 0.06, 0.04], [0.25, 0.18, 0.12], [0.5, 0.35, 0.2],
		[0.7, 0.55, 0.3], [0.85, 0.7, 0.45], [0.6, 0.15, 0.1],
		[0.15, 0.15, 0.15],
	]
	return colours[randi() % colours.size()]
