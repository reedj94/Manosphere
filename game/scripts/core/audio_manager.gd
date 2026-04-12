extends Node

## Audio manager with per-region music, crossfading, and DMCA-free
## streaming support (no copyrighted music = streamer-friendly).

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_region_track: String = ""
var music_volume: float = 0.8
var sfx_volume: float = 1.0

const REGION_TRACKS := {
	GameState.Region.CONSETT: "res://assets/audio/music/consett_theme.ogg",
	GameState.Region.LONDON: "res://assets/audio/music/london_theme.ogg",
	GameState.Region.MIAMI: "res://assets/audio/music/miami_theme.ogg",
	GameState.Region.DUBAI: "res://assets/audio/music/dubai_theme.ogg",
}

const MAX_SFX_PLAYERS := 8


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)


func play_region_music(region: GameState.Region) -> void:
	var track_path: String = REGION_TRACKS.get(region, "")
	if track_path == current_region_track or track_path == "":
		return

	current_region_track = track_path
	if ResourceLoader.exists(track_path):
		var stream := load(track_path) as AudioStream
		if stream:
			_crossfade_to(stream)


func play_sfx(sfx_path: String) -> void:
	if not ResourceLoader.exists(sfx_path):
		return
	var stream := load(sfx_path) as AudioStream
	if not stream:
		return

	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume)
			player.play()
			return


func _crossfade_to(new_stream: AudioStream) -> void:
	# Simple crossfade via tween
	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, 1.0)
	await tween.finished
	music_player.stream = new_stream
	music_player.volume_db = linear_to_db(music_volume)
	music_player.play()
