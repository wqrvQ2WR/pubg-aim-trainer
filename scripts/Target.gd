extends Node3D
## 사격 표적: 서있기 / 앉아있기 / 걷기 / 뛰기 상태를 가진다.

signal target_hit(target: Node3D, damage: int, is_kill: bool)
signal target_downed(target: Node3D)
signal target_respawned(target: Node3D)

enum TargetType { STANDING, SITTING, WALKING, RUNNING }

const TYPE_LABEL := {
	TargetType.STANDING: "서있는 표적",
	TargetType.SITTING: "앉아있는 표적",
	TargetType.WALKING: "걷는 표적",
	TargetType.RUNNING: "뛰는 표적",
}

const MAX_HEALTH := 100
const RESPAWN_DELAY := 2.2
const WALK_SPEED := 1.6
const RUN_SPEED := 5.5
const RUN_WOBBLE_AMP := 0.6
const RUN_WOBBLE_FREQ := 3.0

var target_type: int = TargetType.STANDING
var health: int = MAX_HEALTH
var is_downed: bool = false

var spawn_position: Vector3
var path_points: PackedVector3Array = PackedVector3Array()
var path_index: int = 0
var path_dir: int = 1
var move_speed: float = 0.0
var wobble_t: float = 0.0

var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var body_material: StandardMaterial3D
var head_material: StandardMaterial3D
var body_hitbox: Area3D
var head_hitbox: Area3D
var name_label: Label3D
var respawn_timer: Timer

const COLOR_NORMAL := Color(0.75, 0.32, 0.18)
const COLOR_HEAD := Color(0.85, 0.7, 0.55)
const COLOR_FLASH := Color(1.0, 0.15, 0.1)
const COLOR_DOWNED := Color(0.35, 0.35, 0.35)


func _ready() -> void:
	_build_visuals()
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.wait_time = RESPAWN_DELAY
	respawn_timer.timeout.connect(_respawn)
	add_child(respawn_timer)


func _build_visuals() -> void:
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = COLOR_NORMAL
	head_material = StandardMaterial3D.new()
	head_material.albedo_color = COLOR_HEAD

	var body_capsule := CapsuleMesh.new()
	body_capsule.radius = 0.32
	body_capsule.height = 1.4
	body_mesh = MeshInstance3D.new()
	body_mesh.mesh = body_capsule
	body_mesh.material_override = body_material
	body_mesh.position.y = 1.0
	add_child(body_mesh)

	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.22
	head_sphere.height = 0.44
	head_mesh = MeshInstance3D.new()
	head_mesh.mesh = head_sphere
	head_mesh.material_override = head_material
	head_mesh.position.y = 1.85
	add_child(head_mesh)

	body_hitbox = _make_hitbox("body", CapsuleShape3D.new(), Vector3(0, 1.0, 0))
	(body_hitbox.get_child(0).shape as CapsuleShape3D).radius = 0.34
	(body_hitbox.get_child(0).shape as CapsuleShape3D).height = 1.4

	head_hitbox = _make_hitbox("head", SphereShape3D.new(), Vector3(0, 1.85, 0))
	(head_hitbox.get_child(0).shape as SphereShape3D).radius = 0.24

	name_label = Label3D.new()
	name_label.text = TYPE_LABEL[target_type]
	name_label.position.y = 2.3
	name_label.font_size = 32
	name_label.outline_size = 8
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.modulate = Color(1, 1, 1, 0.85)
	add_child(name_label)


func _make_hitbox(part: String, shape: Shape3D, local_pos: Vector3) -> Area3D:
	var area := Area3D.new()
	area.set_script(load("res://scripts/Hitbox.gd"))
	area.target = self
	area.part = part
	area.collision_layer = 4
	area.collision_mask = 0
	area.position = local_pos
	var cs := CollisionShape3D.new()
	cs.shape = shape
	area.add_child(cs)
	add_child(area)
	return area


