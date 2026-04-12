extends Node

## Save system: autosave at man caves + periodic (5 min) + major events.
## Single persistent save per playthrough. Steam Cloud sync.

signal save_completed(slot: String)
signal load_completed(slot: String)
signal autosave_triggered(reason: String)

const SAVE_DIR := "user://saves/"
const AUTOSAVE_INTERVAL := 300.0  # 5 minutes
const SAVE_VERSION := 1

var autosave_timer: float = 0.0
var current_slot: String = "default"
var is_saving: bool = false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _process(delta: float) -> void:
	autosave_timer += delta
	if autosave_timer >= AUTOSAVE_INTERVAL:
		autosave_timer = 0.0
		autosave("periodic")


func autosave(reason: String = "periodic") -> void:
	save_game(current_slot)
	autosave_triggered.emit(reason)


func save_at_man_cave() -> void:
	autosave_timer = 0.0  # reset periodic timer
	save_game(current_slot)
	autosave_triggered.emit("man_cave")


func save_on_event(event_name: String) -> void:
	save_game(current_slot)
	autosave_triggered.emit(event_name)


func save_game(slot: String) -> void:
	if is_saving:
		return
	is_saving = true

	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": GameState.get_save_data(),
		"economy": _get_economy_data(),
		"crapto_portfolio": CraptoFeed.get_portfolio_data() if CraptoFeed.has_method("get_portfolio_data") else {},
	}

	var path := SAVE_DIR + slot + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		save_completed.emit(slot)

	is_saving = false


func load_game(slot: String) -> bool:
	var path := SAVE_DIR + slot + ".json"
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	file.close()

	if result != OK:
		push_error("Failed to parse save file: %s" % path)
		return false

	var data: Dictionary = json.data
	if data.get("version", 0) != SAVE_VERSION:
		push_warning("Save version mismatch, attempting migration")
		# TODO: implement save migration

	if data.has("game_state"):
		GameState.load_save_data(data["game_state"])

	current_slot = slot
	load_completed.emit(slot)
	return true


func get_save_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var dir := DirAccess.open(SAVE_DIR)
	if not dir:
		return slots

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var slot_name := file_name.trim_suffix(".json")
			var file := FileAccess.open(SAVE_DIR + file_name, FileAccess.READ)
			if file:
				var json := JSON.new()
				if json.parse(file.get_as_text()) == OK:
					var data: Dictionary = json.data
					slots.append({
						"slot": slot_name,
						"timestamp": data.get("timestamp", "Unknown"),
						"pyramid_tier": data.get("game_state", {}).get("pyramid_tier", 1),
						"region": data.get("game_state", {}).get("current_region", 0),
					})
				file.close()
		file_name = dir.get_next()
	dir.list_dir_end()
	return slots


func delete_save(slot: String) -> void:
	var path := SAVE_DIR + slot + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _get_economy_data() -> Dictionary:
	return {
		"rent_timer": EconomyManager.rent_timer if EconomyManager else 0.0,
	}
