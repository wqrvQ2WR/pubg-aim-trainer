extends Control
## 크로스헤어, 무기명, 탄약, 자세, 명중 통계를 표시하는 HUD

var player: Node = null
var duel_manager: Node = null

var weapon_name_label: Label
var weapon_sub_label: Label
var stance_label: Label
var ads_label: Label
var shoulder_label: Label
var stats_label: Label
var hint_label: Label
var health_bg: ColorRect
var health_fill: ColorRect
var health_label: Label
var boost_bg: ColorRect
var boost_fill: ColorRect
var item_use_label: Label
var duel_score_label: Label
var death_label: Label

const HEALTH_BAR_WIDTH := 224.0
const BOOST_BAR_WIDTH := 224.0

var shots := 0
var hits := 0
var kills := 0

var hit_flash_t := 0.0
const HIT_FLASH_DURATION := 0.15

var item_use_remaining := 0.0
var item_use_total := 0.0
var item_use_name := ""


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
	hint_label.text = "Tab 무기선택 | P 설정 | R 재장전 | B 발사모드 | 우클릭 줌(ADS) | 마우스4 견착 | C 앉기 | Z 엎드리기 | N AI 대전 | 4-6 회복 | 7-9 부스트 | Esc 마우스해제"
	add_child(hint_label)

	health_bg = ColorRect.new()
	health_bg.color = Color(0.12, 0.12, 0.12, 0.85)
	_place(health_bg, Control.PRESET_CENTER_BOTTOM, -112, -150, 112, -128)
	add_child(health_bg)

	health_fill = ColorRect.new()
	health_fill.color = Color(0.3, 0.85, 0.35, 0.95)
	_place(health_fill, Control.PRESET_CENTER_BOTTOM, -112, -150, 112, -128)
	add_child(health_fill)

	health_label = _make_label(14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_place(health_label, Control.PRESET_CENTER_BOTTOM, -112, -150, 112, -128)
	add_child(health_label)

	boost_bg = ColorRect.new()
	boost_bg.color = Color(0.12, 0.12, 0.12, 0.85)
	_place(boost_bg, Control.PRESET_CENTER_BOTTOM, -112, -174, 112, -156)
	add_child(boost_bg)

	boost_fill = ColorRect.new()
	boost_fill.color = Color(0.95, 0.8, 0.2, 0.95)
	_place(boost_fill, Control.PRESET_CENTER_BOTTOM, -112, -174, -112, -156)
	add_child(boost_fill)

	item_use_label = _make_label(20, Color(0.9, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	_place(item_use_label, Control.PRESET_CENTER_BOTTOM, -200, -210, 200, -180)
	item_use_label.text = ""
	add_child(item_use_label)

	duel_score_label = _make_label(20, Color(1.0, 0.85, 0.4), HORIZONTAL_ALIGNMENT_CENTER)
	_place(duel_score_label, Control.PRESET_TOP_WIDE, 0, 52, 0, 78)
	duel_score_label.text = ""
	add_child(duel_score_label)

	death_label = _make_label(48, Color(1.0, 0.2, 0.2), HORIZONTAL_ALIGNMENT_CENTER)
	_place(death_label, Control.PRESET_CENTER, -300, -80, 300, -20)
	death_label.text = ""
	add_child(death_label)

	_update_health_bar(player.health if player else 100, 100)

	if player:
		player.weapon_changed.connect(_on_weapon_changed)
		player.ammo_changed.connect(_on_ammo_changed)
		player.stance_changed.connect(_on_stance_changed)
		player.fire_mode_changed.connect(_on_fire_mode_changed)
		player.hit_registered.connect(_on_hit_registered)
		player.shot_fired.connect(_on_shot_fired)
		player.ads_changed.connect(_on_ads_changed)
		player.shoulder_changed.connect(_on_shoulder_changed)
		player.health_changed.connect(_update_health_bar)
		player.died.connect(_on_player_died)
		player.respawned.connect(_on_player_respawned)
		player.boost_changed.connect(_update_boost_bar)
		player.item_use_started.connect(_on_item_use_started)
		player.item_use_finished.connect(_on_item_use_ended)
		player.item_use_cancelled.connect(_on_item_use_ended)
		_on_weapon_changed(player.current_weapon_id)
		_update_boost_bar(0.0, 100.0)

	if duel_manager:
		duel_manager.score_changed.connect(_on_score_changed)
		duel_manager.mode_changed.connect(_on_duel_mode_changed)

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
		player.ammo_in_mag, w["magazine"], mode_kr, w["damage"],
		WeaponData.get_effective_rpm(player.current_weapon_id)
	]


func _on_stance_changed(label: String) -> void:
	stance_label.text = label


func _on_ads_changed(active: bool) -> void:
	ads_label.text = "조준 중" if active else ""


func _on_shoulder_changed(active: bool) -> void:
	shoulder_label.text = "견착 중" if active else ""


func _update_health_bar(current: int, max_health: int) -> void:
	var frac: float = clamp(float(current) / float(max_health), 0.0, 1.0)
	health_fill.offset_right = health_fill.offset_left + HEALTH_BAR_WIDTH * frac
	health_fill.color = Color(0.3, 0.85, 0.35, 0.95) if frac > 0.3 else Color(0.85, 0.3, 0.25, 0.95)
	health_label.text = "%d / %d" % [max(current, 0), max_health]


func _update_boost_bar(current: float, max_boost: float) -> void:
	var frac: float = clamp(current / max_boost, 0.0, 1.0)
	boost_fill.offset_right = boost_fill.offset_left + BOOST_BAR_WIDTH * frac


func _on_item_use_started(item_name: String, use_time: float) -> void:
	item_use_name = item_name
	item_use_total = use_time
	item_use_remaining = use_time
	item_use_label.text = "%s 사용 중... (%.1fs)" % [item_use_name, item_use_remaining]


func _on_item_use_ended() -> void:
	item_use_total = 0.0
	item_use_remaining = 0.0
	item_use_label.text = ""


func _on_player_died() -> void:
	death_label.text = "사망!"


func _on_player_respawned() -> void:
	death_label.text = ""


func _on_score_changed(player_kills: int, ai_kills: int) -> void:
	duel_score_label.text = "AI 대전   나 %d  :  %d AI" % [player_kills, ai_kills]


func _on_duel_mode_changed(active: bool) -> void:
	if not active:
		duel_score_label.text = ""
		death_label.text = ""


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
	if item_use_total > 0.0:
		item_use_remaining = max(item_use_remaining - delta, 0.0)
		item_use_label.text = "%s 사용 중... (%.1fs)" % [item_use_name, item_use_remaining]
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var spread_deg := 0.0
	if player:
		spread_deg = player.get_spread_deg()
	var gap := 7.0 + spread_deg * 6.0
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
