extends Control

const CONSETT_SCENE := "res://scenes/world/consett_blockout.tscn"
const CHARACTER_CREATOR := "res://scenes/ui/character_creator.tscn"


func _ready() -> void:
	$Center/Buttons/PlayButton.pressed.connect(_on_play_pressed)
	$Center/Buttons/QuitButton.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	if GameState.player_appearance.is_empty():
		get_tree().change_scene_to_file(CHARACTER_CREATOR)
	else:
		get_tree().change_scene_to_file(CONSETT_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
