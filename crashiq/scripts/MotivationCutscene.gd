extends Control

var input_locked = true
var can_advance = false
var has_advanced = false
var debug_label: Label

var text_label : RichTextLabel
var continue_label : Label

var full_text := ""

var typing_speed := 0.025
var fade_visible := true
var _skip_typing := false

func _ready():
	var difficulty: String = SimulationManager.selected_difficulty
	match difficulty:
		"Young Pro":
			full_text = "[center][color=yellow][b]You have [/b][/color][color=red][b]$5,000[/b][/color][color=yellow][b] saved from your first job.[/b][/color]\n\n[color=yellow][b]The Iran war just started.[/b][/color]\n\n[color=yellow][b]Your friends are panic-selling.[/b][/color]\n\n[color=yellow][b]You see an opportunity.[/b][/color]\n\n[color=yellow][b]Four markets. Five cycles. One chance to prove your instincts.[/b][/color][/center]"
		"Mid-career":
			full_text = "[center][color=yellow][b]You have [/b][/color][color=red][b]$25,000[/b][/color][color=yellow][b] invested.[/b][/color]\n\n[color=yellow][b]A mortgage. A family.[/b][/color]\n\n[color=yellow][b]The Iran war is crashing the broad market.[/b][/color]\n\n[color=yellow][b]Every decision you make in the next few minutes will test everything you think you know about staying calm under pressure.[/b][/color][/center]"
		"Veteran":
			full_text = "[center][color=yellow][b]You traded through 2008.[/b][/color]\n\n[color=yellow][b]Through COVID.[/b][/color]\n\n[color=yellow][b]You have [/b][/color][color=red][b]$100,000[/b][/color][color=yellow][b] on the line right now.[/b][/color]\n\n[color=yellow][b]The Iran war just started. You have 10 seconds per cycle.[/b][/color]\n\n[color=yellow][b]No room for panic. No room for error. Prove it.[/b][/color][/center]"
		_:
			full_text = "[center][color=yellow][b]The US just launched airstrikes on Iran.[/b][/color]\n\n[color=yellow][b]The Strait of Hormuz is closing.[/b][/color]\n\n[color=yellow][b]You have [/b][/color][color=red][b]$500[/b][/color][color=yellow][b] in your Robinhood account and one thought:[/b][/color]\n\n[color=yellow][b]If there is going to be a war - you are going to profit from it.[/b][/color][/center]"
	_add_debug_label()
	var current_scene_path: String = ""
	var scene := get_tree().current_scene
	if scene:
		current_scene_path = scene.scene_file_path
	print("CURRENT SCENE:", current_scene_path)
	var script_file_path := ""
	var script: Script = get_script()
	if script:
		script_file_path = script.resource_path
	if debug_label:
		debug_label.text = "SCENE: " + current_scene_path.get_file() + "\nSCRIPT: " + script_file_path.get_file()

	text_label = RichTextLabel.new()
	add_child(text_label)

	text_label.bbcode_enabled = true
	text_label.text = full_text
	text_label.visible_characters = 0
	text_label.anchor_left = 0.5
	text_label.anchor_right = 0.5
	text_label.anchor_top = 0.5
	text_label.anchor_bottom = 0.5
	text_label.offset_left = -500
	text_label.offset_right = 500
	text_label.offset_top = -150
	text_label.offset_bottom = 150
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	continue_label = $ContinueLabel
	continue_label.modulate.a = 0.0

	await type_text()

	if not _skip_typing:
		start_blink()
		input_locked = false
		can_advance = true

func type_text():
	var total = text_label.get_total_character_count()

	for i in range(total):
		if _skip_typing:
			break
		text_label.visible_characters = i
		await get_tree().create_timer(typing_speed).timeout

	text_label.visible_characters = total

func start_blink():
	fade_visible = true
	blink_loop()

func blink_loop():
	while true:
		if fade_visible:
			continue_label.modulate.a = 1.0
		else:
			continue_label.modulate.a = 0.0

		fade_visible = !fade_visible
		await get_tree().create_timer(0.7).timeout

func _input(event):
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_SPACE:
		return
	if input_locked:
		if has_advanced:
			return
		_skip_typing = true
		text_label.visible_characters = text_label.get_total_character_count()
		input_locked = false
		if not can_advance:
			start_blink()
			can_advance = true
		return
	if not can_advance or has_advanced:
		return
	has_advanced = true
	can_advance = false
	var target_scene: String = "res://scenes/MarketIntroCutscene.tscn"
	print("TRANSITIONING TO:", target_scene)
	get_viewport().set_input_as_handled()
	get_tree().change_scene_to_file(target_scene)

func _add_debug_label():
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
	debug_label.add_theme_color_override("font_color", Color(0,1,0))
	add_child(debug_label)
