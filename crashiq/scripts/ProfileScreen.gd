extends Control

@onready var _radar: RadarChartControl = %RadarChartNode
@onready var _pl: PLChartControl = %PLChartNode
@onready var _archetype_lbl: Label = %ArchetypeLabel
@onready var _pathway_lbl: Label = %PathwaySignatureLabel
@onready var _diff_lbl: Label = %DifficultyLabel
@onready var _interp_lbl: Label = %InterpLabel
@onready var _delta_lbl: Label = %DeltaLabel
@onready var _breakdown: VBoxContainer = %PathwayBreakdown
@onready var _play_again: Button = %PlayAgainButton

var INTERPRETATIONS: Dictionary = {
	"EXPEDIENT":
		"You reacted before you reflected. Every headline sent you to the confirm button before your data panel. Under real market conditions this pattern costs investors 2-4% per crash cycle. That is the Expedient pathway - perception collapsed directly into decision.",
	"ANALYTICAL":
		"You ignored the noise and read the numbers. Your decisions lagged the headline but led the data - the hallmark of the Analytical pathway. In the 2026 Iran crisis traders who held Energy and Defense outperformed the market by over 40%.",
	"VALUE_DRIVEN":
		"You had a rule and you stuck to it. Regardless of what the data showed your strategy was consistent cycle over cycle. The Value-Driven pathway is rigid under chaos - sometimes right, sometimes costly.",
	"RULING_GUIDE":
		"You worked every stage before committing. Headline, data, judgment, decision - in order, every time. The Ruling Guide pathway is the most deliberate. Under a 10-second timer it is nearly impossible. You did it.",
	"REVISIONIST":
		"You checked the data before the headline settled. Where others read crisis, you read signal — then let the data reshape what the headline meant. You bought into the crash and read the macro correctly twice. The third call was wrong. That is the Revisionist pathway — information reframes perception before every decision.",
	"GLOBAL":
		"You thought in systems. Every trade accounted for the macro picture - not just one ETF but how the whole portfolio responded to the crisis arc. The Global pathway is rare under time pressure. You demonstrated it."
}

var PATHWAY_SIGNATURES: Dictionary = {
	"EXPEDIENT": "P -> D",
	"ANALYTICAL": "I -> J -> D",
	"VALUE_DRIVEN": "P -> J -> D",
	"RULING_GUIDE": "P -> I -> J -> D",
	"REVISIONIST": "I -> P -> D",
	"GLOBAL": "I -> P -> J -> D"
}

var PATHWAY_ORDER: Array[String] = [
	"EXPEDIENT",
	"ANALYTICAL",
	"VALUE_DRIVEN",
	"RULING_GUIDE",
	"REVISIONIST",
	"GLOBAL"
]

func _ready() -> void:
	_add_debug_label()
	var amplitudes: Dictionary = BehaviorTracker.get_final_amplitudes()
	var dominant: String = BehaviorTracker.get_dominant_pathway()
	var learning_delta: float = BehaviorTracker.get_learning_delta()
	var history: Array = SimulationManager.cycle_history
	var starting_cash: float = SimulationManager.starting_cash
	var difficulty: String = SimulationManager.selected_difficulty

	_radar.set_amplitudes(amplitudes)
	_radar.set_dominant(dominant)
	_pl.set_data(history, starting_cash)

	_archetype_lbl.text = dominant.replace("_", " ")
	_pathway_lbl.text = PATHWAY_SIGNATURES.get(dominant, "")
	_diff_lbl.text = "Difficulty: %s  |  Starting cash: $%.0f" % [difficulty, starting_cash]
	_interp_lbl.text = INTERPRETATIONS.get(dominant, "")

	var sign_str: String = "+" if learning_delta >= 0.0 else ""
	_delta_lbl.text = "Learning delta %s%.3f (non-expedient amplitude shift across 5 cycles)" % [sign_str, learning_delta]
	_delta_lbl.add_theme_color_override(
		"font_color",
		Color("00c805") if learning_delta >= 0.0 else Color("ff3b30")
	)

	_build_breakdown(amplitudes, dominant)
	_play_again.pressed.connect(_on_play_again)

func _build_breakdown(amplitudes: Dictionary, dominant: String) -> void:
	for child in _breakdown.get_children():
		child.queue_free()

	for pathway in PATHWAY_ORDER:
		var amplitude: float = amplitudes.get(pathway, 0.0)
		var is_dominant: bool = pathway == dominant

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var name_lbl: Label = Label.new()
		name_lbl.text = "%-14s  %s" % [pathway.replace("_", " "), PATHWAY_SIGNATURES.get(pathway, "")]
		name_lbl.custom_minimum_size = Vector2(220, 0)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override(
			"font_color",
			Color(1, 1, 1, 0.9) if is_dominant else Color(1, 1, 1, 0.4)
		)

		var bar: ProgressBar = ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = 1.0
		bar.value = amplitude
		bar.custom_minimum_size = Vector2(140, 14)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false

		row.add_child(name_lbl)
		row.add_child(bar)
		_breakdown.add_child(row)

func _on_play_again() -> void:
	SimulationManager.reset()
	BehaviorTracker.reset()
	var target_scene: String = "res://scenes/StartScreen.tscn"
	print("TRANSITIONING TO:", target_scene)
	get_tree().change_scene_to_file(target_scene)

func _on_profile_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/MotivationCutscene.tscn")

func _add_debug_label():
	var label = Label.new()
	label.name = "TopRightDebugLabel"
	label.text = "ProfileScreen.tscn | ProfileScreen.gd"
	label.anchor_left = 1
	label.anchor_right = 1
	label.offset_left = -400
	label.offset_right = -10
	label.offset_top = 10
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0, 1, 0))
	add_child(label)
