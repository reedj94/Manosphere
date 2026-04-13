extends Node3D

## Consett high street — spawns POI buildings from the registry with
## interaction zones, signage labels, and faction territory markers.

const LABEL_HEIGHT_OFFSET := 0.4
const INTERACTION_RANGE := 3.5

@onready var buildings_node: Node3D = $Buildings
@onready var hint_label: Label = $"../UI/Hint" if has_node("../UI/Hint") else null

var active_poi_id: String = ""


func get_active_poi_id() -> String:
	return active_poi_id


func _ready() -> void:
	GameState.current_region = GameState.Region.CONSETT
	_spawn_all_pois()
	_spawn_street_props()
	_apply_time_of_day()
	GameState.game_time_advanced.connect(_on_time_advanced)


func _on_time_advanced(_new_hour: int) -> void:
	_apply_time_of_day()


func _apply_time_of_day() -> void:
	var env_node: WorldEnvironment = $WorldEnvironment
	if not env_node or not env_node.environment:
		return

	var env: Environment = env_node.environment
	var sun: DirectionalLight3D = $DirectionalLight3D
	var hour: int = GameState.game_hour
	var t: float = 0.0

	if hour >= 6 and hour < 8:
		t = (hour - 6.0) / 2.0
	elif hour >= 8 and hour < 18:
		t = 1.0
	elif hour >= 18 and hour < 21:
		t = 1.0 - (hour - 18.0) / 3.0
	else:
		t = 0.0

	var day_sky := Color(0.32, 0.52, 0.8)
	var night_sky := Color(0.04, 0.05, 0.1)
	var day_horizon := Color(0.68, 0.76, 0.84)
	var night_horizon := Color(0.08, 0.1, 0.15)
	var day_ambient := Color(0.82, 0.88, 0.94)
	var night_ambient := Color(0.15, 0.18, 0.25)

	var sky_mat: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
	if sky_mat:
		sky_mat.sky_top_color = night_sky.lerp(day_sky, t)
		sky_mat.sky_horizon_color = night_horizon.lerp(day_horizon, t)

	env.ambient_light_color = night_ambient.lerp(day_ambient, t)
	env.ambient_light_energy = lerpf(0.1, 0.38, t)

	if sun:
		sun.light_energy = lerpf(0.15, 1.15, t)
		sun.light_color = Color(0.9, 0.7, 0.5).lerp(Color(1.0, 0.98, 0.95), t)


func _spawn_all_pois() -> void:
	var pois: Array = POIRegistry.get_pois_for_region(GameState.Region.CONSETT)
	for poi in pois:
		_add_poi_building(poi)


func _add_poi_building(poi: Dictionary) -> void:
	var pos: Vector3 = poi["position"]
	var size: Vector3 = poi["size"]
	var colour: Color = poi["colour"]
	var poi_type: int = poi["type"]

	var body := StaticBody3D.new()
	body.name = poi["id"]
	body.position = Vector3(pos.x, 0.0, pos.z)
	body.set_meta("poi_id", poi["id"])
	body.set_meta("poi_type", poi_type)

	# Building mesh
	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()

	if poi_type == POIRegistry.POIType.PARK:
		box_mesh.size = Vector3(size.x, 0.15, size.z)
		mesh_inst.position = Vector3(0.0, 0.075, 0.0)
	else:
		box_mesh.size = size
		mesh_inst.position = Vector3(0.0, size.y * 0.5, 0.0)

	mesh_inst.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.88
	mesh_inst.material_override = mat

	# Collision
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_mesh.size
	col.position = mesh_inst.position
	col.shape = shape

	body.add_child(mesh_inst)
	body.add_child(col)

	# Signage (3D label floating above the building)
	if poi_type != POIRegistry.POIType.PARK:
		var sign_label := Label3D.new()
		sign_label.text = poi["display_name"]
		sign_label.font_size = 48
		sign_label.pixel_size = 0.01
		sign_label.position = Vector3(0.0, size.y + LABEL_HEIGHT_OFFSET, 0.0)
		sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign_label.modulate = _get_sign_colour(poi_type, poi)
		sign_label.outline_size = 8
		sign_label.name = "Sign"
		body.add_child(sign_label)

	# Interaction trigger zone (Area3D slightly larger than building)
	var area := Area3D.new()
	area.name = "InteractionZone"
	var area_col := CollisionShape3D.new()
	var area_shape := BoxShape3D.new()
	if poi_type == POIRegistry.POIType.PARK:
		area_shape.size = Vector3(size.x + 2.0, 4.0, size.z + 2.0)
		area_col.position = Vector3(0.0, 2.0, 0.0)
	else:
		area_shape.size = Vector3(size.x + INTERACTION_RANGE, size.y + 2.0, size.z + INTERACTION_RANGE)
		area_col.position = Vector3(0.0, size.y * 0.5, 0.0)
	area_col.shape = area_shape
	area.add_child(area_col)
	area.monitoring = true
	area.monitorable = false
	area.collision_layer = 0
	area.collision_mask = 2

	area.body_entered.connect(_on_poi_entered.bind(poi["id"], poi))
	area.body_exited.connect(_on_poi_exited.bind(poi["id"]))

	body.add_child(area)
	buildings_node.add_child(body)


