extends Control

var input_locked = true
var animation_done = false
var _continue_label: Label
var _blink_on := false
var _row_panels: Array = []

var ETF_DATA = [
	{
		"ticker": "CIQM",
		"name": "CIQ BROAD MARKET",
		"primary": "System-wide panic selling",
		"behavior": "Investors rapidly exit positions",
		"start_price": "$100.00",
		"rising": false
	},
	{
		"ticker": "CIQE",
		"name": "CIQ ENERGY FUND",
		"primary": "Oil supply disruption",
		"behavior": "Aggressive buying on oil spikes",
		"start_price": "$80.00",
		"rising": true
	},
	{
		"ticker": "CIQD",
		"name": "CIQ DEFENSE FUND",
		"primary": "Military escalation increases",
		"behavior": "Institutional inflows into defense",
		"start_price": "$90.00",
		"rising": true
	},
	{
		"ticker": "CIQS",
		"name": "CIQ SAFE HAVEN",
		"primary": "Fear dominates markets",
		"behavior": "Flight to safety assets",
		"start_price": "$70.00",
		"rising": true
	},
	{
		"ticker": "CIQG",
		"name": "CIQ SHIPPING",
		"primary": "Global trade disruption",
		"behavior": "Investors dump logistics exposure",
		"start_price": "$60.00",
		"rising": false
	}
]

func _ready():
	_add_debug_label()
	create_rows()
	await get_tree().process_frame
	animate_rows()
	await get_tree().create_timer(0.2).timeout
	input_locked = false

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if input_locked:
			return
		if not animation_done:
			skip_animation()
		_blink_on = false
		get_tree().change_scene_to_file("res://scenes/SimulationScreen.tscn")

