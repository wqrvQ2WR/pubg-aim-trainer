extends CharacterBody3D
## 1인칭 플레이어 컨트롤러: 이동, 자세, 마우스룩, 발사 & 반동 적용

signal weapon_changed(weapon_id: String)
signal ammo_changed(current: int, magazine: int)
signal stance_changed(stance_label: String)
signal fire_mode_changed(mode: String)
signal hit_registered(is_kill: bool)
signal shot_fired()
signal ads_changed(active: bool)
signal shoulder_changed(active: bool)
signal health_changed(current: int, max_health: int)
signal died()
signal respawned()

enum Stance { STAND, CROUCH, PRONE }

const SPEED_STAND := 5.0
const SPEED_SPRINT := 8.5
const SPEED_CROUCH := 2.6
const SPEED_PRONE := 1.3
const JUMP_VELOCITY := 6.0
const MOUSE_SENS_BASE := 0.0022
const PITCH_LIMIT := deg_to_rad(89.0)
const BASE_FOV := 80.0
const ADS_SENS_MULT := 0.55
const ADS_TWEEN_TIME := 0.12
const SHOULDER_FOV_MULT := 0.92
const SHOULDER_SENS_MULT := 0.8
const SHOULDER_RECOIL_MULT := 0.8
const MAX_HEALTH := 100
const RESPAWN_DELAY := 3.0

const HEIGHT_STAND := 1.8
const HEIGHT_CROUCH := 1.1
const HEIGHT_PRONE := 0.5
const CAM_Y_STAND := 1.6
const CAM_Y_CROUCH := 0.9
const CAM_Y_PRONE := 0.35

var stance: int = Stance.STAND
var sensitivity: float = 1.0

var head: Node3D
var camera: Camera3D
var collision_shape: CollisionShape3D
var capsule: CapsuleShape3D
var gun_holder: Node3D

var current_weapon_id: String = ""
var ammo_in_mag: int = 0
var fire_mode_index: int = 0
var shot_index: int = 0
var fire_timer: float = 0.0
var auto_hold: bool = false
var shots_remaining_in_trigger: int = 0
var is_sprinting: bool = false

var mouse_captured: bool = true
var is_ads: bool = false
var is_shoulder: bool = false
var ads_tween: Tween
var chamber_tween: Tween
var is_reloading: bool = false

var health: int = MAX_HEALTH
var is_dead: bool = false
var spawn_position: Vector3
var temp_spawn: Vector3 = Vector3.ZERO
var has_temp_spawn: bool = false


func _ready() -> void:
	head = Node3D.new()
	head.name = "Head"
	add_child(head)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = BASE_FOV
	head.add_child(camera)

	capsule = CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = HEIGHT_STAND
	collision_shape = CollisionShape3D.new()
	collision_shape.shape = capsule
	collision_shape.position.y = HEIGHT_STAND / 2.0
	add_child(collision_shape)

	floor_max_angle = deg_to_rad(50)

	gun_holder = Node3D.new()
	gun_holder.name = "GunHolder"
	gun_holder.position = Vector3(0.28, -0.28, -0.6)
	camera.add_child(gun_holder)

	set_weapon(WeaponData.DEFAULT_WEAPON)
	_apply_stance_visuals()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn_position = global_position


func set_sensitivity(v: float) -> void:
	sensitivity = v


func set_temp_spawn(pos: Vector3) -> void:
	temp_spawn = pos
	has_temp_spawn = true


func clear_temp_spawn() -> void:
	has_temp_spawn = false


func heal_full() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)


