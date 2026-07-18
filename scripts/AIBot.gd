extends CharacterBody3D
## AI 대전 상대: 시야가 확보되면 플레이어를 향해 스트레이핑하며 반응지연+탄퍼짐이
## 있는 사격을 한다. 완벽한 에임봇이 아니라 연습 상대로 이길 수 있는 수준.

signal ai_hit(damage: int, is_kill: bool)
signal ai_died()
signal ai_respawned()

const MAX_HEALTH := 100
const ENGAGE_RANGE := 55.0
const KEEP_DISTANCE_FAR := 24.0
const KEEP_DISTANCE_NEAR := 9.0
const RESPAWN_DELAY := 3.5
const STRAFE_CHANGE_INTERVAL := 1.4
const EYE_HEIGHT := 1.5

const COLOR_NORMAL := Color(0.75, 0.14, 0.12)
const COLOR_HEAD := Color(0.85, 0.55, 0.5)
const COLOR_FLASH := Color(1.0, 0.9, 0.2)
const COLOR_DOWNED := Color(0.3, 0.3, 0.3)

## 난이도별 파라미터 - 반응지연/탄퍼짐이 클수록, 연사간격이 길수록 약함
const DIFFICULTY_PRESETS := {
	"easy": {"reaction_delay": 0.95, "aim_spread_deg": 6.5, "fire_interval": 0.26, "damage_per_hit": 9, "move_speed": 2.3, "turn_speed": 2.0},
	"normal": {"reaction_delay": 0.6, "aim_spread_deg": 4.2, "fire_interval": 0.19, "damage_per_hit": 13, "move_speed": 2.9, "turn_speed": 2.6},
	"hard": {"reaction_delay": 0.4, "aim_spread_deg": 2.8, "fire_interval": 0.15, "damage_per_hit": 17, "move_speed": 3.4, "turn_speed": 3.2},
}
const DEFAULT_DIFFICULTY := "normal"

var move_speed: float = 2.9
var turn_speed: float = 2.6
var fire_interval: float = 0.19
var aim_spread_deg: float = 4.2
var reaction_delay: float = 0.6
var damage_per_hit: int = 13

var health: int = MAX_HEALTH
var is_dead: bool = false
var player: Node3D = null
var spawn_points: Array = []
var terrain_provider: Node = null
const GROUND_CLEARANCE := 0.02

var fire_timer: float = 0.0
var sight_timer: float = 0.0
var strafe_dir: int = 1
var strafe_timer: float = STRAFE_CHANGE_INTERVAL
var los_check_timer: float = 0.0
var has_los_cached: bool = false

var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var body_material: StandardMaterial3D
var body_hitbox: Area3D
var head_hitbox: Area3D
var name_label: Label3D
var health_label: Label3D


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	floor_max_angle = deg_to_rad(50)

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	var coll := CollisionShape3D.new()
	coll.shape = capsule
	coll.position.y = 0.9
	add_child(coll)

	_build_visuals()


func _build_visuals() -> void:
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = COLOR_NORMAL
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = COLOR_HEAD

	var body_capsule := CapsuleMesh.new()
	body_capsule.radius = 0.34
	body_capsule.height = 1.4
	body_mesh = MeshInstance3D.new()
	body_mesh.mesh = body_capsule
	body_mesh.material_override = body_material
	body_mesh.position.y = 1.0
	add_child(body_mesh)

	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.23
	head_sphere.height = 0.46
	head_mesh = MeshInstance3D.new()
	head_mesh.mesh = head_sphere
	head_mesh.material_override = head_material
	head_mesh.position.y = 1.85
	add_child(head_mesh)

	body_hitbox = _make_hitbox("body", Vector3(0, 1.0, 0))
	var body_shape := CapsuleShape3D.new()
	body_shape.radius = 0.36
	body_shape.height = 1.4
	(body_hitbox.get_child(0) as CollisionShape3D).shape = body_shape

	head_hitbox = _make_hitbox("head", Vector3(0, 1.85, 0))
	var head_shape := SphereShape3D.new()
	head_shape.radius = 0.25
	(head_hitbox.get_child(0) as CollisionShape3D).shape = head_shape

	name_label = Label3D.new()
	name_label.text = "AI"
	name_label.position.y = 2.3
	name_label.font_size = 32
	name_label.outline_size = 8
	name_label.modulate = Color(1.0, 0.7, 0.7, 0.9)
	add_child(name_label)

	health_label = Label3D.new()
	health_label.text = "100"
	health_label.position.y = 2.05
	health_label.font_size = 24
	health_label.outline_size = 6
	health_label.modulate = Color(1.0, 1.0, 1.0, 0.85)
	add_child(health_label)


func _make_hitbox(part: String, local_pos: Vector3) -> Area3D:
	var area := Area3D.new()
	area.set_script(load("res://scripts/Hitbox.gd"))
	area.target = self
	area.part = part
	area.collision_layer = 4
	area.collision_mask = 0
	area.position = local_pos
	var cs := CollisionShape3D.new()
	area.add_child(cs)
	add_child(area)
	return area


func set_difficulty(level: String) -> void:
	var p: Dictionary = DIFFICULTY_PRESETS.get(level, DIFFICULTY_PRESETS[DEFAULT_DIFFICULTY])
	reaction_delay = p["reaction_delay"]
	aim_spread_deg = p["aim_spread_deg"]
	fire_interval = p["fire_interval"]
	damage_per_hit = p["damage_per_hit"]
	move_speed = p["move_speed"]
	turn_speed = p["turn_speed"]


