extends Control

@onready var _title_label: Label = $OuterMargin/MainColumn/TitleLabel
@onready var _sub_label: Label = $OuterMargin/MainColumn/SubLabel
@onready var _card_row: HBoxContainer = %CardRow
@onready var _press_label: Label = %PressLabel

var can_advance: bool = false
var has_advanced: bool = false
var debug_label: Label
var _press_blink_on: bool = false
var input_locked: bool = true

func _ready() -> void:
	_add_debug_label()
	var current_scene_path: String = ""
	var scene: Node = get_tree().current_scene
	if scene:
		current_scene_path = scene.scene_file_path
	var script_file_path: String = ""
	var script: Script = get_script()
	if script:
		script_file_path = script.resource_path
	print("CURRENT SCENE:", current_scene_path)
	if debug_label:
		debug_label.text = "SCENE: " + current_scene_path.get_file() + "\nSCRIPT: " + script_file_path.get_file()

	_title_label.visible = true
	_title_label.modulate.a = 1.0
	_sub_label.visible = true
	_sub_label.modulate.a = 1.0
	_press_label.visible = true
	_press_label.modulate.a = 1.0
	_start_press_blink()

	_build_etf_cards()
	await get_tree().create_timer(0.6).timeout
	input_locked = false
	can_advance = true
	has_advanced = false

func _build_etf_cards() -> void:
	for child in _card_row.get_children():
		child.queue_free()

	for item in SimulationManager.get_market_intro_data():
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(220, 250)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.visible = true
		card.modulate = Color(1, 1, 1, 1)

		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_bottom", 14)
		card.add_child(margin)

		var column: VBoxContainer = VBoxContainer.new()
		column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 14)
		margin.add_child(column)

		var ticker_label: Label = Label.new()
		ticker_label.text = String(item.get("ticker", ""))
		ticker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ticker_label.add_theme_font_size_override("font_size", 24)
		ticker_label.add_theme_color_override("font_color", Color("ffd700"))
		column.add_child(ticker_label)

		var name_label: Label = Label.new()
		name_label.text = String(item.get("name", ""))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90, 1.0))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(name_label)

		var price_label: Label = Label.new()
		price_label.text = String(item.get("price", ""))
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 20)
		price_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.25, 1.0))
		column.add_child(price_label)

		var price_spacer: Control = Control.new()
		price_spacer.custom_minimum_size = Vector2(0, 10)
		column.add_child(price_spacer)

		var sections: Dictionary = _parse_behavior_sections(String(item.get("behavior", "")))
		var primary_block: VBoxContainer = VBoxContainer.new()
		primary_block.add_theme_constant_override("separation", 6)
		column.add_child(primary_block)

		var primary_header: Label = Label.new()
		primary_header.text = "PRIMARY EFFECT"
		primary_header.add_theme_font_size_override("font_size", 12)
		primary_header.add_theme_color_override("font_color", Color("ff4444"))
		primary_block.add_child(primary_header)

		var primary_body: RichTextLabel = RichTextLabel.new()
		primary_body.bbcode_enabled = true
		primary_body.fit_content = true
		primary_body.scroll_active = false
		primary_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		primary_body.add_theme_font_size_override("normal_font_size", 14)
		primary_body.add_theme_color_override("default_color", Color(1, 1, 1, 1))
		primary_body.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		primary_body.text = "[color=white]" + sections.get("primary", "") + "[/color]"
		primary_block.add_child(primary_body)

		var section_spacer: Control = Control.new()
		section_spacer.custom_minimum_size = Vector2(0, 12)
		column.add_child(section_spacer)

		var behavior_block: VBoxContainer = VBoxContainer.new()
		behavior_block.add_theme_constant_override("separation", 6)
		behavior_block.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(behavior_block)

		var behavior_header: Label = Label.new()
		behavior_header.text = "INVESTOR BEHAVIOR:"
		behavior_header.add_theme_font_size_override("font_size", 12)
		behavior_header.add_theme_color_override("font_color", Color(0.0, 1.0, 0.25, 1.0))
		behavior_header.add_theme_font_override("font", ThemeDB.fallback_font)
		behavior_block.add_child(behavior_header)

		var behavior_body: RichTextLabel = RichTextLabel.new()
		behavior_body.bbcode_enabled = true
		behavior_body.fit_content = true
		behavior_body.scroll_active = false
		behavior_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		behavior_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		behavior_body.add_theme_font_size_override("normal_font_size", 14)
		behavior_body.add_theme_color_override("default_color", Color(1, 1, 1, 1))
		behavior_body.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		behavior_body.text = "[color=white]" + sections.get("behavior", "") + "[/color]"
		behavior_block.add_child(behavior_body)

		_card_row.add_child(card)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_SPACE:
		return
	if input_locked:
		return
	if not can_advance or has_advanced:
		return
	has_advanced = true
	can_advance = false
	_press_blink_on = false
	_press_label.modulate.a = 1.0
	get_viewport().set_input_as_handled()
	var target_scene: String = "res://scenes/SimulationScreen.tscn"
	print("TRANSITIONING TO:", target_scene)
	get_tree().change_scene_to_file(target_scene)

func _start_press_blink() -> void:
	if _press_blink_on:
		return
	_press_blink_on = true
	_blink_press_label()

func _blink_press_label() -> void:
	while _press_blink_on:
		if _press_label:
			_press_label.modulate.a = 1.0 if _press_label.modulate.a < 0.5 else 0.25
		await get_tree().create_timer(0.6).timeout

func _parse_behavior_sections(raw_text: String) -> Dictionary:
	var sections: Dictionary = {
		"primary": "",
		"behavior": ""
	}
	var lines: PackedStringArray = raw_text.split("\n")
	for line in lines:
		if line.begins_with("PRIMARY EFFECT:"):
			sections["primary"] = line.trim_prefix("PRIMARY EFFECT:").strip_edges()
		elif line.begins_with("INVESTOR BEHAVIOR:"):
			sections["behavior"] = line.trim_prefix("INVESTOR BEHAVIOR:").strip_edges()
	return sections

func _add_debug_label() -> void:
	debug_label = Label.new()
	debug_label.name = "TopRightDebugLabel"
	debug_label.visible = true
	debug_label.anchor_left = 1.0
	debug_label.anchor_right = 1.0
	debug_label.anchor_top = 0.0
	debug_label.anchor_bottom = 0.0
	debug_label.offset_left = -400
	debug_label.offset_right = -10
	debug_label.offset_top = 10
	debug_label.offset_bottom = 40
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	debug_label.add_theme_font_size_override("font_size", 14)
	debug_label.add_theme_color_override("font_color", Color(0, 1, 0))
	add_child(debug_label)