func teleport_to(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	rotation.y = 0.0
	head.rotation.x = 0.0


func take_hit(damage: int, _hit_pos: Vector3 = Vector3.ZERO) -> bool:
	if is_dead:
		return false
	health -= damage
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		_die()
		return true
	return false


func _die() -> void:
	is_dead = true
	auto_hold = false
	shots_remaining_in_trigger = 0
	_set_ads(false)
	_set_shoulder(false)
	died.emit()
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(_respawn)


func _respawn() -> void:
	health = MAX_HEALTH
	is_dead = false
	teleport_to(temp_spawn if has_temp_spawn else spawn_position)
	set_stance(Stance.STAND)
	is_reloading = false
	if chamber_tween:
		chamber_tween.kill()
		gun_holder.rotation = Vector3.ZERO
		gun_holder.position = Vector3(0.28, -0.28, -0.6)
	var w := WeaponData.get_weapon(current_weapon_id)
	ammo_in_mag = w["magazine"]
	shot_index = 0
	ammo_changed.emit(ammo_in_mag, w["magazine"])
	health_changed.emit(health, MAX_HEALTH)
	respawned.emit()


func set_weapon(id: String) -> void:
	if not WeaponData.WEAPONS.has(id):
		return
	current_weapon_id = id
	var w := WeaponData.get_weapon(id)
	is_reloading = false
	if chamber_tween:
		chamber_tween.kill()
		if gun_holder:
			gun_holder.rotation = Vector3.ZERO
			gun_holder.position = Vector3(0.28, -0.28, -0.6)
	ammo_in_mag = w["magazine"]
	fire_mode_index = w["fire_modes"].size() - 1
	shot_index = 0
	auto_hold = false
	shots_remaining_in_trigger = 0
	is_sprinting = false
	_set_ads(false)
	_set_shoulder(false)
	_update_gun_visual(w["category"])
	weapon_changed.emit(id)
	ammo_changed.emit(ammo_in_mag, w["magazine"])
	fire_mode_changed.emit(get_current_fire_mode())


func _set_ads(active: bool) -> void:
	is_ads = active
	_update_fov()
	ads_changed.emit(is_ads)


func _set_shoulder(active: bool) -> void:
	is_shoulder = active
	_update_fov()
	shoulder_changed.emit(is_shoulder)


func _update_fov() -> void:
	if is_reloading:
		return
	if ads_tween:
		ads_tween.kill()
	if chamber_tween:
		chamber_tween.kill()
	if gun_holder:
		gun_holder.rotation = Vector3.ZERO
	var target_fov := BASE_FOV
	var target_gun_pos := Vector3(0.28, -0.28, -0.6)
	if is_ads:
		target_fov = BASE_FOV * WeaponData.get_ads_fov_mult(current_weapon_id)
		target_gun_pos = Vector3(0.0, -0.18, -0.45)
	elif is_shoulder:
		target_fov = BASE_FOV * SHOULDER_FOV_MULT
		target_gun_pos = Vector3(0.2, -0.22, -0.5)
	ads_tween = create_tween()
	ads_tween.set_parallel(true)
	ads_tween.tween_property(camera, "fov", target_fov, ADS_TWEEN_TIME)
	if gun_holder:
		ads_tween.tween_property(gun_holder, "position", target_gun_pos, ADS_TWEEN_TIME)


func _current_sens_mult() -> float:
	if is_ads:
		return ADS_SENS_MULT
	if is_shoulder:
		return SHOULDER_SENS_MULT
	return 1.0


func get_current_fire_mode() -> String:
	var w := WeaponData.get_weapon(current_weapon_id)
	var modes: Array = w["fire_modes"]
	return modes[fire_mode_index]


func cycle_fire_mode() -> void:
	var w := WeaponData.get_weapon(current_weapon_id)
	var modes: Array = w["fire_modes"]
	if modes.size() <= 1:
		return
	fire_mode_index = (fire_mode_index + 1) % modes.size()
	fire_mode_changed.emit(get_current_fire_mode())


func reload() -> void:
	if is_reloading:
		return
	var w := WeaponData.get_weapon(current_weapon_id)
	if ammo_in_mag == w["magazine"]:
		return
	is_reloading = true
	_set_ads(false)
	_set_shoulder(false)
	
	if ads_tween:
		ads_tween.kill()
	if chamber_tween:
		chamber_tween.kill()
	
	chamber_tween = create_tween()
	var base_pos := Vector3(0.28, -0.28, -0.6)
	var lower_pos := base_pos + Vector3(-0.06, -0.25, 0.08)
	var lower_rot := Vector3(deg_to_rad(-30), deg_to_rad(-10), deg_to_rad(-25))
	
	# 1. Lower gun
	chamber_tween.tween_property(gun_holder, "position", lower_pos, 0.35)
	chamber_tween.parallel().tween_property(gun_holder, "rotation", lower_rot, 0.35)
	
	# 2. Shake (magazine out/in)
	var shake_pos := lower_pos + Vector3(0, 0.03, -0.02)
	chamber_tween.tween_property(gun_holder, "position", shake_pos, 0.15)
	chamber_tween.tween_property(gun_holder, "position", lower_pos, 0.15)
	
	# 3. Pull bolt / slide back
	var bolt_rot := lower_rot + Vector3(deg_to_rad(5), deg_to_rad(8), deg_to_rad(5))
	chamber_tween.tween_property(gun_holder, "rotation", bolt_rot, 0.2)
	chamber_tween.tween_property(gun_holder, "rotation", lower_rot, 0.15)
	
	# 4. Rise back up
	chamber_tween.tween_property(gun_holder, "position", base_pos, 0.35)
	chamber_tween.parallel().tween_property(gun_holder, "rotation", Vector3.ZERO, 0.35)
	
	# 5. Done callback
	chamber_tween.tween_callback(func():
		ammo_in_mag = w["magazine"]
		shot_index = 0
		is_reloading = false
		ammo_changed.emit(ammo_in_mag, w["magazine"])
	)


func set_stance(new_stance: int) -> void:
	if stance == new_stance:
		return
	stance = new_stance
	_apply_stance_visuals()
	var label := "서기"
	if stance == Stance.CROUCH:
		label = "앉기"
	elif stance == Stance.PRONE:
		label = "엎드리기"
	stance_changed.emit(label)


func _apply_stance_visuals() -> void:
	var h := HEIGHT_STAND
	var cam_y := CAM_Y_STAND
	match stance:
		Stance.CROUCH:
			h = HEIGHT_CROUCH
			cam_y = CAM_Y_CROUCH
		Stance.PRONE:
			h = HEIGHT_PRONE
			cam_y = CAM_Y_PRONE
	capsule.height = h
	collision_shape.position.y = h / 2.0
	head.position.y = cam_y


func _stance_recoil_multiplier() -> float:
	match stance:
		Stance.CROUCH:
			return 0.5
		Stance.PRONE:
			return 0.34
		_:
			return 1.0


func _stance_spread_multiplier() -> float:
	match stance:
		Stance.CROUCH:
			return 0.55
		Stance.PRONE:
			return 0.3
		_:
			return 1.0


## 이동/자세/조준 상태에 따른 탄퍼짐(도 단위) - 걸을수록/뛸수록 넓어지고
## 앉거나 엎드리면 줄어들며, 조준(ADS)/견착 시에는 크게/약간 줄어든다.
func get_spread_deg() -> float:
	return _current_spread_deg()


func _current_spread_deg() -> float:
	if is_ads:
		return 0.0
	var base := WeaponData.get_base_spread(current_weapon_id)
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var speed_ratio: float = clamp(horizontal_speed / SPEED_STAND, 0.0, 1.3)
	var move_mult := 1.0 + speed_ratio * 2.2
	var stance_mult := _stance_spread_multiplier()
	var aim_mult := 1.0
	if is_shoulder:
		aim_mult = 0.7
	return base * move_mult * stance_mult * aim_mult


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseMotion and mouse_captured:
		var sens_mult := _current_sens_mult()
		rotate_y(-event.relative.x * MOUSE_SENS_BASE * sensitivity * sens_mult)
		head.rotate_x(-event.relative.y * MOUSE_SENS_BASE * sensitivity * sens_mult)
		head.rotation.x = clamp(head.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)

	if event.is_action_pressed("ads") and mouse_captured:
		if not is_reloading:
			_set_ads(true)
	if event.is_action_released("ads"):
		_set_ads(false)
	if event.is_action_pressed("shoulder") and mouse_captured:
		if not is_reloading:
			_set_shoulder(true)
	if event.is_action_released("shoulder"):
		_set_shoulder(false)

	if event.is_action_pressed("fire") and mouse_captured:
		if is_reloading:
			return
		if ammo_in_mag <= 0:
			reload()
			return
		shot_index = 0
		var mode := get_current_fire_mode()
		match mode:
			"single":
				shots_remaining_in_trigger = 1
			"burst":
				shots_remaining_in_trigger = 3
			"auto":
				auto_hold = true
	if event.is_action_released("fire"):
		auto_hold = false
		shots_remaining_in_trigger = 0

	if event.is_action_pressed("reload"):
		reload()
	if event.is_action_pressed("fire_mode_switch"):
		cycle_fire_mode()
	if event.is_action_pressed("crouch"):
		set_stance(Stance.STAND if stance == Stance.CROUCH else Stance.CROUCH)
	if event.is_action_pressed("prone"):
		set_stance(Stance.STAND if stance == Stance.PRONE else Stance.PRONE)
	if event.is_action_pressed("jump") and stance == Stance.STAND and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if event is InputEventKey and event.keycode == KEY_SHIFT and not event.echo:
		is_sprinting = event.pressed
		if is_sprinting and mouse_captured:
			if is_ads:
				_set_ads(false)
			if is_shoulder:
				_set_shoulder(false)
			if stance != Stance.STAND:
				set_stance(Stance.STAND)
			auto_hold = false
			shots_remaining_in_trigger = 0

	if event.is_action_pressed("ui_release_mouse"):
		_toggle_mouse_capture()


func _toggle_mouse_capture(force_release: bool = false) -> void:
	if mouse_captured and not force_release:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
	elif not force_release:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false


func set_mouse_captured(value: bool) -> void:
	mouse_captured = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE
	if not value:
		is_sprinting = false
		if is_ads:
			_set_ads(false)
		if is_shoulder:
			_set_shoulder(false)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	if is_dead:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Sprint validation
	if is_sprinting and (input_dir.length() <= 0.01 or stance != Stance.STAND or is_ads or is_shoulder or is_reloading):
		is_sprinting = false
	if is_sprinting:
		auto_hold = false
		shots_remaining_in_trigger = 0

	var speed := SPEED_STAND
	if is_sprinting:
		speed = SPEED_SPRINT
	elif stance == Stance.CROUCH:
		speed = SPEED_CROUCH
	elif stance == Stance.PRONE:
		speed = SPEED_PRONE
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dir.length() > 0.01:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 6.0 * delta)

	move_and_slide()
	_process_firing(delta)


