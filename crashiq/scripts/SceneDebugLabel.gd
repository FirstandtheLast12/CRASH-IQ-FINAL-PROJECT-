extends Label

@export var override_scene_name: String = ""
@export var override_script_name: String = ""

func _ready():
	var scene_name = override_scene_name
	if scene_name == "":
		var scene = get_tree().current_scene
		if scene:
			scene_name = scene.scene_file_path.get_file()
		else:
			scene_name = "UNKNOWN_SCENE"

	var script_name = override_script_name
	if script_name == "":
		var parent_script = get_parent().get_script()
		if parent_script:
			script_name = parent_script.resource_path.get_file()
		else:
			script_name = "NO_SCRIPT"

	text = scene_name + " | " + script_name

	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0

	offset_left = -400
	offset_right = -10
	offset_top = 10
	offset_bottom = 40

	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	add_theme_font_size_override("font_size", 14)
	add_theme_color_override("font_color", Color(0.8, 1, 0.8, 0.9))

	self_modulate = Color(1, 1, 1, 1)
