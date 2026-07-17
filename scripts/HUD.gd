extends Control
## 크로스헤어, 무기명, 탄약, 자세, 명중 통계를 표시하는 HUD

var player: Node = null

var weapon_name_label: Label
var weapon_sub_label: Label
var stance_label: Label
var ads_label: Label
var shoulder_label: Label
var stats_label: Label
var hint_label: Label

var shots := 0
var hits := 0
var kills := 0

var hit_flash_t := 0.0
const HIT_FLASH_DURATION := 0.15


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	weapon_name_label = _make_label(40, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_place(weapon_name_label, Control.PRESET_BOTTOM_LEFT, 24, -108, 524, -58)
	add_child(weapon_name_label)

	weapon_sub_label = _make_label(20, Color(0.85, 0.85, 0.85), HORIZONTAL_ALIGNMENT_LEFT)
	_place(weapon_sub_label, Control.PRESET_BOTTOM_LEFT, 24, -62, 524, -22)
	add_child(weapon_sub_label)

	stance_label = _make_label(20, Color(0.9, 0.9, 0.6), HORIZONTAL_ALIGNMENT_LEFT)
	_place(stance_label, Control.PRESET_TOP_LEFT, 24, 24, 224, 54)
	stance_label.text = "서기"
	add_child(stance_label)

	ads_label = _make_label(18, Color(1.0, 0.5, 0.35), HORIZONTAL_ALIGNMENT_LEFT)
	_place(ads_label, Control.PRESET_TOP_LEFT, 24, 56, 224, 82)
	ads_label.text = ""
	add_child(ads_label)

	shoulder_label = _make_label(18, Color(0.5, 0.85, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_place(shoulder_label, Control.PRESET_TOP_LEFT, 24, 84, 224, 110)
	shoulder_label.text = ""
	add_child(shoulder_label)

	stats_label = _make_label(18, Color(0.9, 0.9, 0.9), HORIZONTAL_ALIGNMENT_RIGHT)
	_place(stats_label, Control.PRESET_TOP_RIGHT, -320, 24, -20, 104)
	add_child(stats_label)

	hint_label = _make_label(15, Color(0.85, 0.85, 0.85, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	_place(hint_label, Control.PRESET_TOP_WIDE, 0, 24, 0, 48)
	hint_label.text = "Tab 무기선택 | P 설정 | R 재장전 | B 발사모드 | 우클릭 줌(ADS) | 마우스4 견착 | C 앉기 | Z 엎드리기 | Esc 마우스해제"
	add_child(hint_label)

	if player:
		player.weapon_changed.connect(_on_weapon_changed)
		player.ammo_changed.connect(_on_ammo_changed)
		player.stance_changed.connect(_on_stance_changed)
		player.fire_mode_changed.connect(_on_fire_mode_changed)
		player.hit_registered.connect(_on_hit_registered)
		player.shot_fired.connect(_on_shot_fired)
		player.ads_changed.connect(_on_ads_changed)
		player.shoulder_changed.connect(_on_shoulder_changed)
		_on_weapon_changed(player.current_weapon_id)

	_update_stats()


func _place(ctrl: Control, preset: Control.LayoutPreset, off_left: float, off_top: float, off_right: float, off_bottom: float) -> void:
	ctrl.set_anchors_preset(preset)
	ctrl.offset_left = off_left
	ctrl.offset_top = off_top
	ctrl.offset_right = off_right
	ctrl.offset_bottom = off_bottom


func _make_label(font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = align
	return l


func _on_weapon_changed(id: String) -> void:
	var w := WeaponData.get_weapon(id)
	weapon_name_label.text = w["name"]
	_refresh_sub_label()


func _on_ammo_changed(_current: int, _magazine: int) -> void:
	_refresh_sub_label()


func _on_fire_mode_changed(_mode: String) -> void:
	_refresh_sub_label()


func _refresh_sub_label() -> void:
	if not player:
		return
	var w := WeaponData.get_weapon(player.current_weapon_id)
	var mode_kr: String = {"single": "단발", "burst": "점사", "auto": "연사"}.get(player.get_current_fire_mode(), "")
	weapon_sub_label.text = "%d / %d   ·   %s   ·   DMG %d   RPM %d" % [
		player.ammo_in_mag, w["magazine"], mode_kr, w["damage"], w["rpm"]
	]


func _on_stance_changed(label: String) -> void:
	stance_label.text = label


func _on_ads_changed(active: bool) -> void:
	ads_label.text = "조준 중" if active else ""


func _on_shoulder_changed(active: bool) -> void:
	shoulder_label.text = "견착 중" if active else ""


func _on_shot_fired() -> void:
	shots += 1
	_update_stats()


func _on_hit_registered(is_kill: bool) -> void:
	hits += 1
	if is_kill:
		kills += 1
	hit_flash_t = HIT_FLASH_DURATION
	_update_stats()


func _update_stats() -> void:
	var acc := 0.0
	if shots > 0:
		acc = float(hits) / float(shots) * 100.0
	stats_label.text = "명중 %d   /   사격 %d   (%.1f%%)\n킬 %d" % [hits, shots, acc, kills]


func _process(delta: float) -> void:
	if hit_flash_t > 0.0:
		hit_flash_t -= delta
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var gap := 7.0
	var arm_len := 11.0
	var thickness := 2.0
	var color := Color(1, 1, 1, 0.9)
	if hit_flash_t > 0.0:
		color = Color(1, 0.25, 0.15, 1.0)

	draw_line(center + Vector2(0, -gap - arm_len), center + Vector2(0, -gap), color, thickness)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + arm_len), color, thickness)
	draw_line(center + Vector2(-gap - arm_len, 0), center + Vector2(-gap, 0), color, thickness)
	draw_line(center + Vector2(gap, 0), center + Vector2(gap + arm_len, 0), color, thickness)
	draw_circle(center, 1.5, color)
