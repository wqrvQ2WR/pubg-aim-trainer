extends Node3D
## AI 대전 전용 아레나. 사격장과 겹치지 않도록 멀리 떨어진 좌표(X 오프셋)에
## 절차적 높이맵 지형(능선 2개)과 엄폐물, 경계벽을 생성한다.

const OFFSET_X := 600.0
const HALF_X := 36.0
const MIN_Z := -95.0
const MAX_Z := -10.0
const GRID_STEP := 2.0
const WALL_HEIGHT := 16.0

const RIDGE1_Z := -32.0
const RIDGE2_Z := -68.0

var spawn_points: Array = []
var player_start: Vector3


func _ready() -> void:
	_build_terrain()
	_build_walls()
	_build_cover()
	_build_spawn_points()


## 아레나 로컬 X(중심 기준)와 월드 Z를 받아 지형 높이를 반환한다.
func height_at_local(x: float, z: float) -> float:
	var ridge1 := 2.2 * exp(-pow((z - RIDGE1_Z) / 9.0, 2))
	var ridge2 := 1.8 * exp(-pow((z - RIDGE2_Z) / 9.0, 2))
	var bumps := 0.3 * sin(x * 0.2) * cos(z * 0.15)
	var h := ridge1 + ridge2 + bumps

	var edge_dist_x: float = HALF_X - abs(x)
	var edge_dist_z: float = min(z - MIN_Z, MAX_Z - z)
	var edge_dist: float = min(edge_dist_x, edge_dist_z)
	var falloff: float = clamp(edge_dist / 6.0, 0.0, 1.0)
	return h * falloff


## 월드 XZ 좌표를 받아 지형 높이를 반환 (스폰/배치 계산용)
func height_at_world(world_x: float, z: float) -> float:
	return height_at_local(world_x - OFFSET_X, z)


func _build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var steps_x := int((HALF_X * 2.0) / GRID_STEP)
	var steps_z := int((MAX_Z - MIN_Z) / GRID_STEP)

	var get_pos := func(ix: int, iz: int) -> Vector3:
		var x: float = -HALF_X + float(ix) * GRID_STEP
		var z: float = MIN_Z + float(iz) * GRID_STEP
		var y := height_at_local(x, z)
		return Vector3(OFFSET_X + x, y, z)

	for iz in range(steps_z):
		for ix in range(steps_x):
			var p00: Vector3 = get_pos.call(ix, iz)
			var p10: Vector3 = get_pos.call(ix + 1, iz)
			var p01: Vector3 = get_pos.call(ix, iz + 1)
			var p11: Vector3 = get_pos.call(ix + 1, iz + 1)
			st.add_vertex(p00)
			st.add_vertex(p01)
			st.add_vertex(p10)
			st.add_vertex(p10)
			st.add_vertex(p01)
			st.add_vertex(p11)

	st.generate_normals()
	var mesh := st.commit()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.44, 0.3)
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	add_child(mesh_inst)

	var body := StaticBody3D.new()
	var coll := CollisionShape3D.new()
	coll.shape = mesh.create_trimesh_shape()
	body.add_child(coll)
	add_child(body)


func _build_walls() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.25, 0.27, 0.24)
	wall_mat.roughness = 0.9

	var depth := MAX_Z - MIN_Z
	var center_z := (MAX_Z + MIN_Z) / 2.0

	_add_box(Vector3(1, WALL_HEIGHT, depth), Vector3(OFFSET_X - HALF_X, WALL_HEIGHT / 2.0, center_z), wall_mat)
	_add_box(Vector3(1, WALL_HEIGHT, depth), Vector3(OFFSET_X + HALF_X, WALL_HEIGHT / 2.0, center_z), wall_mat)
	_add_box(Vector3(HALF_X * 2.0, WALL_HEIGHT, 1), Vector3(OFFSET_X, WALL_HEIGHT / 2.0, MIN_Z), wall_mat)
	_add_box(Vector3(HALF_X * 2.0, WALL_HEIGHT, 1), Vector3(OFFSET_X, WALL_HEIGHT / 2.0, MAX_Z), wall_mat)


func _build_cover() -> void:
	var crate_mat := StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.45, 0.32, 0.18)
	crate_mat.roughness = 0.85

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.42, 0.42, 0.44)
	rock_mat.roughness = 1.0

	var crate_spots := [
		Vector2(-14, -18), Vector2(10, -22), Vector2(-6, -40),
		Vector2(16, -44), Vector2(-20, -58), Vector2(4, -62),
		Vector2(-10, -80), Vector2(18, -84),
	]
	for spot in crate_spots:
		var x: float = spot.x
		var z: float = spot.y
		var y := height_at_local(x, z)
		var size := Vector3(1.3, 1.3, 1.3)
		_add_box(size, Vector3(OFFSET_X + x, y + size.y / 2.0, z), crate_mat)

	var rock_spots := [
		Vector2(-24, -14), Vector2(22, -30), Vector2(0, -50),
		Vector2(-16, -70), Vector2(26, -76), Vector2(-2, -90),
	]
	for spot in rock_spots:
		var x: float = spot.x
		var z: float = spot.y
		var y := height_at_local(x, z)
		var radius := randf_range(1.1, 1.7)
		_add_rock(Vector3(OFFSET_X + x, y + radius * 0.5, z), radius, rock_mat)


func _add_box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	var coll := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	coll.shape = shape
	body.add_child(coll)
	add_child(body)


func _add_rock(pos: Vector3, radius: float, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.7
	mesh_inst.mesh = sphere
	mesh_inst.material_override = mat
	mesh_inst.scale = Vector3(1.0, 0.85, 1.1)
	body.add_child(mesh_inst)
	var coll := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	coll.shape = shape
	coll.scale = Vector3(1.0, 0.85, 1.1)
	body.add_child(coll)
	add_child(body)


func _build_spawn_points() -> void:
	var candidates := [
		Vector2(0, -15), Vector2(-18, -25), Vector2(18, -25),
		Vector2(-10, -45), Vector2(12, -48), Vector2(0, -55),
		Vector2(-16, -65), Vector2(16, -68), Vector2(-6, -88),
		Vector2(8, -90),
	]
	spawn_points.clear()
	for spot in candidates:
		var x: float = spot.x
		var z: float = spot.y
		var y := height_at_local(x, z) + 1.0
		spawn_points.append(Vector3(OFFSET_X + x, y, z))

	var start_y := height_at_local(0, -14) + 1.0
	player_start = Vector3(OFFSET_X, start_y, -14)