func _process_firing(delta: float) -> void:
	fire_timer -= delta
	if is_reloading:
		return
	if (auto_hold or shots_remaining_in_trigger > 0) and ammo_in_mag > 0 and fire_timer <= 0.0:
		_shoot_once()
		fire_timer += WeaponData.get_fire_interval(current_weapon_id)
		if shots_remaining_in_trigger > 0:
			shots_remaining_in_trigger -= 1
	elif ammo_in_mag <= 0:
		auto_hold = false
		shots_remaining_in_trigger = 0


func _shoot_once() -> void:
	ammo_in_mag -= 1
	_apply_recoil(shot_index)
	_do_hit_raycast()
	_play_chamber_animation()
	shot_index += 1
	shot_fired.emit()
	ammo_changed.emit(ammo_in_mag, WeaponData.get_weapon(current_weapon_id)["magazine"])


func _apply_recoil(i: int) -> void:
	var r := WeaponData.get_shot_recoil(current_weapon_id, i)
	var mult := _stance_recoil_multiplier()
	if is_shoulder:
		mult *= SHOULDER_RECOIL_MULT
	head.rotate_x(deg_to_rad(r.x * mult))
	head.rotation.x = clamp(head.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)
	rotate_y(deg_to_rad(-r.y * mult))


func _do_hit_raycast() -> void:
	var space_state := get_world_3d().direct_space_state
	var origin := camera.global_transform.origin
	var forward_base := -camera.global_transform.basis.z

	var w := WeaponData.get_weapon(current_weapon_id)
	var is_shotgun: bool = (w["category"] == "SHOTGUN")
	var pellet_count := 9 if is_shotgun else 1
	var base_spread := deg_to_rad(_current_spread_deg())
	var shotgun_pellet_spread := deg_to_rad(2.0) # cone of fire for shotgun pellets

	for pellet in range(pellet_count):
		var forward := forward_base
		var spread_rad := base_spread
		if is_shotgun:
			# Even when ADS/zoomed (base_spread = 0), shotgun pellets spread in a cone
			spread_rad = base_spread + shotgun_pellet_spread
		
		if spread_rad > 0.0:
			var rand_yaw := (randf() * 2.0 - 1.0) * spread_rad
			var rand_pitch := (randf() * 2.0 - 1.0) * spread_rad
			forward = (camera.global_transform.basis * Vector3(rand_yaw, rand_pitch, -1.0)).normalized()

		var to := origin + forward * 400.0
		var query := PhysicsRayQueryParameters3D.create(origin, to)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.collision_mask = 1 | 4  # 환경/벽(1) + 표적·AI 히트박스(4). AI 물리바디(16)는 제외해 판정이 항상 히트박스로 가도록 함
		var result := space_state.intersect_ray(query)
		if result and result.has("collider") and result["collider"] and result["collider"].has_method("take_hit"):
			var dmg: int = w["damage"]
			var is_kill: bool = result["collider"].take_hit(dmg, result["position"])
			hit_registered.emit(is_kill)