func create_rows():
	# Full-screen black background
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "CLASSIFIED MARKET BRIEFING"
	title.add_theme_color_override("font_color", Color("ffd700"))
	title.add_theme_font_size_override("font_size", 24)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -420
	title.offset_right = 420
	title.offset_top = 34
	title.offset_bottom = 74
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "ETFs available for trading  ·  Iran War Escalation Scenario"
	subtitle.add_theme_color_override("font_color", Color(0.38, 0.38, 0.38))
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.anchor_left = 0.5
	subtitle.anchor_right = 0.5
	subtitle.offset_left = -420
	subtitle.offset_right = 420
	subtitle.offset_top = 70
	subtitle.offset_bottom = 96
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	var start_y := 106
	var card_h := 90
	var gap := 8
	var card_w := 860.0

	for i in range(ETF_DATA.size()):
		var etf: Dictionary = ETF_DATA[i]
		var y: int = start_y + i * (card_h + gap)
		var price_color: Color = Color("00ff41") if etf["rising"] else Color("ff4444")
		var arrow: String = "▲  RISING" if etf["rising"] else "▼  FALLING"

		# Outer border
		var border := ColorRect.new()
		border.color = Color("001800")
		border.anchor_left = 0.5
		border.anchor_right = 0.5
		border.offset_left = -(card_w / 2)
		border.offset_right = card_w / 2
		border.offset_top = y
		border.offset_bottom = y + card_h
		border.modulate.a = 0.0
		add_child(border)
		_row_panels.append(border)

		# Inner background
		var inner := ColorRect.new()
		inner.color = Color(0.02, 0.04, 0.02, 1.0)
		inner.anchor_right = 1.0
		inner.anchor_bottom = 1.0
		inner.offset_left = 1
		inner.offset_top = 1
		inner.offset_right = -1
		inner.offset_bottom = -1
		border.add_child(inner)

		# Left green accent bar
		var accent := ColorRect.new()
		accent.color = Color("00ff41")
		accent.anchor_bottom = 1.0
		accent.offset_right = 4
		border.add_child(accent)

		# Ticker — yellow
		var ticker_lbl := Label.new()
		ticker_lbl.text = "$" + etf["ticker"]
		ticker_lbl.add_theme_color_override("font_color", Color("ffd700"))
		ticker_lbl.add_theme_font_size_override("font_size", 22)
		ticker_lbl.offset_left = 18
		ticker_lbl.offset_top = 5
		ticker_lbl.offset_right = 200
		ticker_lbl.offset_bottom = 38
		border.add_child(ticker_lbl)

		# ETF name — matrix green
		var name_lbl := Label.new()
		name_lbl.text = etf["name"]
		name_lbl.add_theme_color_override("font_color", Color("00ff41"))
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.offset_left = 18
		name_lbl.offset_top = 36
		name_lbl.offset_right = 500
		name_lbl.offset_bottom = 56
		border.add_child(name_lbl)

		# Primary effect — off-white
		var primary_lbl := Label.new()
		primary_lbl.text = "PRIMARY:   " + etf["primary"]
		primary_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
		primary_lbl.add_theme_font_size_override("font_size", 12)
		primary_lbl.offset_left = 18
		primary_lbl.offset_top = 55
		primary_lbl.offset_right = 630
		primary_lbl.offset_bottom = 73
		border.add_child(primary_lbl)

		# Behavior — dimmer white
		var behavior_lbl := Label.new()
		behavior_lbl.text = "BEHAVIOR:  " + etf["behavior"]
		behavior_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		behavior_lbl.add_theme_font_size_override("font_size", 12)
		behavior_lbl.offset_left = 18
		behavior_lbl.offset_top = 71
		behavior_lbl.offset_right = 630
		behavior_lbl.offset_bottom = 89
		border.add_child(behavior_lbl)

		# Starting price — right side, red or green
		var price_lbl := Label.new()
		price_lbl.text = etf["start_price"]
		price_lbl.add_theme_color_override("font_color", price_color)
		price_lbl.add_theme_font_size_override("font_size", 26)
		price_lbl.anchor_right = 1.0
		price_lbl.offset_left = -190
		price_lbl.offset_right = -16
		price_lbl.offset_top = 6
		price_lbl.offset_bottom = 46
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		border.add_child(price_lbl)

		# Direction arrow + label
		var arrow_lbl := Label.new()
		arrow_lbl.text = arrow
		arrow_lbl.add_theme_color_override("font_color", price_color)
		arrow_lbl.add_theme_font_size_override("font_size", 13)
		arrow_lbl.anchor_right = 1.0
		arrow_lbl.offset_left = -190
		arrow_lbl.offset_right = -16
		arrow_lbl.offset_top = 48
		arrow_lbl.offset_bottom = 68
		arrow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		border.add_child(arrow_lbl)

		# "in crisis" note
		var crisis_lbl := Label.new()
		crisis_lbl.text = "in crisis"
		crisis_lbl.add_theme_color_override("font_color", Color(price_color.r, price_color.g, price_color.b, 0.5))
		crisis_lbl.add_theme_font_size_override("font_size", 11)
		crisis_lbl.anchor_right = 1.0
		crisis_lbl.offset_left = -190
		crisis_lbl.offset_right = -16
		crisis_lbl.offset_top = 68
		crisis_lbl.offset_bottom = 86
		crisis_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		border.add_child(crisis_lbl)

	# PRESS SPACE TO CONTINUE — bottom, flickering
	_continue_label = Label.new()
	_continue_label.text = "PRESS SPACE TO CONTINUE"
	_continue_label.anchor_left = 0.5
	_continue_label.anchor_right = 0.5
	_continue_label.anchor_top = 1.0
	_continue_label.anchor_bottom = 1.0
	_continue_label.offset_left = -200
	_continue_label.offset_right = 200
	_continue_label.offset_top = -50
	_continue_label.offset_bottom = -14
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_label.add_theme_color_override("font_color", Color(0, 1, 0))
	_continue_label.modulate.a = 0.0
	add_child(_continue_label)

func animate_rows():
	var tween := create_tween()
	for panel in _row_panels:
		tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.finished.connect(func():
		animation_done = true
		_start_blink()
	)

func skip_animation():
	for panel in _row_panels:
		panel.modulate.a = 1.0
	animation_done = true
	_start_blink()

func _start_blink():
	if _blink_on:
		return
	_blink_on = true
	_blink_loop()

func _blink_loop():
	while _blink_on:
		if _continue_label:
			_continue_label.modulate.a = 1.0 if _continue_label.modulate.a < 0.5 else 0.0
		await get_tree().create_timer(0.7).timeout

func _add_debug_label():
	var label = Label.new()
	label.name = "TopRightLabel"
	label.text = "ETFScreen.tscn | ETFScreen.gd"
	label.anchor_left = 1
	label.anchor_right = 1
	label.offset_left = -400
	label.offset_right = -10
	label.offset_top = 10
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0,1,0))
	add_child(label)
