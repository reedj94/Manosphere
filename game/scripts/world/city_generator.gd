extends Node3D

## Bridge between browser map editor JSON exports and CityCrafter3D.
## Loads a map_layout.json, generates the city using CityCrafter3D
## for the base grid, then overlays POIs and custom placements.

const MAP_LAYOUT_PATH := "res://data/maps/map_layout.json"
const CONFIG_PATHS := {
	"consett": "res://data/city_configs/consett_config.tres",
	"london": "res://data/city_configs/london_config.tres",
	"miami": "res://data/city_configs/miami_config.tres",
	"dubai": "res://data/city_configs/dubai_config.tres",
}


func generate_for_region(region_name: String) -> void:
	var config_path: String = CONFIG_PATHS.get(region_name, "")
	if config_path == "" or not ResourceLoader.exists(config_path):
		push_warning("CityGenerator: No config for region %s" % region_name)
		return

	var config: Resource = load(config_path)
	if not config:
		push_warning("CityGenerator: Failed to load config %s" % config_path)
		return

	# Look for CityCrafter node or create one
	var crafter: Node = null
	for child in get_children():
		if child.has_method("generate"):
			crafter = child
			break

	if not crafter:
		var crafter_script := load("res://addons/citycrafter/citycrafter.gd")
		if crafter_script:
			crafter = Node3D.new()
			crafter.set_script(crafter_script)
			crafter.name = "CityCrafter"
			add_child(crafter)

	if crafter and crafter.has_method("set_configuration"):
		crafter.set_configuration(config)
	if crafter and crafter.has_method("generate"):
		crafter.generate()

	_overlay_custom_placements(region_name)


func _overlay_custom_placements(region_name: String) -> void:
	if not FileAccess.file_exists(MAP_LAYOUT_PATH):
		return

	var file := FileAccess.open(MAP_LAYOUT_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()

	var data: Dictionary = json.data
	var region_data: Dictionary = data.get(region_name, {})
	if region_data.is_empty():
		return

	# Place vehicles from JSON
	var vehicles: Array = region_data.get("vehicles", [])
	for v in vehicles:
		var pos: Array = v.get("position", [0, 0, 0])
		var sz: Array = v.get("size", [2, 1.5, 4.5])
		var col: Array = v.get("colour", [0.5, 0.5, 0.5])
		var rot: float = v.get("rotation", 0)
		_spawn_box(Vector3(pos[0], pos[1], pos[2]), Vector3(sz[0], sz[1], sz[2]),
			Color(col[0], col[1], col[2]), rot)

	# Place water from JSON
	var water: Array = region_data.get("water", [])
	for w in water:
		var pos: Array = w.get("position", [0, 0, 0])
		var sz: Array = w.get("size", [10, 0.3, 10])
		var col: Array = w.get("colour", [0.2, 0.5, 0.8])
		_spawn_water(Vector3(pos[0], pos[1], pos[2]), Vector3(sz[0], sz[1], sz[2]),
			Color(col[0], col[1], col[2]))

	# Place props
	var props: Array = region_data.get("props", [])
	for p in props:
		var pos: Array = p.get("position", [0, 0, 0])
		var sz: Array = p.get("size", [0.5, 1, 0.5])
		_spawn_box(Vector3(pos[0], pos[1], pos[2]), Vector3(sz[0], sz[1], sz[2]),
			Color(0.5, 0.5, 0.5), 0)


func _spawn_box(pos: Vector3, sz: Vector3, col: Color, rot: float) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(pos.x, sz.y * 0.5, pos.z)

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = sz
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.85
	mesh_inst.material_override = mat

	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col_shape.shape = shape

	body.add_child(mesh_inst)
	body.add_child(col_shape)
	if rot != 0:
		body.rotation_degrees.y = rot
	add_child(body)


func _spawn_water(pos: Vector3, sz: Vector3, col: Color) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = sz
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(pos.x, sz.y * 0.5, pos.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.6
	mesh_inst.material_override = mat
	add_child(mesh_inst)
