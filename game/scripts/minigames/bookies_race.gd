extends Control

## Bookies race minigame — renders a side-scrolling horse race or sumo
## tournament on a retro CRT screen. Receives runner data + bet info
## from BookiesManager, animates the race, returns results.

signal race_complete(result: Dictionary)

const TRACK_LENGTH := 800.0
const LANE_HEIGHT := 48.0
const LANE_MARGIN := 8.0
const RUNNER_WIDTH := 40.0
const RUNNER_HEIGHT := 36.0
const FINISH_X := 760.0
const START_X := 60.0

const COMMENTARY_HORSE: Array[String] = [
	"AND THEY'RE OFF!",
	"%s is pulling ahead!",
	"Look at %s go!",
	"%s is making a move on the inside!",
	"It's neck and neck between %s and %s!",
	"%s is falling behind!",
	"The crowd goes WILD!",
	"%s surges forward!",
	"What a race this is turning out to be!",
	"%s is giving it everything!",
	"DOWN THE FINAL STRAIGHT!",
	"AND THE WINNER IS... %s!",
]

const COMMENTARY_SUMO: Array[String] = [
	"THE BOUT BEGINS!",
	"%s charges forward!",
	"%s digs in! Incredible strength!",
	"%s is being pushed to the edge!",
	"What power from %s!",
	"%s tries a desperate counter!",
	"The crowd is on their feet!",
	"%s won't give an inch!",
	"AND %s IS OUT! %s WINS THE BOUT!",
]

enum RaceMode { HORSE, SUMO }

var mode: int = RaceMode.HORSE
var runners: Array[Dictionary] = []
var player_pick: String = ""
var bet_amount: float = 0.0
var race_active: bool = false
var race_time: float = 0.0
var race_duration: float = 8.0
var winner_name: String = ""
var commentary_queue: Array[String] = []
var commentary_timer: float = 0.0
var current_commentary: String = ""

# Per-runner runtime state
var runner_positions: Array[float] = []
var runner_speeds: Array[float] = []
var runner_burst_timers: Array[float] = []

# Sumo-specific
var sumo_bracket: Array = []
var sumo_current_bout: int = 0
var sumo_fighter_a_pos: float = 0.0
var sumo_fighter_b_pos: float = 0.0

@onready var race_viewport: SubViewportContainer = $CRTFrame/SubViewportContainer
@onready var race_subviewport: SubViewport = $CRTFrame/SubViewportContainer/SubViewport
@onready var track_canvas: Control = $CRTFrame/SubViewportContainer/SubViewport/TrackCanvas
@onready var commentary_label: Label = $CommentaryBar
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_title: Label = $ResultPanel/VBox/ResultTitle
@onready var result_details: Label = $ResultPanel/VBox/ResultDetails
@onready var result_button: Button = $ResultPanel/VBox/DoneButton


func _ready() -> void:
	result_panel.visible = false
	result_button.pressed.connect(_on_done)
	track_canvas.connect("draw", _draw_track)
	_auto_start()


func _auto_start() -> void:
	if BookiesManager.pending_race_type < 0:
		return
	var rt: int = BookiesManager.pending_race_type
	var rn: Array[Dictionary] = BookiesManager.pending_runners
	var pk: String = BookiesManager.pending_pick
	var bt: float = BookiesManager.pending_bet
	BookiesManager.pending_race_type = -1

	if rt == BookiesManager.RaceType.HORSE_RACING:
		start_horse_race(rn, pk, bt)
	else:
		start_sumo(rn, pk, bt)


func start_horse_race(race_runners: Array[Dictionary], pick: String, bet: float) -> void:
	mode = RaceMode.HORSE
	runners = race_runners
	player_pick = pick
	bet_amount = bet
	_init_horse_race()
	race_active = true


func start_sumo(race_runners: Array[Dictionary], pick: String, bet: float) -> void:
	mode = RaceMode.SUMO
	runners = race_runners
	player_pick = pick
	bet_amount = bet
	_init_sumo()
	race_active = true


func _init_horse_race() -> void:
	race_time = 0.0
	winner_name = ""
	runner_positions.clear()
	runner_speeds.clear()
	runner_burst_timers.clear()

	for runner in runners:
		runner_positions.append(START_X)
		runner_speeds.append(runner.get("base_speed", 1.0))
		runner_burst_timers.append(randf_range(1.0, 3.0))

	commentary_queue = COMMENTARY_HORSE.duplicate()
	current_commentary = "AND THEY'RE OFF!"
	commentary_timer = 0.0


