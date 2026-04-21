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
		"You reacted before you reflected. Every headline sent you to the confirm button before your data panel. Under real market conditions this pattern costs investors 2-4% per crash cycle. That is the Expedient pathway — perception collapsed directly into decision.",
	"ANALYTICAL":
		"You ignored the noise and read the numbers. Your decisions lagged the headline but led the data — the hallmark of the Analytical pathway. In the 2026 Iran crisis traders who held Energy and Defense outperformed the market by over 40%.",
	"VALUE_DRIVEN":
		"You had a rule and you stuck to it. Same ETF, same conviction, cycle after cycle. The Value-Driven pathway is consistent under chaos — perception leads to information, judgment confirms the thesis, and decision executes it every time.",
	"REVISIONIST":
		"You checked the data before the headline settled. Where others read crisis, you read signal — then let the data reshape what the headline meant. Information reframes perception before every decision. That is the Methodical — Revisionist pathway.",
}

var PATHWAY_SIGNATURES: Dictionary = {
	"EXPEDIENT":    "P -> D",
	"ANALYTICAL":   "I -> J -> D",
	"VALUE_DRIVEN": "P -> I -> J -> D",
	"REVISIONIST":  "I -> P -> D",
}

var PATHWAY_ORDER: Array[String] = [
	"EXPEDIENT",
	"ANALYTICAL",
	"VALUE_DRIVEN",
	"REVISIONIST",
]

var PATHWAY_COLORS: Dictionary = {
	"EXPEDIENT":    Color(1.0, 0.267, 0.267),
	"ANALYTICAL":   Color(0.267, 0.6,  1.0),
	"VALUE_DRIVEN": Color(1.0, 0.843, 0.0),
	"REVISIONIST":  Color(0.0, 1.0,   0.314),
}

var _pnl_lbl: Label = null
var _pnl_pulse_t: float = 0.0
var _pnl_base_color: Color = Color.WHITE

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
	_diff_lbl.add_theme_color_override("font_color", Color.WHITE)
	_interp_lbl.text = INTERPRETATIONS.get(dominant, "")

	_delta_lbl.hide()

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
		bar.value = amplitude if is_dominant else 0.0
		bar.custom_minimum_size = Vector2(140, 14)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		if is_dominant and PATHWAY_COLORS.has(pathway):
			var fill_style: StyleBoxFlat = StyleBoxFlat.new()
			fill_style.bg_color = PATHWAY_COLORS[pathway]
			bar.add_theme_stylebox_override("fill", fill_style)

		row.add_child(name_lbl)
		row.add_child(bar)
		_breakdown.add_child(row)

	var sep: ColorRect = ColorRect.new()
	sep.color = Color(1, 1, 1, 0.12)
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_breakdown.add_child(sep)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 72)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_breakdown.add_child(spacer)

	var final_value: float = SimulationManager.get_portfolio_value()
	var pnl: float = final_value - SimulationManager.starting_cash
	var pct: float = (pnl / SimulationManager.starting_cash) * 100.0
	var is_gain: bool = pnl >= 0.0
	var sign: String = "+" if is_gain else "-"
	var arrow: String = "▲" if is_gain else "▼"
	_pnl_base_color = Color("00c805") if is_gain else Color("ff3b30")

	var tag_lbl: Label = Label.new()
	tag_lbl.text = "PROFIT" if is_gain else "LOSS"
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_lbl.add_theme_font_size_override("font_size", 16)
	tag_lbl.add_theme_color_override("font_color", Color(_pnl_base_color.r, _pnl_base_color.g, _pnl_base_color.b, 0.65))
	_breakdown.add_child(tag_lbl)

	_pnl_lbl = Label.new()
	_pnl_lbl.text = "%s  %s$%s" % [arrow, sign, "%.2f" % absf(pnl)]
	_pnl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pnl_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pnl_lbl.add_theme_font_size_override("font_size", 48)
	_pnl_lbl.add_theme_color_override("font_color", _pnl_base_color)
	_breakdown.add_child(_pnl_lbl)
	_pnl_pulse_t = 0.0

	var pct_lbl: Label = Label.new()
	pct_lbl.text = "%s%.1f%%" % [sign, absf(pct)]
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pct_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pct_lbl.add_theme_font_size_override("font_size", 28)
	pct_lbl.add_theme_color_override("font_color", Color(_pnl_base_color.r, _pnl_base_color.g, _pnl_base_color.b, 0.65))
	_breakdown.add_child(pct_lbl)

func _process(delta: float) -> void:
	if is_instance_valid(_pnl_lbl):
		_pnl_pulse_t += delta * 2.5
		var a: float = 0.55 + 0.45 * sin(_pnl_pulse_t)
		_pnl_lbl.modulate = Color(1.0, 1.0, 1.0, a)

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
