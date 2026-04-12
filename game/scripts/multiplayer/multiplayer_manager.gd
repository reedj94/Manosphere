extends Node

## Multiplayer manager. Handles 1-4 player co-op via Godot's ENet
## peer-to-peer networking + GodotSteam for lobby/invite system.
## Host-authoritative for quest state and economy; client-predicted for movement.

signal player_joined(peer_id: int, player_name: String)
signal player_left(peer_id: int)
signal lobby_created(lobby_code: String)
signal lobby_joined(host_name: String)
signal rally_point_waiting(quest_id: String, players_present: int, players_needed: int)
signal all_players_at_rally()

const MAX_PLAYERS := 4
const DEFAULT_PORT := 27015

var peer: ENetMultiplayerPeer
var connected_players: Dictionary = {}  # peer_id -> {name, region, position, ready_for_rally}
var is_hosting: bool = false
var lobby_code: String = ""

# Rally point system — major quests require all players present
var active_rally: Dictionary = {}  # quest_id -> {required_players, present_players}


func host_game(player_name: String) -> bool:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(DEFAULT_PORT, MAX_PLAYERS - 1)
	if err != OK:
		push_error("Failed to create server: %s" % error_string(err))
		return false

	multiplayer.multiplayer_peer = peer
	is_hosting = true
	GameState.is_host = true

	connected_players[1] = {"name": player_name, "region": GameState.current_region, "ready_for_rally": false}
	lobby_code = _generate_lobby_code()
	lobby_created.emit(lobby_code)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return true


func join_game(host_ip: String, player_name: String) -> bool:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(host_ip, DEFAULT_PORT)
	if err != OK:
		push_error("Failed to connect: %s" % error_string(err))
		return false

	multiplayer.multiplayer_peer = peer
	is_hosting = false
	GameState.is_host = false

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func(): _register_with_host.rpc_id(1, player_name))
	return true


func disconnect_game() -> void:
	if peer:
		multiplayer.multiplayer_peer = null
		peer = null
	connected_players.clear()
	is_hosting = false
	active_rally.clear()


func _on_peer_connected(id: int) -> void:
	pass  # wait for registration RPC


func _on_peer_disconnected(id: int) -> void:
	if connected_players.has(id):
		var name: String = connected_players[id]["name"]
		connected_players.erase(id)
		player_left.emit(id)
		_check_rally_state()


@rpc("any_peer", "reliable")
func _register_with_host(player_name: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	connected_players[sender] = {
		"name": player_name,
		"region": GameState.current_region,
		"ready_for_rally": false,
	}
	player_joined.emit(sender, player_name)

	# Sync game state to new player
	_sync_state_to_peer.rpc_id(sender, GameState.get_save_data())


@rpc("authority", "reliable")
func _sync_state_to_peer(state_data: Dictionary) -> void:
	GameState.load_save_data(state_data)
	lobby_joined.emit(state_data.get("player_name", "Host"))


# --- Rally Point System ---

func initiate_rally(quest_id: String) -> void:
	if not is_hosting:
		_request_rally.rpc_id(1, quest_id)
		return

	active_rally = {
		"quest_id": quest_id,
		"required": connected_players.size(),
		"present": [],
	}
	_notify_rally.rpc(quest_id, connected_players.size())


@rpc("any_peer", "reliable")
func _request_rally(quest_id: String) -> void:
	initiate_rally(quest_id)


@rpc("authority", "reliable", "call_local")
func _notify_rally(quest_id: String, players_needed: int) -> void:
	rally_point_waiting.emit(quest_id, 0, players_needed)


func player_arrived_at_rally(peer_id: int = -1) -> void:
	if peer_id == -1:
		peer_id = multiplayer.get_unique_id()

	if not is_hosting:
		_report_rally_arrival.rpc_id(1)
		return

	if active_rally.size() > 0 and peer_id not in active_rally["present"]:
		active_rally["present"].append(peer_id)
		_check_rally_state()


@rpc("any_peer", "reliable")
func _report_rally_arrival() -> void:
	player_arrived_at_rally(multiplayer.get_remote_sender_id())


func _check_rally_state() -> void:
	if active_rally.size() == 0:
		return

	var present := active_rally["present"].size()
	var required: int = active_rally["required"]

	rally_point_waiting.emit(active_rally["quest_id"], present, required)

	if present >= required:
		active_rally.clear()
		_rally_complete.rpc()


@rpc("authority", "reliable", "call_local")
func _rally_complete() -> void:
	all_players_at_rally.emit()


func get_player_count() -> int:
	return connected_players.size()


func is_solo() -> bool:
	return connected_players.size() <= 1


func _generate_lobby_code() -> String:
	var chars := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code := ""
	for i in 6:
		code += chars[randi_range(0, chars.length() - 1)]
	return code
