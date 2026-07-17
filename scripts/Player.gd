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

enum Stance { STAND, CROUCH, PRONE }

const SPEED_STAND := 5.0
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

var current_weapon_id: String = ""
var ammo_in_mag: int = 0
var fire_mode_index: int = 0
var shot_index: int = 0
var fire_timer: float = 0.0
var auto_hold: bool = false
var shots_remaining_in_trigger: int = 0

var mouse_captured: bool = true
var is_ads: bool = false
var is_shoulder: bool = false
var ads_tween: Tween


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

	set_weapon(WeaponData.DEFAULT_WEAPON)
	_apply_stance_visuals()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func set_sensitivity(v: float) -> void:
	sensitivity = v


func set_weapon(id: String) -> void:
	if not WeaponData.WEAPONS.has(id):
		return
	current_weapon_id = id
	var w := WeaponData.get_weapon(id)
	ammo_in_mag = w["magazine"]
	fire_mode_index = w["fire_modes"].size() - 1
	shot_index = 0
	auto_hold = false
	shots_remaining_in_trigger = 0
	_set_ads(false)
	_set_shoulder(false)
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
	if ads_tween:
		ads_tween.kill()
	var target_fov := BASE_FOV
	if is_ads:
		target_fov = BASE_FOV * WeaponData.get_ads_fov_mult(current_weapon_id)
	elif is_shoulder:
		target_fov = BASE_FOV * SHOULDER_FOV_MULT
	ads_tween = create_tween()
	ads_tween.tween_property(camera, "fov", target_fov, ADS_TWEEN_TIME)


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
	var w := WeaponData.get_weapon(current_weapon_id)
	ammo_in_mag = w["magazine"]
	shot_index = 0
	ammo_changed.emit(ammo_in_mag, w["magazine"])


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
	var base := WeaponData.get_base_spread(current_weapon_id)
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var speed_ratio: float = clamp(horizontal_speed / SPEED_STAND, 0.0, 1.3)
	var move_mult := 1.0 + speed_ratio * 2.2
	var stance_mult := _stance_spread_multiplier()
	var aim_mult := 1.0
	if is_ads:
		aim_mult = 0.3
	elif is_shoulder:
		aim_mult = 0.7
	return base * move_mult * stance_mult * aim_mult


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		var sens_mult := _current_sens_mult()
		rotate_y(-event.relative.x * MOUSE_SENS_BASE * sensitivity * sens_mult)
		head.rotate_x(-event.relative.y * MOUSE_SENS_BASE * sensitivity * sens_mult)
		head.rotation.x = clamp(head.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)

	if event.is_action_pressed("ads") and mouse_captured:
		_set_ads(true)
	if event.is_action_released("ads"):
		_set_ads(false)
	if event.is_action_pressed("shoulder") and mouse_captured:
		_set_shoulder(true)
	if event.is_action_released("shoulder"):
		_set_shoulder(false)

	if event.is_action_pressed("fire") and mouse_captured:
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
	if not value and is_ads:
		_set_ads(false)
	if not value and is_shoulder:
		_set_shoulder(false)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	var speed := SPEED_STAND
	if stance == Stance.CROUCH:
		speed = SPEED_CROUCH
	elif stance == Stance.PRONE:
		speed = SPEED_PRONE

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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
	var forward := -camera.global_transform.basis.z

	var spread_rad := deg_to_rad(_current_spread_deg())
	if spread_rad > 0.0:
		var rand_yaw := (randf() * 2.0 - 1.0) * spread_rad
		var rand_pitch := (randf() * 2.0 - 1.0) * spread_rad
		forward = (camera.global_transform.basis * Vector3(rand_yaw, rand_pitch, -1.0)).normalized()

	var to := origin + forward * 400.0
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := space_state.intersect_ray(query)
	if result and result.has("collider") and result["collider"] and result["collider"].has_method("take_hit"):
		var dmg: int = WeaponData.get_weapon(current_weapon_id)["damage"]
		var is_kill: bool = result["collider"].take_hit(dmg, result["position"])
		hit_registered.emit(is_kill)
