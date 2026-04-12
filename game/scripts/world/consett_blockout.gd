extends Node3D

## Procedural greybox “high street” layout for Consett playtests.

const BUILDING_SPECS: Array = [
	[Vector3(22.0, 0.0, 10.0), Vector3(9.0, 11.0, 14.0), Color(0.48, 0.44, 0.42)],
	[Vector3(-20.0, 0.0, 12.0), Vector3(11.0, 9.0, 12.0), Color(0.42, 0.46, 0.5)],
	[Vector3(6.0, 0.0, -22.0), Vector3(18.0, 8.0, 9.0), Color(0.5, 0.42, 0.4)],
	[Vector3(-10.0, 0.0, -18.0), Vector3(7.0, 13.0, 8.0), Color(0.45, 0.45, 0.48)],
	[Vector3(28.0, 0.0, -8.0), Vector3(6.0, 7.0, 20.0), Color(0.52, 0.5, 0.46)],
	[Vector3(-28.0, 0.0, -6.0), Vector3(8.0, 10.0, 16.0), Color(0.4, 0.44, 0.46)],
	[Vector3(0.0, 0.0, 28.0), Vector3(24.0, 6.0, 10.0), Color(0.46, 0.48, 0.44)],
	[Vector3(14.0, 0.0, 22.0), Vector3(5.0, 15.0, 5.0), Color(0.44, 0.42, 0.5)],
	[Vector3(-16.0, 0.0, 26.0), Vector3(6.0, 12.0, 7.0), Color(0.5, 0.46, 0.42)],
	[Vector3(-32.0, 0.0, 18.0), Vector3(5.0, 8.0, 22.0), Color(0.43, 0.47, 0.45)],
	[Vector3(32.0, 0.0, 14.0), Vector3(5.0, 9.0, 11.0), Color(0.47, 0.43, 0.46)],
	[Vector3(10.0, 0.0, 4.0), Vector3(6.0, 5.0, 6.0), Color(0.55, 0.52, 0.48)],
	[Vector3(-8.0, 0.0, 2.0), Vector3(5.0, 5.5, 5.0), Color(0.52, 0.54, 0.5)],
]


func _ready() -> void:
	GameState.current_region = GameState.Region.CONSETT
	for spec in BUILDING_SPECS:
		_add_building(spec[0], spec[1], spec[2])


func _add_building(footprint_center: Vector3, size: Vector3, albedo: Color) -> void:
	var body := StaticBody3D.new()
	var half_h := size.y * 0.5
	body.position = Vector3(footprint_center.x, 0.0, footprint_center.z)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.position = Vector3(0.0, half_h, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = 0.9
	mesh_inst.material_override = mat

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.position = mesh_inst.position
	col.shape = shape

	body.add_child(mesh_inst)
	body.add_child(col)
	$Buildings.add_child(body)
