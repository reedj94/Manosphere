extends CharacterBody3D

const MAIN_MENU := "res://scenes/main/main_menu.tscn"
const SPEED := 5.5
const SPRINT_MULT := 1.65
const MOUSE_SENS := 0.0022
const JUMP_VELOCITY := 4.8

@onready var camera: Camera3D = $Camera3D
@onready var hint: Label = $"../UI/Hint"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if hint:
		hint.text = "WASD move · Shift sprint · Space jump · Mouse look · Esc free mouse · M main menu"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		camera.rotate_x(-event.relative.y * MOUSE_SENS)
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-88.0), deg_to_rad(88.0))

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		get_tree().change_scene_to_file(MAIN_MENU)

	if event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var wish := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var spd := SPEED * (SPRINT_MULT if Input.is_action_pressed("sprint") else 1.0)

	if wish.length_squared() > 0.0001:
		velocity.x = wish.x * spd
		velocity.z = wish.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0.0, spd * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, spd * 10.0 * delta)

	move_and_slide()


func _try_interact() -> void:
	var world_script: Node = get_parent()
	if world_script and world_script.has_method("get_active_poi_id"):
		var poi_id: String = world_script.get_active_poi_id()
		if poi_id != "":
			var ui: Node = get_tree().get_first_node_in_group("poi_interaction_ui")
			if ui and ui.has_method("open_for_poi"):
				ui.open_for_poi(poi_id)
