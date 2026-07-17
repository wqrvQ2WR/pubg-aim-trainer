extends Control
## P로 여닫는 설정 패널: 표적 종류 on/off, 마우스 감도 조절

var player: Node = null
var range_manager: Node = null
var is_open := false

var sens_value_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.04, 0.88)
	_place(background, Control.PRESET_FULL_RECT, 0, 0, 0, 0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 22)
	_place(panel, Control.PRESET_CENTER, -260, -220, 260, 220)
	add_child(panel)

	var title := Label.new()
	title.text = "설정   (P: 닫기)"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var target_header := Label.new()
	target_header.text = "표적 종류"
	target_header.add_theme_font_size_override("font_size", 20)
	target_header.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	panel.add_child(target_header)

	_add_target_toggle(panel, "서있는 표적", 0)
	_add_target_toggle(panel, "앉아있는 표적", 1)
	_add_target_toggle(panel, "걷는 표적", 2)
	_add_target_toggle(panel, "뛰는 표적", 3)

	var sens_header := Label.new()
	sens_header.text = "마우스 감도"
	sens_header.add_theme_font_size_override("font_size", 20)
	sens_header.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	panel.add_child(sens_header)

	var sens_row := HBoxContainer.new()
	sens_row.add_theme_constant_override("separation", 12)
	panel.add_child(sens_row)

	var slider := HSlider.new()
	slider.min_value = 0.2
	slider.max_value = 3.0
	slider.step = 0.05
	slider.value = 1.0
	slider.custom_minimum_size = Vector2(360, 24)
	slider.value_changed.connect(_on_sensitivity_changed)
	sens_row.add_child(slider)

	sens_value_label = Label.new()
	sens_value_label.text = "1.00"
	sens_value_label.custom_minimum_size = Vector2(60, 0)
	sens_row.add_child(sens_value_label)


func _add_target_toggle(parent: VBoxContainer, label_text: String, target_type: int) -> void:
	var cb := CheckButton.new()
	cb.text = label_text
	cb.button_pressed = true
	cb.add_theme_font_size_override("font_size", 18)
	cb.toggled.connect(_on_target_toggle.bind(target_type))
	parent.add_child(cb)


func _on_target_toggle(pressed: bool, target_type: int) -> void:
	if range_manager:
		range_manager.set_type_enabled(target_type, pressed)


func _on_sensitivity_changed(value: float) -> void:
	sens_value_label.text = "%.2f" % value
	if player:
		player.set_sensitivity(value)


func _place(ctrl: Control, preset: Control.LayoutPreset, off_left: float, off_top: float, off_right: float, off_bottom: float) -> void:
	ctrl.set_anchors_preset(preset)
	ctrl.offset_left = off_left
	ctrl.offset_top = off_top
	ctrl.offset_right = off_right
	ctrl.offset_bottom = off_bottom


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("settings_menu"):
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