func _create_box_part(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	inst.material_override = mat
	inst.position = pos
	parent.add_child(inst)
	return inst


func _update_gun_visual(category: String) -> void:
	if not gun_holder:
		return
	
	# Clear previous parts
	for child in gun_holder.get_children():
		child.queue_free()
		gun_holder.remove_child(child)
	
	var dark_metal := Color(0.15, 0.15, 0.16)
	var wood_brown := Color(0.4, 0.25, 0.15)
	var olive_green := Color(0.22, 0.28, 0.2)
	var steel_grey := Color(0.3, 0.32, 0.35)
	var bright_accent := Color(0.7, 0.5, 0.2)
	
	match category:
		"PISTOL":
			# Body
			_create_box_part(gun_holder, Vector3(0.03, 0.05, 0.18), Vector3(0, 0, 0), steel_grey)
			# Slide
			_create_box_part(gun_holder, Vector3(0.03, 0.02, 0.17), Vector3(0, 0.035, -0.005), dark_metal)
			# Grip
			_create_box_part(gun_holder, Vector3(0.028, 0.08, 0.035), Vector3(0, -0.05, 0.04), dark_metal)
			
		"SMG":
			# Body
			_create_box_part(gun_holder, Vector3(0.04, 0.07, 0.3), Vector3(0, 0, 0), steel_grey)
			# Barrel
			_create_box_part(gun_holder, Vector3(0.02, 0.02, 0.12), Vector3(0, 0.01, -0.21), dark_metal)
			# Grip
			_create_box_part(gun_holder, Vector3(0.035, 0.1, 0.04), Vector3(0, -0.07, 0.06), dark_metal)
			# Magazine
			_create_box_part(gun_holder, Vector3(0.025, 0.15, 0.03), Vector3(0, -0.1, -0.05), dark_metal)
			# Stock
			_create_box_part(gun_holder, Vector3(0.03, 0.03, 0.18), Vector3(0, 0.02, 0.24), dark_metal)
			
		"AR":
			# Body
			_create_box_part(gun_holder, Vector3(0.045, 0.08, 0.45), Vector3(0, 0, 0), steel_grey)
			# Handguard
			_create_box_part(gun_holder, Vector3(0.05, 0.06, 0.2), Vector3(0, -0.01, -0.18), dark_metal)
			# Barrel
			_create_box_part(gun_holder, Vector3(0.02, 0.02, 0.25), Vector3(0, 0.01, -0.405), dark_metal)
			# Grip
			_create_box_part(gun_holder, Vector3(0.035, 0.11, 0.045), Vector3(0, -0.08, 0.08), dark_metal)
			# Curved Magazine
			_create_box_part(gun_holder, Vector3(0.03, 0.18, 0.06), Vector3(0, -0.11, -0.06), bright_accent)
			# Stock
			_create_box_part(gun_holder, Vector3(0.04, 0.07, 0.2), Vector3(0, 0.01, 0.325), olive_green)
			# Iron sights
			_create_box_part(gun_holder, Vector3(0.01, 0.03, 0.02), Vector3(0, 0.055, -0.2), dark_metal)
			
		"DMR":
			# Body
			_create_box_part(gun_holder, Vector3(0.048, 0.09, 0.55), Vector3(0, 0, 0), olive_green)
			# Barrel
			_create_box_part(gun_holder, Vector3(0.022, 0.022, 0.38), Vector3(0, 0.01, -0.465), dark_metal)
			# Scope Base
			_create_box_part(gun_holder, Vector3(0.02, 0.03, 0.1), Vector3(0, 0.06, -0.05), steel_grey)
			# Scope Tube
			_create_box_part(gun_holder, Vector3(0.035, 0.035, 0.22), Vector3(0, 0.085, -0.05), dark_metal)
			# Grip
			_create_box_part(gun_holder, Vector3(0.035, 0.11, 0.045), Vector3(0, -0.08, 0.1), dark_metal)
			# Mag
			_create_box_part(gun_holder, Vector3(0.032, 0.13, 0.07), Vector3(0, -0.09, -0.08), steel_grey)
			# Stock
			_create_box_part(gun_holder, Vector3(0.04, 0.07, 0.24), Vector3(0, 0.01, 0.395), dark_metal)
			
		"SR":
			# Body
			_create_box_part(gun_holder, Vector3(0.05, 0.09, 0.65), Vector3(0, 0, 0), wood_brown)
			# Long Barrel
			_create_box_part(gun_holder, Vector3(0.02, 0.02, 0.5), Vector3(0, 0.01, -0.575), dark_metal)
			# Scope Mounts
			_create_box_part(gun_holder, Vector3(0.02, 0.04, 0.12), Vector3(0, 0.065, -0.05), dark_metal)
			# Large Scope
			_create_box_part(gun_holder, Vector3(0.045, 0.045, 0.3), Vector3(0, 0.095, -0.05), dark_metal)
			# Stock
			_create_box_part(gun_holder, Vector3(0.045, 0.08, 0.28), Vector3(0, -0.01, 0.465), wood_brown)
			# Bolt Handle
			_create_box_part(gun_holder, Vector3(0.06, 0.02, 0.02), Vector3(0.05, 0.02, 0.1), steel_grey)
			
		"LMG":
			# Bulky Body
			_create_box_part(gun_holder, Vector3(0.07, 0.12, 0.55), Vector3(0, 0, 0), dark_metal)
			# Heavy Barrel
			_create_box_part(gun_holder, Vector3(0.03, 0.03, 0.35), Vector3(0, 0.02, -0.45), steel_grey)
			# Large Ammo Box
			_create_box_part(gun_holder, Vector3(0.07, 0.11, 0.11), Vector3(-0.06, -0.08, -0.05), olive_green)
			# Carrying Handle
			_create_box_part(gun_holder, Vector3(0.02, 0.06, 0.15), Vector3(0, 0.09, -0.05), steel_grey)
			# Stock
			_create_box_part(gun_holder, Vector3(0.05, 0.08, 0.22), Vector3(0, -0.01, 0.385), steel_grey)
			
		"SHOTGUN":
			# Body
			_create_box_part(gun_holder, Vector3(0.055, 0.08, 0.4), Vector3(0, 0, 0), wood_brown)
			# Double Barrel
			_create_box_part(gun_holder, Vector3(0.045, 0.025, 0.35), Vector3(0, 0.02, -0.375), dark_metal)
			# Stock
			_create_box_part(gun_holder, Vector3(0.048, 0.08, 0.25), Vector3(0, -0.02, 0.325), wood_brown)


func _play_chamber_animation() -> void:
	if not gun_holder:
		return
	if chamber_tween:
		chamber_tween.kill()
	
	var base_pos := Vector3(0.28, -0.28, -0.6)
	if is_ads:
		base_pos = Vector3(0.0, -0.18, -0.45)
	elif is_shoulder:
		base_pos = Vector3(0.2, -0.22, -0.5)

	var w_id := current_weapon_id
	if w_id == "s1897":
		chamber_tween = create_tween()
		# 1. Recoil kick
		var kick_pos := base_pos + Vector3(0.0, 0.04, 0.06)
		var kick_rot := Vector3(deg_to_rad(12), 0, 0)
		chamber_tween.tween_property(gun_holder, "position", kick_pos, 0.08)
		chamber_tween.parallel().tween_property(gun_holder, "rotation", kick_rot, 0.08)
		
		# 2. Pump back (bolt slide back / clack sound timing)
		var pump_pos := base_pos + Vector3(-0.02, -0.04, 0.02)
		var pump_rot := Vector3(deg_to_rad(-4), deg_to_rad(-6), deg_to_rad(-8))
		chamber_tween.tween_property(gun_holder, "position", pump_pos, 0.18)
		chamber_tween.parallel().tween_property(gun_holder, "rotation", pump_rot, 0.18)
		
		# 3. Pump forward
		chamber_tween.tween_property(gun_holder, "position", base_pos, 0.18)
		chamber_tween.parallel().tween_property(gun_holder, "rotation", Vector3.ZERO, 0.18)

	elif w_id in ["kar98k", "m24", "awm"]:
		chamber_tween = create_tween()
		# 1. Recoil kick
		var kick_pos := base_pos + Vector3(0.0, 0.05, 0.08)
		var kick_rot := Vector3(deg_to_rad(15), 0, 0)
		chamber_tween.tween_property(gun_holder, "position", kick_pos, 0.1)
		chamber_tween.parallel().tween_property(gun_holder, "rotation", kick_rot, 0.1)
		
		# 2. Bolt pull back (rotate and move)
		var bolt_pos := base_pos + Vector3(0.02, -0.08, 0.04)
		var bolt_rot := Vector3(deg_to_rad(-8), deg_to_rad(10), deg_to_rad(5))
		chamber_tween.tween_property(gun_holder, "position", bolt_pos, 0.3)
		chamber_tween.parallel().tween_property(gun_holder, "rotation", bolt_rot, 0.3)
		
		# 3. Bolt push forward & lock
		chamber_tween.tween_property(gun_holder, "position", base_pos, 0.3)
		chamber_tween.parallel().tween_property(gun_holder, "rotation", Vector3.ZERO, 0.3)
