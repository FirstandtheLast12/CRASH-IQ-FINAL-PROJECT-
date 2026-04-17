extends Node

const SCENE_START: String = "res://scenes/StartScreen.tscn"

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	if get_tree().current_scene == self:
		print("CURRENT SCENE:", scene_file_path)
	print("TRANSITIONING TO:", SCENE_START)
	get_tree().change_scene_to_file.call_deferred(SCENE_START)
