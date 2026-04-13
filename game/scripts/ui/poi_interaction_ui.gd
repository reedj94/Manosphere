extends CanvasLayer

## POI interaction UI — shows when player presses E near a POI.
## Displays context-appropriate options based on POI type.

signal action_selected(poi_id: String, action: String)
signal ui_closed()

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var desc_label: Label = $Panel/VBox/Description
@onready var buttons_container: VBoxContainer = $Panel/VBox/Buttons
@onready var close_btn: Button = $Panel/VBox/CloseButton

var current_poi_id: String = ""
var is_open: bool = false


func _ready() -> void:
	panel.visible = false
	close_btn.pressed.connect(_close)


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func open_for_poi(poi_id: String) -> void:
	var poi: Dictionary = POIRegistry.get_poi(poi_id)
	if poi.is_empty():
		return

	if not POIRegistry.is_open(poi, GameState.game_hour):
		_show_closed_message(poi)
		return

	current_poi_id = poi_id
	is_open = true

	title_label.text = poi["display_name"]
	desc_label.text = poi.get("description", "")

	_clear_buttons()

	var poi_type: int = poi["type"]
	var actions: Array = POIRegistry.get_actions(poi_type)

	for action_name in actions:
		var btn := Button.new()
		btn.text = _format_action_name(action_name, poi)
		btn.custom_minimum_size = Vector2(250, 40)
		var bound_action: String = action_name
		btn.pressed.connect(_on_action_pressed.bind(bound_action))
		buttons_container.add_child(btn)

	if poi.has("faction_id"):
		var bark: String = FactionManager.get_random_bark(poi["faction_id"])
		if bark != "":
			var bark_label := Label.new()
			bark_label.text = "\"%s\"" % bark
			bark_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
			bark_label.add_theme_font_size_override("font_size", 14)
			bark_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			buttons_container.add_child(bark_label)

	panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _show_closed_message(poi: Dictionary) -> void:
	current_poi_id = ""
	is_open = true
	title_label.text = poi["display_name"]
	desc_label.text = "[CLOSED] — Come back later."
	_clear_buttons()
	panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close() -> void:
	panel.visible = false
	is_open = false
	current_poi_id = ""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ui_closed.emit()


func _clear_buttons() -> void:
	for child in buttons_container.get_children():
		child.queue_free()


func _on_action_pressed(action: String) -> void:
	action_selected.emit(current_poi_id, action)

	match action:
		"bet_horses":
			_open_bookies(BookiesManager.RaceType.HORSE_RACING)
		"bet_sumo":
			_open_bookies(BookiesManager.RaceType.SUMO_WRESTLING)
		"save":
			_do_save()
		"sleep":
			_do_sleep()
		"faction_dialogue":
			_start_faction_dialogue()
		"confront":
			_start_faction_dialogue()
		_:
			_show_placeholder(action)


func _open_bookies(race_type: int) -> void:
	_clear_buttons()
	var type_name: String = "Horse Racing" if race_type == BookiesManager.RaceType.HORSE_RACING else "Extreme Sumo Showdown"
	title_label.text = type_name
	desc_label.text = "Pick your champion and place a bet. Cash: £%.0f" % GameState.cash

	var runners: Array[Dictionary] = BookiesManager.get_race_runners(race_type)

	for runner in runners:
		var btn := Button.new()
		btn.text = "%s  |  %s  |  Form: %s" % [runner["name"], runner["odds_display"], runner["form"]]
		btn.custom_minimum_size = Vector2(400, 36)
		var runner_name: String = runner["name"]
		btn.pressed.connect(_on_runner_selected.bind(race_type, runner_name, runners))
		buttons_container.add_child(btn)


func _on_runner_selected(race_type: int, runner_name: String, runners: Array[Dictionary]) -> void:
	_clear_buttons()
	title_label.text = "Bet on: %s" % runner_name
	desc_label.text = "How much? Cash: £%.0f" % GameState.cash

	var bet_amounts: Array[float] = [10.0, 50.0, 100.0, 500.0]
	for amount in bet_amounts:
		if amount > GameState.cash:
			continue
		var btn := Button.new()
		btn.text = "£%.0f" % amount
		btn.custom_minimum_size = Vector2(200, 40)
		btn.pressed.connect(_on_bet_confirmed.bind(race_type, runner_name, amount, runners))
		buttons_container.add_child(btn)

	if GameState.cash >= 10.0:
		var all_in_btn := Button.new()
		all_in_btn.text = "ALL IN — £%.0f" % GameState.cash
		all_in_btn.custom_minimum_size = Vector2(200, 40)
		all_in_btn.pressed.connect(_on_bet_confirmed.bind(race_type, runner_name, GameState.cash, runners))
		buttons_container.add_child(all_in_btn)


