extends Node3D
## 사격장 씬 조립: 환경, 플레이어, 표적 매니저, HUD/무기선택/설정 UI를 생성하고 연결한다.

var player: CharacterBody3D
var range_manager: Node3D
var duel_manager: Node3D


func _ready() -> void:
	_build_environment()
	_build_player()
	_build_range()
	_build_duel()
	_build_ui()


func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.30, 0.45, 0.75)
	sky_material.sky_horizon_color = Color(0.65, 0.72, 0.78)
	sky_material.ground_bottom_color = Color(0.3, 0.3, 0.3)
	sky_material.ground_horizon_color = Color(0.65, 0.72, 0.78)
	var sky := Sky.new()
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.5, 0.47, 0.4)
	ground_mat.roughness = 0.95
	_add_box(Vector3(60, 1, 220), Vector3(0, -0.5, -85), ground_mat)

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.28, 0.3, 0.33)
	wall_mat.roughness = 0.9

	_add_box(Vector3(1, 16, 220), Vector3(-30, 8, -85), wall_mat)
	_add_box(Vector3(1, 16, 220), Vector3(30, 8, -85), wall_mat)
	_add_box(Vector3(60, 20, 1), Vector3(0, 10, -196), wall_mat)
	_add_box(Vector3(60, 6, 1), Vector3(0, 3, 14), wall_mat)

	_add_distance_marker(-10)
	_add_distance_marker(-25)
	_add_distance_marker(-50)
	_add_distance_marker(-100)
	_add_distance_marker(-150)


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


func _add_distance_marker(z: float) -> void:
	var label := Label3D.new()
	label.text = "%dm" % int(abs(z))
	label.font_size = 48
	label.outline_size = 10
	label.position = Vector3(-28, 0.2, z)
	label.rotation_degrees = Vector3(-90, 0, 0)
	add_child(label)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/Player.gd"))
	player.position = Vector3(0, 0.1, 8)
	add_child(player)


func _build_range() -> void:
	range_manager = Node3D.new()
	range_manager.name = "RangeManager"
	range_manager.set_script(load("res://scripts/RangeManager.gd"))
	add_child(range_manager)


func _build_duel() -> void:
	var arena := Node3D.new()
	arena.name = "DuelArena"
	arena.set_script(load("res://scripts/DuelArena.gd"))
	add_child(arena)

	duel_manager = Node3D.new()
	duel_manager.name = "DuelManager"
	duel_manager.set_script(load("res://scripts/DuelManager.gd"))
	duel_manager.player = player
	duel_manager.arena = arena
	add_child(duel_manager)


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var hud := Control.new()
	hud.set_script(load("res://scripts/HUD.gd"))
	hud.player = player
	hud.duel_manager = duel_manager
	canvas.add_child(hud)

	var weapon_select := Control.new()
	weapon_select.set_script(load("res://scripts/WeaponSelectUI.gd"))
	weapon_select.player = player
	canvas.add_child(weapon_select)

	var settings := Control.new()
	settings.set_script(load("res://scripts/SettingsUI.gd"))
	settings.player = player
	settings.range_manager = range_manager
	settings.duel_manager = duel_manager
	canvas.add_child(settings)
