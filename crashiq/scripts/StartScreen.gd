extends Control

var TICKER_HEADLINES: PackedStringArray = PackedStringArray([
	"BREAKING: US & Israel launch Operation Epic Fury — airstrikes hit Iranian command, navy, and nuclear sites",
	"BREAKING: Iran closes Strait of Hormuz — tankers under missile attack — 20% of global oil supply cut off and countig...",
	"BREAKING: China warns US to stand down — Iran strikes Saudi oil facilities — Kuwait and UAE infrastructure hit war is escalating...",
	"BREAKING: US 82nd Airborne deployed — ground invasion begins to reopen Strait of Hormuz by force the markets are tanking...",
	"BREAKING: Iran mines Persian Gulf — global recession declared — Chinese naval vessels enter conflict zone WW3 has begun",
	"Oil futures hit $180/barrel  ·  IMF warns 2.9% global GDP wipeout  ·  CIQ Defense Fund +35%  ·  CIQ Energy Fund +75%",
])

@onready var _ticker:         NewsTicker     = %NewsTicker
@onready var _title_label:    RichTextLabel  = %TitleLabel
@onready var _title_cursor:   Label          = %TitleCursor
@onready var _system_ready:   Label          = %SystemReadyLabel
@onready var _subtitle_label: Label          = %SubtitleLabel
@onready var _flicker_rect:   ColorRect      = %FlickerRect
@onready var _student_btn:    Button         = %StudentBtn
@onready var _youngpro_btn:   Button         = %YoungProBtn
@onready var _midcareer_btn:  Button         = %MidCareerBtn
@onready var _veteran_btn:    Button         = %VeteranBtn
@onready var _student_card:   PanelContainer = %StudentCard
@onready var _youngpro_card:  PanelContainer = %YoungProCard
@onready var _midcareer_card: PanelContainer = %MidCareerCard
@onready var _veteran_card:   PanelContainer = %VeteranCard

# ── Keyboard / selection state ─────────────────────────────────────────────
var _selected_index: int = 0

var TIER_NAMES: Array[String] = ["Student", "Young Pro", "Mid-career", "Veteran"]

var _cards: Array[PanelContainer] = []
var profile_cards = []
var _card_colors: Array[Color] = [
	Color(0.0, 1.0,  0.25, 1.0),   # Student  — green
	Color(0.0, 0.75, 1.0,  1.0),   # Young Pro — blue
	Color(1.0, 0.85, 0.0,  1.0),   # Mid-Career — yellow
	Color(1.0, 0.27, 0.27, 1.0),   # Veteran  — red
]
var _indicators: Array[Label] = []

# ── CRT / blink state ─────────────────────────────────────────────────────
var _cursor_timer:     float = 0.5
var _cursor_on:        bool  = true
var _sysready_timer:   float = 0.8
var _sysready_on:      bool  = true
var _flicker_cooldown: float = randf_range(3.0, 8.0)
var _flicker_active:   float = 0.0

func _ready() -> void:
	_add_debug_label()
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray([
		"Courier New", "Consolas", "Lucida Console", "Courier", "monospace"
	])
	mono.hinting = TextServer.HINTING_LIGHT
	mono.generate_mipmaps = false
	mono.multichannel_signed_distance_field = false
	var t := Theme.new()
	t.default_font = mono
	theme = t

	_ticker.set_messages(TICKER_HEADLINES)

	_title_label.bbcode_enabled = true
	_title_label.scroll_active  = false
	_title_label.clear()
	_title_label.append_text("[color=#FFD700]Crash[/color][color=#00FF41]IQ[/color]")

	_flicker_rect.color = Color(0, 0, 0, 0.0)

	# Mouse-click fallback: clicking START button directly selects that tier
	_student_btn.pressed.connect(func(): _selected_index = 0; _start_selected())
	_youngpro_btn.pressed.connect(func(): _selected_index = 1; _start_selected())
	_midcareer_btn.pressed.connect(func(): _selected_index = 2; _start_selected())
	_veteran_btn.pressed.connect(func(): _selected_index = 3; _start_selected())

	# Wait one frame so card sizes are valid for pivot calculation
	await get_tree().process_frame
	_cards = [_student_card, _youngpro_card, _midcareer_card, _veteran_card]
	for i in range(4):
		_setup_card_hover(_cards[i], [_student_btn, _youngpro_btn, _midcareer_btn, _veteran_btn][i], i)
	_create_indicators()
	setup_profile_cards()
	_update_card_selection()

# ── Keyboard input ─────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var ke := event as InputEventKey
	if not ke.pressed or ke.echo:
		return
	match ke.keycode:
		KEY_LEFT:
			_selected_index = (_selected_index - 1 + 4) % 4
			_update_card_selection()
			get_viewport().set_input_as_handled()
		KEY_RIGHT:
			_selected_index = (_selected_index + 1) % 4
			_update_card_selection()
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			_start_selected()
			get_viewport().set_input_as_handled()

