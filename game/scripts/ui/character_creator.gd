extends Control

## In-game character creator. Shown at game start before main menu.
## Player customises their character with sliders and dropdowns,
## then the appearance is saved to GameState.player_appearance.

const MAIN_MENU := "res://scenes/main/main_menu.tscn"

const BASE_MODELS := ["male_average", "male_heavy", "male_slim", "female_average", "female_athletic"]
const HAIR_M := ["buzz_cut", "shaved", "slicked_back", "fade_sharp", "messy_short", "dreads_short", "man_bun", "curtains", "receding", "afro_short"]
const HAIR_F := ["ponytail_tight", "messy_bun", "shoulder_natural", "big_curls", "beach_waves", "braids", "bob_sharp", "long_sleek", "pixie_cut"]
const BEARDS := ["none", "stubble_perfect", "designer_stubble", "full_thick", "full_groomed", "goatee", "patchy"]
const TOPS := ["hoodie", "tracksuit_top", "polo_shirt", "fleece", "simple_jumper", "tank_top", "linen_shirt_open", "puffer_jacket"]
const BOTTOMS := ["tracksuit_bottoms", "jeans_regular", "slim_jeans", "cargo_pants", "chinos_slim", "joggers_designer"]
const SHOES := ["trainers_white", "trainers_scuffed", "air_max_white", "work_boots", "loafers_black", "chelsea_boots"]
const HATS := ["none", "beanie", "baseball_cap", "flat_cap", "snapback", "bucket_hat"]
const ACCESSORIES := ["none", "gold_chain", "vape_pen", "airpods", "aviator_sunglasses", "earbuds_cheap"]

var current_base_idx: int = 0
var current_hair_idx: int = 0
var current_beard_idx: int = 0
var current_top_idx: int = 0
var current_bottom_idx: int = 0
var current_shoes_idx: int = 0
var current_hat_idx: int = 0
var current_acc_idx: int = 0

@onready var name_input: LineEdit = $Panel/VBox/NameInput
@onready var base_label: Label = $Panel/VBox/Sections/Body/BaseLabel
@onready var height_slider: HSlider = $Panel/VBox/Sections/Body/HeightSlider
@onready var width_slider: HSlider = $Panel/VBox/Sections/Body/WidthSlider
@onready var head_slider: HSlider = $Panel/VBox/Sections/Body/HeadSlider
@onready var hair_label: Label = $Panel/VBox/Sections/Face/HairLabel
@onready var beard_label: Label = $Panel/VBox/Sections/Face/BeardLabel
@onready var skin_picker: ColorPickerButton = $Panel/VBox/Sections/Face/SkinPicker
@onready var hair_colour_picker: ColorPickerButton = $Panel/VBox/Sections/Face/HairColourPicker
@onready var top_label: Label = $Panel/VBox/Sections/Outfit/TopLabel
@onready var bottom_label: Label = $Panel/VBox/Sections/Outfit/BottomLabel
@onready var shoes_label: Label = $Panel/VBox/Sections/Outfit/ShoesLabel
@onready var hat_label: Label = $Panel/VBox/Sections/Outfit/HatLabel
@onready var acc_label: Label = $Panel/VBox/Sections/Outfit/AccLabel
@onready var confirm_btn: Button = $Panel/VBox/ConfirmButton
@onready var random_btn: Button = $Panel/VBox/RandomButton


func _ready() -> void:
	confirm_btn.pressed.connect(_on_confirm)
	random_btn.pressed.connect(_on_randomise)
	_update_labels()
	skin_picker.color = Color(0.85, 0.7, 0.6)
	hair_colour_picker.color = Color(0.15, 0.1, 0.06)


