extends Control

@onready var _classification_label: Label = %ClassificationLabel
@onready var _explanation_label: Label = %ExplanationLabel
@onready var _metrics_label: Label = %MetricsLabel
@onready var _decisions_list: VBoxContainer = %DecisionsList
@onready var _continue_button: Button = %ContinueButton

func _ready() -> void:
	_add_debug_label()
	_populate_results()
	_continue_button.pressed.connect(_go_to_profile)

func _populate_results() -> void:
	var classification: String = BehaviorTracker.get_tpm_classification()
	var explanation: String = BehaviorTracker.get_tpm_explanation()
	var metrics: Dictionary = BehaviorTracker.get_tpm_metrics()
	var decision_log: Array = BehaviorTracker.get_cycle_decisions()

	_classification_label.text = classification
	_explanation_label.text = explanation
	_metrics_label.text = "Risk tolerance: %s\nReaction speed: %s\nBuy / Sell / Hold: %d / %d / %d" % [
		metrics.get("risk_tolerance", "Moderate"),
		metrics.get("reaction_speed", "Measured"),
		int(metrics.get("buy_count", 0)),
		int(metrics.get("sell_count", 0)),
		int(metrics.get("hold_count", 0))
	]

	for child in _decisions_list.get_children():
		child.queue_free()

	for decision in decision_log:
		var action: String = String(decision.get("trade_action", "HOLD")).to_upper()
		var ticker: String = String(decision.get("selected_etf", decision.get("etf_traded", "")))
		var cycle_num: int = int(decision.get("cycle", 0))
		var summary: String = "Cycle %d  -  %s" % [cycle_num, action]
		if not ticker.is_empty():
			summary += "  " + ticker

		var row: Label = Label.new()
		row.text = summary
		row.add_theme_font_size_override("font_size", 16)
		row.add_theme_color_override("font_color", _get_action_color(action))
		_decisions_list.add_child(row)

func _get_action_color(action: String) -> Color:
	match action:
		"BUY":
			return Color("00ff41")
		"SELL":
			return Color("ff4444")
		_:
			return Color("ffd700")

func _go_to_profile() -> void:
	var target_scene: String = "res://scenes/ProfileScreen.tscn"
	print("TRANSITIONING TO:", target_scene)
	get_tree().change_scene_to_file(target_scene)

func _add_debug_label() -> void:
	var label: Label = Label.new()
	label.name = "TopRightDebugLabel"
	var current_scene_path: String = ""
	var scene: Node = get_tree().current_scene
	if scene:
		current_scene_path = scene.scene_file_path
	var script_file_path: String = ""
	var script: Script = get_script()
	if script:
		script_file_path = script.resource_path
	label.text = "SCENE: " + current_scene_path.get_file() + "\nSCRIPT: " + script_file_path.get_file()
	label.visible = true
	label.anchor_left = 1.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 0.0
	label.offset_left = -400
	label.offset_right = -10
	label.offset_top = 10
	label.offset_bottom = 40
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0, 1, 0))
	add_child(label)