func _get_sign_colour(poi_type: int, poi: Dictionary) -> Color:
	if poi.has("faction_id"):
		var faction: Dictionary = FactionManager.get_faction(poi["faction_id"])
		if not faction.is_empty():
			return faction.get("colour", Color.WHITE)

	match poi_type:
		POIRegistry.POIType.SAFEHOUSE: return Color(0.3, 0.9, 0.4)
		POIRegistry.POIType.BOOKIES: return Color(0.2, 0.85, 0.2)
		POIRegistry.POIType.NIGHTCLUB: return Color(0.7, 0.3, 0.9)
		POIRegistry.POIType.PARK: return Color(0.5, 0.7, 0.4)
		POIRegistry.POIType.VAPE_SHOP: return Color(0.6, 0.85, 0.55)
		POIRegistry.POIType.BARBERS: return Color(0.55, 0.75, 0.9)
		_: return Color(0.9, 0.85, 0.7)


func _on_poi_entered(_body: Node3D, poi_id: String, poi: Dictionary) -> void:
	active_poi_id = poi_id
	POIRegistry.poi_entered.emit(poi_id, POIRegistry.POIType.keys()[poi["type"]])

	var display: String = poi["display_name"]
	var desc: String = poi.get("description", "")
	var open := POIRegistry.is_open(poi, GameState.game_hour)

	var hint_text := "%s\n%s" % [display, desc]
	if not open:
		hint_text += "\n[CLOSED]"

	if poi.has("faction_id"):
		var bark: String = FactionManager.get_random_bark(poi["faction_id"])
		if bark != "":
			hint_text += "\n\n\"%s\"" % bark

	hint_text += "\n[E] Interact"

	if hint_label:
		hint_label.text = hint_text


func _on_poi_exited(_body: Node3D, poi_id: String) -> void:
	if active_poi_id == poi_id:
		active_poi_id = ""
		POIRegistry.poi_exited.emit(poi_id)
		if hint_label:
			hint_label.text = "WASD move · Shift sprint · Space jump · Mouse look · Esc menu · M map"


func _spawn_street_props() -> void:
	_add_street_light(Vector3(8.0, 0.0, 4.0))
	_add_street_light(Vector3(-8.0, 0.0, 4.0))
	_add_street_light(Vector3(18.0, 0.0, 18.0))
	_add_street_light(Vector3(-18.0, 0.0, 18.0))
	_add_street_light(Vector3(0.0, 0.0, 20.0))

	_add_bench(Vector3(4.0, 0.0, 2.0))
	_add_bench(Vector3(-4.0, 0.0, 2.0))
	_add_bench(Vector3(-28.0, 0.0, 14.0))

	_add_bin(Vector3(6.0, 0.0, 3.0))
	_add_bin(Vector3(-6.0, 0.0, 3.0))
	_add_bin(Vector3(12.0, 0.0, 18.0))


func _add_street_light(pos: Vector3) -> void:
	# Pole
	var pole := MeshInstance3D.new()
	var pole_mesh := BoxMesh.new()
	pole_mesh.size = Vector3(0.15, 5.0, 0.15)
	pole.mesh = pole_mesh
	pole.position = Vector3(pos.x, 2.5, pos.z)
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.25, 0.25, 0.28)
	pole.material_override = pole_mat
	buildings_node.add_child(pole)

	# Light head
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.6, 0.2, 0.3)
	head.mesh = head_mesh
	head.position = Vector3(pos.x, 5.1, pos.z)
	head.material_override = pole_mat
	buildings_node.add_child(head)

	# Actual light
	var light := OmniLight3D.new()
	light.position = Vector3(pos.x, 4.8, pos.z)
	light.light_energy = 0.6
	light.light_color = Color(1.0, 0.92, 0.7)
	light.omni_range = 10.0
	light.omni_attenuation = 1.5
	light.shadow_enabled = true
	buildings_node.add_child(light)


func _add_bench(pos: Vector3) -> void:
	var bench := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.8, 0.5, 0.6)
	bench.mesh = mesh
	bench.position = Vector3(pos.x, 0.25, pos.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2)
	mat.roughness = 0.95
	bench.material_override = mat
	buildings_node.add_child(bench)


func _add_bin(pos: Vector3) -> void:
	var bin_mesh := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.4, 0.7, 0.4)
	bin_mesh.mesh = mesh
	bin_mesh.position = Vector3(pos.x, 0.35, pos.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.22)
	bin_mesh.material_override = mat
	buildings_node.add_child(bin_mesh)