func _on_bet_confirmed(race_type: int, runner_name: String, amount: float, runners: Array[Dictionary]) -> void:
	var placed := BookiesManager.place_bet(race_type, runner_name, amount)
	if not placed:
		desc_label.text = "Can't place that bet!"
		return

	_clear_buttons()
	title_label.text = "Race in progress..."
	desc_label.text = "Your bet: £%.0f on %s" % [amount, runner_name]

	var result: Dictionary = BookiesManager.run_race(runners)
	_show_race_result(result)


func _show_race_result(result: Dictionary) -> void:
	_clear_buttons()
	var results: Array = result["results"]
	var player_won: bool = result["player_won"]

	if player_won:
		title_label.text = "WINNER!"
		desc_label.text = "£%.0f payout! Your champion %s came through!" % [result["payout"], result["winner"]]
	else:
		title_label.text = "LOSER!"
		desc_label.text = "%s won. You lost £%.0f. The bookies always win." % [result["winner"], result["bet_amount"]]

	var pos := 1
	for r in results:
		var label := Label.new()
		var marker: String = " ← YOUR BET" if r["name"] == BookiesManager.current_bet_selection else ""
		label.text = "#%d  %s  (score: %.1f)%s" % [pos, r["name"], r["score"], marker]
		if pos == 1:
			label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
		buttons_container.add_child(label)
		pos += 1

	var again_btn := Button.new()
	again_btn.text = "Bet Again"
	again_btn.custom_minimum_size = Vector2(200, 40)
	again_btn.pressed.connect(open_for_poi.bind(current_poi_id))
	buttons_container.add_child(again_btn)


func _do_save() -> void:
	SaveManager.save_game()
	desc_label.text = "Game saved."


func _do_sleep() -> void:
	GameState.advance_time(8)
	desc_label.text = "You slept. It's now %d:00." % GameState.game_hour


func _start_faction_dialogue() -> void:
	var poi: Dictionary = POIRegistry.get_poi(current_poi_id)
	var faction_id: String = poi.get("faction_id", "")
	if faction_id == "":
		return

	var faction: Dictionary = FactionManager.get_faction(faction_id)
	var leader: String = faction.get("leader", "")
	if leader == "":
		return

	_close()

	var npc_id: String = leader.to_lower().replace(" ", "_").replace(".", "")
	DialogueManager.start_dialogue(npc_id)
	FactionManager.add_hostility(faction_id, 5)


func _show_placeholder(action: String) -> void:
	desc_label.text = "[%s] — Coming soon." % _format_action_name(action, {})


func _format_action_name(action: String, _poi: Dictionary) -> String:
	match action:
		"save": return "Save Game"
		"stash": return "Stash Items"
		"upgrade": return "Upgrades"
		"sleep": return "Sleep (8 hours)"
		"plan_heist": return "Plan a Job"
		"buy": return "Buy"
		"sell": return "Sell"
		"recruit": return "Recruit"
		"talk": return "Talk"
		"bet_horses": return "Horse Racing"
		"bet_sumo": return "Extreme Sumo Showdown"
		"bet_custom": return "Special Events"
		"loan_shark": return "Need a Loan? (Don't.)"
		"quest_board": return "Quest Board"
		"dance": return "Dance"
		"vip_area": return "VIP Area"
		"side_quest": return "Side Quests"
		"rest": return "Rest"
		"encounter": return "Look Around"
		"train": return "Train"
		"deal": return "Shady Deal"
		"ambient_quest": return "Explore"
		"confront": return "Confront"
		"buy_vapes": return "Buy Vapes"
		"get_trim": return "Get a Trim"
		"eavesdrop": return "Eavesdrop"
		"faction_dialogue": return "Talk to Owner"
		"boss_fight": return "Challenge Boss"
		"negotiate": return "Negotiate"
		"spy": return "Spy"
		_: return action.capitalize()
