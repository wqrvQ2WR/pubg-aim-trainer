extends Node3D
## 사격장 표적 배치 및 스폰 관리. 표적 종류 on/off 설정을 받아 레인을 재구성한다.

const TargetScript := preload("res://scripts/Target.gd")

signal target_hit(target: Node3D, damage: int, is_kill: bool)

var enabled_types: Dictionary = {
	0: true,  # STANDING
	1: true,  # SITTING
	2: true,  # WALKING
	3: true,  # RUNNING
}

var active_targets: Array = []


func _ready() -> void:
	build_range()


func set_type_enabled(type: int, enabled: bool) -> void:
	enabled_types[type] = enabled
	build_range()


func clear_range() -> void:
	for t in active_targets:
		if is_instance_valid(t):
			t.queue_free()
	active_targets.clear()


func build_range() -> void:
	clear_range()

	# 서있는/앉아있는 표적: 거리별 3열
	var still_type := -1
	if enabled_types.get(0, true) and enabled_types.get(1, true):
		still_type = -1  # alternate
	elif enabled_types.get(0, true):
		still_type = 0
	elif enabled_types.get(1, true):
		still_type = 1

	if still_type != -1 or (enabled_types.get(0, true) and enabled_types.get(1, true)):
		var rows := [-15.0, -40.0, -80.0]
		var xs := [-6.0, 0.0, 6.0]
		var idx := 0
		for z in rows:
			for x in xs:
				var t_type: int
				if still_type == -1:
					t_type = 0 if idx % 2 == 0 else 1
				else:
					t_type = still_type
				_spawn_target(t_type, Vector3(x, 0, z))
				idx += 1

	if enabled_types.get(2, true):
		var walk_path := PackedVector3Array([
			Vector3(-10, 0, -25), Vector3(10, 0, -25)
		])
		_spawn_target(2, walk_path[0], walk_path)
		var walk_path2 := PackedVector3Array([
			Vector3(-12, 0, -65), Vector3(12, 0, -65)
		])
		_spawn_target(2, walk_path2[0], walk_path2)

	if enabled_types.get(3, true):
		var run_path := PackedVector3Array([
			Vector3(-14, 0, -35), Vector3(14, 0, -35)
		])
		_spawn_target(3, run_path[0], run_path)
		var run_path2 := PackedVector3Array([
			Vector3(-16, 0, -95), Vector3(16, 0, -95)
		])
		_spawn_target(3, run_path2[0], run_path2)


func _spawn_target(type: int, pos: Vector3, path: PackedVector3Array = PackedVector3Array()) -> void:
	var t := Node3D.new()
	t.set_script(TargetScript)
	add_child(t)
	t.setup(type, pos, path)
	t.target_hit.connect(_on_target_hit)
	active_targets.append(t)


func _on_target_hit(target: Node3D, damage: int, is_kill: bool) -> void:
	target_hit.emit(target, damage, is_kill)