func _init_sumo() -> void:
	race_time = 0.0
	winner_name = ""
	sumo_bracket.clear()
	sumo_current_bout = 0
	sumo_fighter_a_pos = 0.0
	sumo_fighter_b_pos = 0.0

	var pool := runners.duplicate()
	pool.shuffle()
	while pool.size() > 1:
		var bout := [pool.pop_front(), pool.pop_front()]
		sumo_bracket.append(bout)

	commentary_queue = COMMENTARY_SUMO.duplicate()
	current_commentary = "THE SUMO TOURNAMENT BEGINS!"
	commentary_timer = 0.0


func _process(delta: float) -> void:
	if not race_active:
		return

	race_time += delta
	commentary_timer += delta

	if commentary_timer > 2.0:
		commentary_timer = 0.0
		_update_commentary()

	if mode == RaceMode.HORSE:
		_update_horse_race(delta)
	else:
		_update_sumo(delta)

	track_canvas.queue_redraw()


func _update_horse_race(delta: float) -> void:
	var any_finished := false
	for i in range(runners.size()):
		if runner_positions[i] >= FINISH_X:
			if winner_name == "":
				winner_name = runners[i]["name"]
				any_finished = true
			continue

		runner_burst_timers[i] -= delta
		var burst := 0.0
		if runner_burst_timers[i] <= 0.0:
			burst = randf_range(15.0, 40.0)
			runner_burst_timers[i] = randf_range(0.8, 2.5)

		var base: float = runner_speeds[i]
		var noise: float = randf_range(-8.0, 12.0)
		var mood: float = MarketMood.get_npc_modifier("confidence")
		var speed: float = (base * 70.0 + noise + burst) * mood
		runner_positions[i] += speed * delta

		if runner_positions[i] >= FINISH_X:
			runner_positions[i] = FINISH_X
			if winner_name == "":
				winner_name = runners[i]["name"]
				any_finished = true

	if any_finished and winner_name != "":
		_finish_race()


func _update_sumo(delta: float) -> void:
	if sumo_current_bout >= sumo_bracket.size():
		return

	var bout: Array = sumo_bracket[sumo_current_bout]
	var a: Dictionary = bout[0]
	var b: Dictionary = bout[1]
	var a_power: float = a.get("base_speed", 1.0) * randf_range(0.5, 1.5)
	var b_power: float = b.get("base_speed", 1.0) * randf_range(0.5, 1.5)

	sumo_fighter_a_pos += (a_power - b_power) * 30.0 * delta
	sumo_fighter_b_pos -= (a_power - b_power) * 30.0 * delta

	var ring_edge := 120.0
	if abs(sumo_fighter_a_pos) > ring_edge or abs(sumo_fighter_b_pos) > ring_edge:
		var bout_winner: Dictionary
		if abs(sumo_fighter_a_pos) > abs(sumo_fighter_b_pos):
			bout_winner = b
		else:
			bout_winner = a

		sumo_current_bout += 1

		if sumo_current_bout < sumo_bracket.size():
			sumo_bracket[sumo_current_bout][0] = bout_winner
			sumo_fighter_a_pos = 0.0
			sumo_fighter_b_pos = 0.0
			current_commentary = "%s advances!" % bout_winner["name"]
		else:
			winner_name = bout_winner["name"]
			_finish_race()


func _finish_race() -> void:
	race_active = false
	var player_won := winner_name == player_pick

	if player_won:
		var odds: float = 3.0
		for r in runners:
			if r["name"] == winner_name:
				odds = r.get("odds", 3.0)
				break
		var winnings: float = bet_amount * odds
		GameState.add_cash(winnings)
		GameState.add_respect(int(winnings * 0.1))
		result_title.text = "WINNER!"
		result_details.text = "%s came through!\nPayout: £%.0f" % [winner_name, winnings]
	else:
		result_title.text = "LOSER!"
		result_details.text = "%s won.\nYou lost £%.0f on %s." % [winner_name, bet_amount, player_pick]

	current_commentary = "AND THE WINNER IS... %s!" % winner_name
	result_panel.visible = true

	var result := {
		"winner": winner_name,
		"player_won": player_won,
		"bet_amount": bet_amount,
		"payout": bet_amount * 3.0 if player_won else 0.0,
	}
	race_complete.emit(result)


func _draw_track() -> void:
	var draw_node := track_canvas
	var vp_size := race_subviewport.size

	# Background
	draw_node.draw_rect(Rect2(0, 0, vp_size.x, vp_size.y), Color(0.05, 0.12, 0.05))

	if mode == RaceMode.HORSE:
		_draw_horse_track(draw_node, vp_size)
	else:
		_draw_sumo_ring(draw_node, vp_size)