# ── Card setup ─────────────────────────────────────────────────────────────
func _setup_card_hover(card: PanelContainer, btn: Button, idx: int) -> void:
	card.pivot_offset = card.size / 2.0
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Duplicate so each card's StyleBoxFlat animates independently
	var style := (card.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	var c     := _card_colors[idx]
	style.border_color = Color(c.r, c.g, c.b, 0.4)
	style.bg_color     = Color(0.0, 0.0, 0.0, 0.85)
	card.add_theme_stylebox_override("panel", style)
	# Mouse hover selects the hovered card (same model as keyboard)
	card.mouse_entered.connect(func(): _set_selected(idx))
	btn.mouse_entered.connect(func(): _set_selected(idx))

func setup_profile_cards() -> void:
	profile_cards = find_profile_cards(self)
	print("PROFILE CARDS FOUND: ", profile_cards.size())
	for card in profile_cards:
		if card is Control:
			card.mouse_filter = Control.MOUSE_FILTER_PASS
			card.mouse_entered.connect(_on_card_hover.bind(card))
			card.mouse_exited.connect(_on_card_exit.bind(card))
			card.gui_input.connect(_on_card_clicked.bind(card))

func find_profile_cards(node):
	var result = []
	for child in node.get_children():
		if "Student" in child.name or "Young" in child.name or "Mid" in child.name or "Veteran" in child.name:
			result.append(child)
		result += find_profile_cards(child)
	return result

func _on_card_hover(card) -> void:
	var tween = create_tween()
	tween.tween_property(card, "modulate", Color(1.2, 1.2, 1.2), 0.15)

func _on_card_exit(card) -> void:
	var tween = create_tween()
	tween.tween_property(card, "modulate", Color(1, 1, 1), 0.15)

func _on_card_clicked(event, card) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("CARD CLICKED: ", card.name)
		start_profile_from_card(card)

func start_profile_from_card(card) -> void:
	var card_name = String(card.name).to_lower()
	if "student" in card_name:
		start_student()
	elif "young" in card_name:
		start_young_pro()
	elif "mid" in card_name:
		start_mid_career()
	elif "veteran" in card_name:
		start_veteran()

func start_student() -> void:
	_selected_index = 0
	_update_card_selection()
	_start_selected()

func start_young_pro() -> void:
	_selected_index = 1
	_update_card_selection()
	_start_selected()

func start_mid_career() -> void:
	_selected_index = 2
	_update_card_selection()
	_start_selected()

func start_veteran() -> void:
	_selected_index = 3
	_update_card_selection()
	_start_selected()

func _create_indicators() -> void:
	for i in range(4):
		var card  := _cards[i]
		var color := _card_colors[i]
		# Structure: PanelContainer > MarginContainer > VBoxContainer
		var content_vbox := card.get_child(0).get_child(0) as VBoxContainer
		var lbl := Label.new()
		lbl.text = "► SELECTED"
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", color)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.visible = false
		content_vbox.add_child(lbl)
		content_vbox.move_child(lbl, 0)
		_indicators.append(lbl)

# ── Selection logic ────────────────────────────────────────────────────────
func _set_selected(idx: int) -> void:
	_selected_index = idx
	_update_card_selection()

func _update_card_selection() -> void:
	for i in range(4):
		var card  := _cards[i]
		var color := _card_colors[i]
		var style := card.get_theme_stylebox("panel") as StyleBoxFlat
		var tw    := create_tween().set_parallel()
		if i == _selected_index:
			tw.tween_property(style, "border_color", color, 0.15)
			tw.tween_property(style, "bg_color", Color(color.r, color.g, color.b, 0.25), 0.15)
			tw.tween_property(card,  "scale", Vector2(1.04, 1.04), 0.15)
			_indicators[i].visible = true
		else:
			tw.tween_property(style, "border_color", Color(color.r, color.g, color.b, 0.4), 0.15)
			tw.tween_property(style, "bg_color", Color(0.0, 0.0, 0.0, 0.85), 0.15)
			tw.tween_property(card,  "scale", Vector2(1.0, 1.0), 0.15)
			_indicators[i].visible = false

func _start_selected() -> void:
	var tier := TIER_NAMES[_selected_index]
	print("[StartScreen] START — tier: ", tier)
	SimulationManager.set_difficulty(tier)
	var target_scene: String = "res://scenes/MotivationCutscene.tscn"
	print("TRANSITIONING TO:", target_scene)
	get_tree().change_scene_to_file(target_scene)

# ── _process: CRT effects + blink ─────────────────────────────────────────
func _process(delta: float) -> void:
	# Subtitle pulse
	var pulse: float = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.003)
	_subtitle_label.modulate.a = pulse

	# Cursor blink (0.5 s)
	_cursor_timer -= delta
	if _cursor_timer <= 0.0:
		_cursor_timer = 0.5
		_cursor_on = !_cursor_on
		_title_cursor.modulate.a = 1.0 if _cursor_on else 0.0

	# SYSTEM READY blink (0.8 s)
	_sysready_timer -= delta
	if _sysready_timer <= 0.0:
		_sysready_timer = 0.8
		_sysready_on = !_sysready_on
		_system_ready.modulate.a = 1.0 if _sysready_on else 0.0

	# CRT screen flicker
	if _flicker_active > 0.0:
		_flicker_active -= delta
		_flicker_rect.color.a = randf_range(0.0, 0.03)
		if _flicker_active <= 0.0:
			_flicker_rect.color.a = 0.0
			_flicker_cooldown = randf_range(3.0, 8.0)
	else:
		_flicker_cooldown -= delta
		if _flicker_cooldown <= 0.0:
			_flicker_active = 0.1

func _add_debug_label():
	var label = Label.new()
	label.name = "TopRightDebugLabel"
	label.text = "StartScreen.tscn | StartScreen.gd"
	label.anchor_left = 1
	label.anchor_right = 1
	label.offset_left = -400
	label.offset_right = -10
	label.offset_top = 10
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0, 1, 0))
	add_child(label)