func spawn_at(pos: Vector3) -> void:
	health = MAX_HEALTH
	is_dead = false
	global_position = pos
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	sight_timer = 0.0
	fire_timer = 0.0
	body_material.albedo_color = COLOR_NORMAL
	health_label.text = str(health)
	visible = true
	for hb in [body_hitbox, head_hitbox]:
		(hb.get_child(0) as CollisionShape3D).disabled = false


func register_hit(damage: int, part: String, _hit_pos: Vector3) -> bool:
	if is_dead:
		return false
	var dmg := damage
	if part == "head":
		dmg *= 2
	health -= dmg
	health_label.text = str(max(health, 0))
	_flash_hit()
	var killed := false
	if health <= 0:
		killed = true
		_die()
	ai_hit.emit(dmg, killed)
	return killed


func _flash_hit() -> void:
	body_material.albedo_color = COLOR_FLASH
	var t := get_tree().create_timer(0.08)
	t.timeout.connect(func():
		if not is_dead:
			body_material.albedo_color = COLOR_NORMAL
	)


func _die() -> void:
	is_dead = true
	body_material.albedo_color = COLOR_DOWNED
	for hb in [body_hitbox, head_hitbox]:
		(hb.get_child(0) as CollisionShape3D).disabled = true
	var tw := create_tween()
	tw.tween_property(self, "rotation:x", deg_to_rad(-85), 0.25)
	ai_died.emit()
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(_respawn)


func _respawn() -> void:
	var pos: Vector3 = spawn_points[randi() % spawn_points.size()] if not spawn_points.is_empty() else global_position
	spawn_at(pos)
	ai_respawned.emit()


func _has_line_of_sight() -> bool:
	if not player:
		return false
	var space_state := get_world_3d().direct_space_state
	var eye_pos := global_position + Vector3(0, EYE_HEIGHT, 0)
	var target_pos: Vector3 = player.global_position + Vector3(0, 1.4, 0)
	var dir := target_pos - eye_pos
	var dist := dir.length()
	if dist < 0.05:
		return true
	var to := eye_pos + dir.normalized() * (dist + 1.0)
	var query := PhysicsRayQueryParameters3D.create(eye_pos, to)
	query.collision_mask = 1
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return true
	return result["collider"] == player


func _shoot_at_player() -> void:
	if not player:
		return
	var space_state := get_world_3d().direct_space_state
	var eye_pos := global_position + Vector3(0, EYE_HEIGHT, 0)
	var target_pos: Vector3 = player.global_position + Vector3(0, randf_range(1.15, 1.6), 0)
	var dir := (target_pos - eye_pos).normalized()

	var spread := deg_to_rad(aim_spread_deg)
	var rand_yaw := (randf() * 2.0 - 1.0) * spread
	var rand_pitch := (randf() * 2.0 - 1.0) * spread
	var aim_basis := Basis.looking_at(dir, Vector3.UP)
	var final_dir := (aim_basis * Vector3(rand_yaw, rand_pitch, -1.0)).normalized()

	var to := eye_pos + final_dir * 200.0
	var query := PhysicsRayQueryParameters3D.create(eye_pos, to)
	query.collision_mask = 1
	var result := space_state.intersect_ray(query)
	if result and result.has("collider") and result["collider"] == player and player.has_method("take_hit"):
		player.take_hit(damage_per_hit, result["position"])


func _physics_process(delta: float) -> void:
	if terrain_provider:
		velocity.y = 0.0
	elif not is_on_floor():
		velocity.y -= 20.0 * delta

	if is_dead or not player or player.is_dead:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		_snap_to_terrain()
		return

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	los_check_timer -= delta
	if los_check_timer <= 0.0:
		has_los_cached = _has_line_of_sight()
		los_check_timer = 0.15

	if has_los_cached and dist < ENGAGE_RANGE and dist > 0.01:
		sight_timer += delta
		var forward_dir := to_player.normalized()
		var target_yaw := atan2(forward_dir.x, forward_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

		strafe_timer -= delta
		if strafe_timer <= 0.0:
			strafe_dir *= -1
			strafe_timer = STRAFE_CHANGE_INTERVAL

		var perp := Vector3(-forward_dir.z, 0, forward_dir.x)
		var move_vec := perp * float(strafe_dir)
		if dist > KEEP_DISTANCE_FAR:
			move_vec += forward_dir * 0.6
		elif dist < KEEP_DISTANCE_NEAR:
			move_vec -= forward_dir * 0.6
		if move_vec.length() > 0.01:
			move_vec = move_vec.normalized()
			velocity.x = move_vec.x * move_speed
			velocity.z = move_vec.z * move_speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0

		fire_timer -= delta
		if sight_timer > reaction_delay and fire_timer <= 0.0:
			_shoot_at_player()
			fire_timer = fire_interval
	else:
		sight_timer = 0.0
		if dist > 1.5:
			var seek_dir := to_player.normalized()
			velocity.x = seek_dir.x * move_speed * 0.8
			velocity.z = seek_dir.z * move_speed * 0.8
			var seek_yaw := atan2(seek_dir.x, seek_dir.z)
			rotation.y = lerp_angle(rotation.y, seek_yaw, turn_speed * delta)
		else:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()
	_snap_to_terrain()


func _snap_to_terrain() -> void:
	if not terrain_provider:
		return
	var h: float = terrain_provider.height_at_world(global_position.x, global_position.z)
	global_position.y = h + GROUND_CLEARANCE