func _draw_horse_track(d: Control, vp: Vector2i) -> void:
	var num := runners.size()
	var total_h: float = num * (LANE_HEIGHT + LANE_MARGIN) + LANE_MARGIN

	# Finish line
	d.draw_rect(Rect2(FINISH_X, 0, 3, vp.y), Color(1.0, 0.2, 0.2, 0.8))
	d.draw_string(ThemeDB.fallback_font, Vector2(FINISH_X - 40, 16), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.3, 0.3))

	for i in range(num):
		var lane_y: float = LANE_MARGIN + i * (LANE_HEIGHT + LANE_MARGIN) + (vp.y - total_h) * 0.5
		var is_pick: bool = runners[i]["name"] == player_pick

		# Lane background
		var lane_col := Color(0.08, 0.18, 0.08) if i % 2 == 0 else Color(0.06, 0.15, 0.06)
		d.draw_rect(Rect2(0, lane_y, vp.x, LANE_HEIGHT), lane_col)

		# Lane name
		var name_col := Color(0.0, 1.0, 0.5) if is_pick else Color(0.6, 0.7, 0.6)
		d.draw_string(ThemeDB.fallback_font, Vector2(4, lane_y + 14), runners[i]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, name_col)

		# Runner rectangle
		var rx: float = runner_positions[i] if i < runner_positions.size() else START_X
		var runner_col := Color(0.0, 0.9, 0.4) if is_pick else Color(0.7, 0.7, 0.3)
		d.draw_rect(Rect2(rx, lane_y + 8, RUNNER_WIDTH, RUNNER_HEIGHT), runner_col)

		# Jockey hat (triangle on top)
		var hat_points := PackedVector2Array([
			Vector2(rx + RUNNER_WIDTH * 0.3, lane_y + 8),
			Vector2(rx + RUNNER_WIDTH * 0.7, lane_y + 8),
			Vector2(rx + RUNNER_WIDTH * 0.5, lane_y),
		])
		d.draw_polygon(hat_points, PackedColorArray([runner_col * 1.3]))

		# Pick marker
		if is_pick:
			d.draw_string(ThemeDB.fallback_font, Vector2(rx + RUNNER_WIDTH + 4, lane_y + 30), "YOUR BET", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.0, 1.0, 0.5))


func _draw_sumo_ring(d: Control, vp: Vector2i) -> void:
	var center := Vector2(vp.x * 0.5, vp.y * 0.5)
	var ring_radius := 120.0

	# Ring (dohyo)
	d.draw_circle(center, ring_radius + 5, Color(0.3, 0.25, 0.15))
	d.draw_circle(center, ring_radius, Color(0.6, 0.5, 0.3))
	d.draw_arc(center, ring_radius, 0, TAU, 64, Color(0.2, 0.15, 0.08), 3.0)

	if sumo_current_bout >= sumo_bracket.size():
		return

	var bout: Array = sumo_bracket[sumo_current_bout]
	var a_name: String = bout[0]["name"]
	var b_name: String = bout[1]["name"]

	# Fighters
	var a_pos := center + Vector2(sumo_fighter_a_pos - 30, 0)
	var b_pos := center + Vector2(sumo_fighter_b_pos + 30, 0)
	var a_col := Color(0.0, 0.9, 0.4) if a_name == player_pick else Color(0.8, 0.3, 0.3)
	var b_col := Color(0.0, 0.9, 0.4) if b_name == player_pick else Color(0.3, 0.3, 0.8)

	d.draw_circle(a_pos, 22, a_col)
	d.draw_circle(b_pos, 22, b_col)

	# Names
	d.draw_string(ThemeDB.fallback_font, a_pos + Vector2(-30, -30), a_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	d.draw_string(ThemeDB.fallback_font, b_pos + Vector2(-30, -30), b_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# Bout info
	var bout_text := "Bout %d / %d" % [sumo_current_bout + 1, sumo_bracket.size()]
	d.draw_string(ThemeDB.fallback_font, Vector2(10, 20), bout_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.85, 0.6))


func _update_commentary() -> void:
	if mode == RaceMode.HORSE and runners.size() > 0:
		var lead_idx := 0
		var max_pos := 0.0
		for i in range(runner_positions.size()):
			if runner_positions[i] > max_pos:
				max_pos = runner_positions[i]
				lead_idx = i

		var trail_idx := 0
		var min_pos := 99999.0
		for i in range(runner_positions.size()):
			if runner_positions[i] < min_pos:
				min_pos = runner_positions[i]
				trail_idx = i

		var templates := [
			"%s is pulling ahead!" % runners[lead_idx]["name"],
			"Look at %s go!" % runners[lead_idx]["name"],
			"%s is falling behind!" % runners[trail_idx]["name"],
			"What a race this is!",
			"The crowd goes WILD!",
			"%s surges forward!" % runners[randi() % runners.size()]["name"],
		]
		current_commentary = templates[randi() % templates.size()]

	commentary_label.text = current_commentary


func _on_done() -> void:
	result_panel.visible = false
	get_tree().change_scene_to_file("res://scenes/world/consett_blockout.tscn")