func _on_confirm() -> void:
	var is_female := BASE_MODELS[current_base_idx].begins_with("female")
	var hair_list := HAIR_F if is_female else HAIR_M

	GameState.player_name = name_input.text if name_input.text != "" else "Player"
	GameState.player_appearance = {
		"base_model": BASE_MODELS[current_base_idx],
		"body": {
			"height": height_slider.value,
			"width": width_slider.value,
			"head_scale": head_slider.value,
		},
		"face": {
			"skin_tone": [skin_picker.color.r, skin_picker.color.g, skin_picker.color.b],
			"hair": hair_list[current_hair_idx % hair_list.size()],
			"hair_colour": [hair_colour_picker.color.r, hair_colour_picker.color.g, hair_colour_picker.color.b],
			"beard": BEARDS[current_beard_idx] if not is_female else "none",
		},
		"outfit": {
			"top": TOPS[current_top_idx],
			"bottom": BOTTOMS[current_bottom_idx],
			"shoes": SHOES[current_shoes_idx],
			"hat": HATS[current_hat_idx],
			"accessory": ACCESSORIES[current_acc_idx],
		},
	}
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_randomise() -> void:
	current_base_idx = randi() % BASE_MODELS.size()
	current_hair_idx = randi() % HAIR_M.size()
	current_beard_idx = randi() % BEARDS.size()
	current_top_idx = randi() % TOPS.size()
	current_bottom_idx = randi() % BOTTOMS.size()
	current_shoes_idx = randi() % SHOES.size()
	current_hat_idx = randi() % HATS.size()
	current_acc_idx = randi() % ACCESSORIES.size()
	height_slider.value = randf_range(0.85, 1.2)
	width_slider.value = randf_range(0.8, 1.3)
	head_slider.value = randf_range(1.0, 1.4)
	skin_picker.color = Color(randf_range(0.3, 0.95), randf_range(0.2, 0.8), randf_range(0.15, 0.7))
	hair_colour_picker.color = Color(randf_range(0.0, 0.5), randf_range(0.0, 0.4), randf_range(0.0, 0.3))
	_update_labels()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_LEFT:
			_cycle_current(-1)
		KEY_RIGHT:
			_cycle_current(1)


func _cycle_current(dir: int) -> void:
	current_base_idx = (current_base_idx + dir + BASE_MODELS.size()) % BASE_MODELS.size()
	_update_labels()


func cycle_hair(dir: int) -> void:
	var is_female := BASE_MODELS[current_base_idx].begins_with("female")
	var list := HAIR_F if is_female else HAIR_M
	current_hair_idx = (current_hair_idx + dir + list.size()) % list.size()
	_update_labels()

func cycle_beard(dir: int) -> void:
	current_beard_idx = (current_beard_idx + dir + BEARDS.size()) % BEARDS.size()
	_update_labels()

func cycle_top(dir: int) -> void:
	current_top_idx = (current_top_idx + dir + TOPS.size()) % TOPS.size()
	_update_labels()

func cycle_bottom(dir: int) -> void:
	current_bottom_idx = (current_bottom_idx + dir + BOTTOMS.size()) % BOTTOMS.size()
	_update_labels()

func cycle_shoes(dir: int) -> void:
	current_shoes_idx = (current_shoes_idx + dir + SHOES.size()) % SHOES.size()
	_update_labels()

func cycle_hat(dir: int) -> void:
	current_hat_idx = (current_hat_idx + dir + HATS.size()) % HATS.size()
	_update_labels()

func cycle_acc(dir: int) -> void:
	current_acc_idx = (current_acc_idx + dir + ACCESSORIES.size()) % ACCESSORIES.size()
	_update_labels()


func _update_labels() -> void:
	var is_female := BASE_MODELS[current_base_idx].begins_with("female")
	var hair_list := HAIR_F if is_female else HAIR_M

	base_label.text = BASE_MODELS[current_base_idx].replace("_", " ").capitalize()
	hair_label.text = hair_list[current_hair_idx % hair_list.size()].replace("_", " ").capitalize()
	beard_label.text = BEARDS[current_beard_idx].replace("_", " ").capitalize()
	top_label.text = TOPS[current_top_idx].replace("_", " ").capitalize()
	bottom_label.text = BOTTOMS[current_bottom_idx].replace("_", " ").capitalize()
	shoes_label.text = SHOES[current_shoes_idx].replace("_", " ").capitalize()
	hat_label.text = HATS[current_hat_idx].replace("_", " ").capitalize()
	acc_label.text = ACCESSORIES[current_acc_idx].replace("_", " ").capitalize()