func setup(type: int, spawn_pos: Vector3, path: PackedVector3Array = PackedVector3Array()) -> void:
	target_type = type
	spawn_position = spawn_pos
	path_points = path
	path_index = 0
	path_dir = 1
	global_position = spawn_pos
	name_label.text = TYPE_LABEL[type]

	match type:
		TargetType.STANDING:
			_set_pose_standing()
			move_speed = 0.0
		TargetType.SITTING:
			_set_pose_sitting()
			move_speed = 0.0
		TargetType.WALKING:
			_set_pose_standing()
			move_speed = WALK_SPEED
		TargetType.RUNNING:
			_set_pose_standing()
			move_speed = RUN_SPEED

	health = MAX_HEALTH
	is_downed = false
	rotation = Vector3.ZERO
	body_material.albedo_color = COLOR_NORMAL
	visible = true
	for hb in [body_hitbox, head_hitbox]:
		hb.get_child(0).disabled = false


func _set_pose_standing() -> void:
	body_mesh.mesh.height = 1.4
	body_mesh.position.y = 1.0
	head_mesh.position.y = 1.85
	(body_hitbox.get_child(0).shape as CapsuleShape3D).height = 1.4
	body_hitbox.position.y = 1.0
	head_hitbox.position.y = 1.85
	name_label.position.y = 2.3


func _set_pose_sitting() -> void:
	body_mesh.mesh.height = 0.85
	body_mesh.position.y = 0.62
	head_mesh.position.y = 1.15
	(body_hitbox.get_child(0).shape as CapsuleShape3D).height = 0.85
	body_hitbox.position.y = 0.62
	head_hitbox.position.y = 1.15
	name_label.position.y = 1.6


func register_hit(damage: int, part: String, _hit_pos: Vector3) -> bool:
	if is_downed:
		return false
	var dmg := damage
	if part == "head":
		dmg *= 2
	health -= dmg
	_flash_hit()
	var killed := false
	if health <= 0:
		killed = true
		_on_downed()
	target_hit.emit(self, dmg, killed)
	return killed


func _flash_hit() -> void:
	body_material.albedo_color = COLOR_FLASH
	var t := get_tree().create_timer(0.08)
	t.timeout.connect(func():
		if not is_downed:
			body_material.albedo_color = COLOR_NORMAL
	)


func _on_downed() -> void:
	is_downed = true
	body_material.albedo_color = COLOR_DOWNED
	for hb in [body_hitbox, head_hitbox]:
		hb.get_child(0).disabled = true
	var tw := create_tween()
	tw.tween_property(self, "rotation:x", deg_to_rad(-85), 0.25)
	target_downed.emit(self)
	respawn_timer.start(RESPAWN_DELAY)


func _respawn() -> void:
	setup(target_type, spawn_position, path_points)
	target_respawned.emit(self)


func _process(delta: float) -> void:
	if is_downed or move_speed <= 0.0 or path_points.size() < 2:
		return

	var dest: Vector3 = path_points[path_index]
	var to_dest := dest - global_position
	to_dest.y = 0
	if to_dest.length() < 0.15:
		path_index += path_dir
		if path_index >= path_points.size():
			path_index = path_points.size() - 2
			path_dir = -1
		elif path_index < 0:
			path_index = 1
			path_dir = 1
		dest = path_points[path_index]
		to_dest = dest - global_position
		to_dest.y = 0

	var move_dir := to_dest.normalized()
	var offset := Vector3.ZERO
	if target_type == TargetType.RUNNING:
		wobble_t += delta * RUN_WOBBLE_FREQ
		var perp := Vector3(-move_dir.z, 0, move_dir.x)
		offset = perp * sin(wobble_t) * RUN_WOBBLE_AMP * delta

	global_position += move_dir * move_speed * delta + offset
	if move_dir.length() > 0.01:
		look_at(global_position + move_dir, Vector3.UP)
