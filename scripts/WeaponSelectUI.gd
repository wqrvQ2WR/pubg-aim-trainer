extends Control
## Tab으로 여닫는 전체 무기 선택 패널. 카테고리별로 무기 이름을 크게 표시하고 클릭으로 즉시 선택한다.

var player: Node = null
var is_open := false

var background: ColorRect
var scroll: ScrollContainer
var content: VBoxContainer
var selected_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	background = ColorRect.new()
	background.color = Color(0.03, 0.03, 0.04, 0.88)
	_place_full(background)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var title := Label.new()
	title.text = "무기 선택   (Tab: 닫기)"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color.WHITE)
	_place(title, Control.PRESET_TOP_WIDE, 0, 20, 0, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	selected_label = Label.new()
	selected_label.add_theme_font_size_override("font_size", 18)
	selected_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	_place(selected_label, Control.PRESET_TOP_WIDE, 0, 68, 0, 96)
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(selected_label)

	scroll = ScrollContainer.new()
	_place(scroll, Control.PRESET_FULL_RECT, 40, 110, -40, -30)
	add_child(scroll)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	_build_grid()


func _place(ctrl: Control, preset: Control.LayoutPreset, off_left: float, off_top: float, off_right: float, off_bottom: float) -> void:
	ctrl.set_anchors_preset(preset)
	ctrl.offset_left = off_left
	ctrl.offset_top = off_top
	ctrl.offset_right = off_right
	ctrl.offset_bottom = off_bottom


func _place_full(ctrl: Control) -> void:
	_place(ctrl, Control.PRESET_FULL_RECT, 0, 0, 0, 0)


func _build_grid() -> void:
	for category in WeaponData.CATEGORY_ORDER:
		var ids := WeaponData.get_ids_by_category(category)
		if ids.is_empty():
			continue

		var header := Label.new()
		header.text = WeaponData.CATEGORY_NAMES[category]
		header.add_theme_font_size_override("font_size", 24)
		header.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
		content.add_child(header)

		var grid := GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		content.add_child(grid)

		for id in ids:
			var w := WeaponData.get_weapon(id)
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(210, 112)
			btn.text = ""
			btn.pressed.connect(_on_weapon_button_pressed.bind(id))
			grid.add_child(btn)

			var icon := Control.new()
			icon.set_script(load("res://scripts/WeaponIcon.gd"))
			icon.category = category
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.position = Vector2(69, 10)
			btn.add_child(icon)

			var label := Label.new()
			label.text = "%s\n%d dmg  ·  %d rpm" % [w["name"], w["damage"], WeaponData.get_effective_rpm(id)]
			label.add_theme_font_size_override("font_size", 17)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.position = Vector2(5, 54)
			label.size = Vector2(200, 50)
			btn.add_child(label)


func _on_weapon_button_pressed(id: String) -> void:
	if player:
		player.set_weapon(id)
	var w := WeaponData.get_weapon(id)
	selected_label.text = "선택됨: %s" % w["name"]
	close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_menu"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	is_open = true
	visible = true
	if player:
		player.set_mouse_captured(false)


func close() -> void:
	is_open = false
	visible = false
	if player:
		player.set_mouse_captured(true)
