extends Control

@onready var _cycle_label: RichTextLabel = %CycleLabel
@onready var _headline_label: Label = %HeadlineLabel
@onready var _timer_label: Label = %TimerLabel
@onready var decision_panel = get_node_or_null("%DecisionPanel")
@onready var cash_label: Label = %CashLabel
@onready var _portfolio_label: Label = %PortfolioLabel
@onready var pnl_label: Label = get_node_or_null("OuterMargin/MainColumn/TopBarWrapper/TopBar/TopBarMargin/TopBarContent/TopBarStatsRow/pnl_label") as Label
@onready var buying_power_label: Label = get_node_or_null("OuterMargin/MainColumn/BodyRow/TradePanel/TradeMargin/TradeContent/MetricsGrid/BuyingPowerValue") as Label
@onready var position_label: Label = %"PositionLabel"
@onready var _timer_bar: ProgressBar = %TimerBar
@onready var _active_ticker_label: Label = %ActiveTickerLabel
@onready var _active_name_label: Label = %ActiveNameLabel
@onready var _active_price_label: Label = %ActivePriceLabel
@onready var _active_change_label: Label = %ActiveChangeLabel
@onready var _active_context_label: RichTextLabel = %ActiveContextLabel
@onready var _hint_label: Label = %HintLabel
@onready var percent_label: Label = %ActiveChangeLabel

@onready var etf_tabs: Dictionary = {
	"CIQM": %TabCIQM,
	"CIQE": %TabCIQE,
	"CIQD": %TabCIQD,
	"CIQS": %TabCIQS,
	"CIQG": %TabCIQG
}

@onready var _charts: Dictionary = {
	"CIQM": %ChartCIQM,
	"CIQE": %ChartCIQE,
	"CIQD": %ChartCIQD,
	"CIQS": %ChartCIQS,
	"CIQG": %ChartCIQG
}

@onready var _summary_cards: Array = [
	{
		"button": %MiniCard1,
		"ticker": %MiniTicker1,
		"price": %MiniPrice1,
		"change": %MiniChange1
	},
	{
		"button": %MiniCard2,
		"ticker": %MiniTicker2,
		"price": %MiniPrice2,
		"change": %MiniChange2
	},
	{
		"button": %MiniCard3,
		"ticker": %MiniTicker3,
		"price": %MiniPrice3,
		"change": %MiniChange3
	},
	{
		"button": %MiniCard4,
		"ticker": %MiniTicker4,
		"price": %MiniPrice4,
		"change": %MiniChange4
	}
]

@onready var _trade_panel: TradePanel = %TradePanel
@onready var headline_popup = get_node_or_null("HeadlinePopup")
@onready var _popup_breaking_label: Label = %BreakingLabel
@onready var _popup_headline_text: RichTextLabel = %HeadlineText
@onready var _popup_subtext_text: Label = %SubtextText
@onready var _popup_countdown_label: Label = %CountdownLabel

@onready var _info_panel: Control = %ETFInfoPanel
@onready var _info_ticker_label: Label = %InfoTickerLabel
@onready var _info_name_label: Label = %InfoNameLabel
@onready var _info_desc_label: Label = %InfoDescLabel
@onready var _info_context_label: Label = %InfoContextLabel
@onready var _info_modal_bg: ColorRect = %InfoModalBG

@onready var _transition_overlay: Control = %TransitionOverlay
@onready var _liquidation_overlay: Control = %LiquidationOverlay
@onready var _liquidation_value_label: Label = %LiquidationValueLabel
@onready var _liquidation_cycle_label: Label = %LiquidationCycleLabel
@onready var _restart_button: Button = %RestartButton
@onready var _range_1d_button: Button = %Range1D
@onready var _range_1w_button: Button = %Range1W
@onready var _range_1m_button: Button = %Range1M
@onready var _range_3m_button: Button = %Range3M
@onready var _range_ytd_button: Button = %RangeYTD
@onready var _range_1y_button: Button = %Range1Y
@onready var _range_5y_button: Button = %Range5Y
@onready var _range_max_button: Button = %RangeMAX

var _price_tick_timer: float = 0.0
var _price_tick_interval: float = 0.8
var current_ticker: String = "CIQM"
var selected_range: String = "1D"
var max_cycles = 5
var current_cash: float = 0.0
var input_locked = true
var market_open: bool = false
var _headline_reveal_token: int = 0
var _countdown_blinking: bool = false
var _headline_animating: bool = false
var _headline_skip_requested: bool = false
var _cycle_advancing: bool = false
var _showing_cycle_result: bool = false
var _breaking_pulsing: bool = false
var _cycle_label_pulsing: bool = false
var _time_range_buttons: Dictionary = {}
var _time_range_underlines: Dictionary = {}
const TAB_YELLOW: Color = Color("ffd700")
const TAB_YELLOW_ACTIVE: Color = Color(1.0, 0.95, 0.45, 1.0)
const RANGE_ACTIVE: Color = Color("00ff41")
const RANGE_INACTIVE: Color = Color(1.0, 1.0, 1.0, 0.55)
const BREAKING_DELAY: float = 0.45
const HEADLINE_TYPE_SPEED: float = 0.032
const DETAILS_DELAY: float = 0.45
const SUBTEXT_FADE_DURATION: float = 0.45
const COUNTDOWN_BLINK_SPEED: float = 0.55
const BREAKING_PULSE_SPEED: float = 0.7
const CYCLE_PULSE_SPEED: float = 0.9
const DEV_ALLOW_HEADLINE_SKIP: bool = true

var CYCLE_NARRATIVES: Dictionary = {
	"Student": {
		1: "[center]War starts. Broad market is already falling.\nNo research — we buy in.\n[color=#ff4444][b]P → D.[/b][/color] That is all this investor does.[/center]",
		2: "[center]Strait closes. We freeze. CIQE went up 35% — we missed all of it.\nOur CIQM actually bounced this cycle.\nWe did not notice.[/center]",
		3: "[center]China enters. CIQM is below what we paid. Panic sell.\nBought at $92, sold at $79.\nCIQE is at $145 — up 62% from the start. We have none of it.[/center]",
		4: "[center]CIQM down 31% from the start. Looks cheap. We buy back in.\nSold at $79 — now buying at $69.\nThis is the retail trap.[/center]",
		5: "[center]Gulf mined. Recession. We sell again.\nBought at $69, sold at $52. Second loss locked in.\nCIQE finished at $187 — up 134% from the start. We never held it once.[/center]"
	},
	"Young Pro": {
		1: "[center]We skip the headline. We look at the data.\nEnergy supply shock — Hormuz is threatened.\nCIQE rises when Hormuz is at risk. [color=#ff4444][b]I → J → D.[/b][/color][/center]",
		2: "[center]CIQE up 35%. Energy thesis is working.\nDefense pulled back 8% on profit-taking — ground operations are coming.\nThat is a buy signal.[/center]",
		3: "[center]Energy up another 20%. China entering changes the macro.\nEnergy's thesis is complete.\nTime to rotate out before the reversal.[/center]",
		4: "[center]Defense up 30%. Ground invasion is fully priced in.\nWhen the event is priced, you exit.\nRotate to Safe Haven — maximum fear cycle is coming.[/center]",
		5: "[center]Gulf mined. Maximum fear.\nSafe Haven rises in exactly this environment.\nThe data says hold. The Analytical pathway does nothing when the data says stay.[/center]"
	},
	"Mid-career": {
		1: "[center]Data before headline. Energy supply shock — CIQE benefits.\nSafe Haven rises in fear environments.\nThe headline confirms what the data already showed. [color=#ff4444][b]I → P → D.[/b][/color][/center]",
		2: "[center]Strait closes. The crowd is selling CIQM.\nBut the data shows dip buyers entering — CIQM bounced this cycle.\nThe crowd is fleeing. The data says someone is buying the dip.[/center]",
		3: "[center]China enters. The bounce thesis is over. We captured what we could.\nThe data says exit CIQM before further downside.\nCIQE and CIQS are carrying the portfolio.[/center]",
		4: "[center]Shipping has been falling all war — but look: up 15%.\nGround invasion signals Hormuz may reopen.\nThe data shows a counterintuitive signal the crowd is not positioned for.[/center]",
		5: "[center]Gulf mined. CIQG collapses 30%.\nWe bought the Hormuz reopening thesis. The Gulf got mined instead.\nData reshapes perception — but this time the reframe was wrong.[/center]"
	},
	"Veteran": {
		1: "[center]Defense always rises in the first wave of military escalation.\nThis is the same pattern we have seen in every conflict.\nThesis confirmed. We buy. [color=#ff4444][b]P → I → J → D.[/b][/color][/center]",
		2: "[center]Defense dipped 8%. Others are selling. We are buying.\nThe thesis has not changed — the rule says buy Defense in war.\nWe buy the dip. [color=#ff4444][b]P → I → J → D.[/b][/color] Same sequence.[/center]",
		3: "[center]China entering means multi-front conflict.\nDefense spending across multiple nations accelerates.\nThesis strengthens. We add.[/center]",
		4: "[center]Ground forces in the field. Massive logistics and equipment demand.\nDefense is in full contract mode.\nOne more add.[/center]",
		5: "[center]Thesis complete. Five cycles. Same ETF. Same process.\n[color=#ff4444][b]P → I → J → D[/b][/color] — start to finish.\nThe value-driven investor does not panic out and does not chase noise.[/center]"
	}
}

func _ready() -> void:
	_add_debug_label()
	var current_scene_path: String = ""
	var scene := get_tree().current_scene
	if scene:
		current_scene_path = scene.scene_file_path
	print("CURRENT SCENE:", current_scene_path)
	SimulationManager.difficulty_set.connect(_on_difficulty_set)
	SimulationManager.cycle_started.connect(_on_cycle_started)
	SimulationManager.trading_opened.connect(_on_trading_opened)
	SimulationManager.trade_confirmed.connect(_on_trade_confirmed)
	SimulationManager.cycle_complete.connect(_on_cycle_complete)
	SimulationManager.liquidation_triggered.connect(_on_liquidation_triggered)
	SimulationManager.simulation_complete.connect(_on_simulation_complete)

	for ticker in etf_tabs:
		etf_tabs[ticker].pressed.connect(_on_etf_selected.bind(ticker))
	for ticker in _charts:
		_charts[ticker].chart_info_requested.connect(_on_chart_info_requested)
	for card in _summary_cards:
		card["button"].pressed.connect(_on_summary_card_pressed.bind(card["button"]))
	_setup_time_range_controls()
	update_time_range_ui()

	_info_modal_bg.gui_input.connect(_on_info_modal_gui_input)
	_restart_button.pressed.connect(_return_to_start)

	_transition_overlay.visible = false
	_liquidation_overlay.visible = false
	_info_panel.visible = false
	_timer_bar.visible = false
	_timer_bar.min_value = 0.0
	_timer_label.text = ""

	if not headline_popup:
		print("WARNING: HeadlinePopup node missing")
	current_cash = float(SimulationManager.get("current_cash")) if SimulationManager.get("current_cash") != null else SimulationManager.get_cash()
	if decision_panel and decision_panel.has_signal("decision_made"):
		decision_panel.decision_made.connect(_on_decision_made)
	if SimulationManager.has_signal("decision_processed"):
		SimulationManager.decision_processed.connect(_on_decision_result)

	_set_active_etf("CIQM")
	_update_cash_display()
	_update_portfolio_display()
	_refresh_all()

	if SimulationManager.current_state == SimulationManager.State.BRIEFING:
		SimulationManager.start_next_cycle()
	else:
		start_cycle()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_SPACE:
		return
	if input_locked and _headline_animating and DEV_ALLOW_HEADLINE_SKIP:
		_skip_headline_animation()
		get_viewport().set_input_as_handled()
		return
	if input_locked:
		return
	if not SimulationManager.can_advance or SimulationManager.has_advanced:
		return
	SimulationManager.lock_cycle_advance()
	input_locked = true
	_handle_space_press()

func start_cycle():
	SimulationManager.reset_cycle_input_state()
	if _cycle_label:
		_set_cycle_label_text(SimulationManager.current_cycle, max_cycles)
	if headline_popup:
		headline_popup.visible = true
	await get_tree().create_timer(1.5).timeout
	_enable_cycle_input()

func next_cycle():
	if SimulationManager.current_cycle + 1 > max_cycles:
		end_simulation()
		return
	start_cycle()

func end_simulation():
	var target_scene: String = "res://scenes/TPMResultsScreen.tscn"
	print("TRANSITIONING TO:", target_scene)
	get_tree().change_scene_to_file(target_scene)

func _process(_delta: float) -> void:
	if SimulationManager.current_state == SimulationManager.State.TRADING:
		_price_tick_timer += _delta
		if _price_tick_timer >= _price_tick_interval:
			_price_tick_timer = 0.0
			var base_price: float = SimulationManager.get_price(current_ticker)
			if base_price > 0.0:
				var noise: float = randf_range(-0.012, 0.012) * base_price
				var display_price: float = maxf(base_price + noise, 0.01)
				_active_price_label.text = "$%.2f" % display_price
	else:
		_price_tick_timer = 0.0
		_active_price_label.text = "$%.2f" % SimulationManager.get_price(current_ticker)
	var chart_controller: CandlestickChart = _charts.get(current_ticker)
	var history: Array = SimulationManager.get_price_history(current_ticker)
	if chart_controller and chart_controller.visible_points > 0 and chart_controller.visible_points <= history.size():
		var current_price: float = float(history[chart_controller.visible_points - 1])
		_active_price_label.text = "$%.2f" % current_price
	_refresh_top_bar()

func _on_difficulty_set(_tier: String, _cash: float, _timer: float) -> void:
	_apply_active_etf_state()
	_refresh_all()

func _on_cycle_started(cycle_num: int, cycle_data: CrashCycle) -> void:
	market_open = false
	SimulationManager.reset_cycle_input_state()
	_stop_headline_cta()
	_reset_cycle_label_pulse()
	_transition_overlay.visible = false
	_liquidation_overlay.visible = false
	_set_cycle_label_text(cycle_num, SimulationManager.get_cycle_count())
	_start_cycle_label_pulse(cycle_num)
	_headline_label.text = "BREAKING FEED INCOMING..."
	_headline_label.modulate = Color("ff4444")
	if headline_popup:
		await _play_headline_sequence(cycle_data)
	else:
		await get_tree().create_timer(1.5).timeout
		_enable_cycle_input()
	_refresh_all()
	print("Cycle:", SimulationManager.current_cycle)
	print("can_advance:", SimulationManager.can_advance)
	print("has_advanced:", SimulationManager.has_advanced)

func _on_trading_opened(_time_limit: float) -> void:
	market_open = true
	input_locked = true
	_trade_panel.select_etf(current_ticker)
	_refresh_all()
	print("Cycle:", SimulationManager.current_cycle)
	print("can_advance:", SimulationManager.can_advance)
	print("has_advanced:", SimulationManager.has_advanced)

func _on_trade_confirmed(_trade_data: Dictionary) -> void:
	_update_cash_display()
	_update_position_display()
	_update_portfolio_display()
	_update_tab_highlight()
	_refresh_summary_cards()
	_apply_active_etf_state()
	_refresh_all()

func _on_cycle_complete(cycle_num: int, _portfolio_value: float) -> void:
	market_open = true
	_timer_label.text = ""
	input_locked = true
	_update_cash_display()
	_update_portfolio_display()
	_refresh_all()
	_show_cycle_result(cycle_num, {})
	await get_tree().create_timer(5.0).timeout
	if cycle_num < max_cycles:
		SimulationManager.start_next_cycle()
	else:
		_finish_game()

func _finish_game() -> void:
	var target: String = "res://scenes/TPMResultsScreen.tscn"
	print("TRANSITIONING TO:", target)
	get_tree().change_scene_to_file(target)

func _on_liquidation_triggered(final_data: Dictionary) -> void:
	market_open = false
	_transition_overlay.visible = false
	_liquidation_overlay.visible = true
	_liquidation_value_label.text = _format_currency(final_data.get("final_value", 0.0))
	_liquidation_cycle_label.text = "Liquidated in cycle %d" % int(final_data.get("liquidated_cycle", SimulationManager.current_cycle))

func _on_simulation_complete(_final_data: Dictionary) -> void:
	market_open = false
	_transition_overlay.visible = false

func _handle_space_press() -> void:
	if _cycle_advancing:
		return
	if _showing_cycle_result and SimulationManager.current_cycle < SimulationManager.get_cycle_count():
		return
	_cycle_advancing = true
	if SimulationManager.current_state == SimulationManager.State.HEADLINE and not market_open:
		_start_market_phase()
	elif SimulationManager.current_state == SimulationManager.State.CYCLE_RESULT and market_open:
		_advance_to_next_cycle()
	await get_tree().process_frame
	_cycle_advancing = false

func _start_market_phase() -> void:
	market_open = true
	print("Market opened manually")
	start_trading_phase()

func _advance_to_next_cycle() -> void:
	market_open = false
	SimulationManager.lock_cycle_advance()
	input_locked = true
	print("Advancing to next cycle")
	print("Cycle:", SimulationManager.current_cycle)
	print("can_advance:", SimulationManager.can_advance)
	print("has_advanced:", SimulationManager.has_advanced)
	if SimulationManager.current_cycle < SimulationManager.get_cycle_count():
		show_cycle_transition()
		SimulationManager.start_next_cycle()

func start_trading_phase() -> void:
	if headline_popup:
		_stop_headline_cta()
		headline_popup.dismiss()
	else:
		print("HeadlinePopup not found")
	SimulationManager.open_trading_phase()

func show_cycle_transition() -> void:
	_transition_overlay.visible = false

func _play_headline_sequence(cycle_data: CrashCycle) -> void:
	if headline_popup == null:
		return
	_headline_reveal_token += 1
	var token: int = _headline_reveal_token
	var display_headline: String = _sanitize_headline(cycle_data.headline)
	headline_popup.reset_view()
	headline_popup.visible = true
	_headline_animating = true
	_headline_skip_requested = false
	_breaking_pulsing = false
	_popup_breaking_label.text = "BREAKING:"
	_popup_breaking_label.modulate.a = 1.0
	_popup_headline_text.text = ""
	_popup_headline_text.visible_characters = -1
	_popup_headline_text.modulate.a = 1.0
	_popup_subtext_text.text = _build_headline_briefing(cycle_data)
	_popup_subtext_text.modulate.a = 0.0
	_popup_countdown_label.text = ""
	_popup_countdown_label.modulate.a = 0.0
	await get_tree().create_timer(BREAKING_DELAY).timeout
	if token != _headline_reveal_token:
		return
	_start_breaking_pulse(token)
	await _typewriter_popup_headline(display_headline, token)
	if token != _headline_reveal_token:
		return
	await get_tree().create_timer(DETAILS_DELAY).timeout
	if token != _headline_reveal_token:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_popup_subtext_text, "modulate:a", 1.0, SUBTEXT_FADE_DURATION)
	await tween.finished
	if token != _headline_reveal_token:
		return
	_popup_countdown_label.text = "PRESS SPACE TO OPEN MARKETS"
	_popup_countdown_label.modulate.a = 1.0
	_headline_label.text = display_headline
	_headline_label.modulate = Color("ffd700")
	_start_headline_cta(token)
	_headline_animating = false
	_enable_cycle_input()

func _typewriter_popup_headline(headline_text: String, token: int) -> void:
	for index in range(1, headline_text.length() + 1):
		if token != _headline_reveal_token:
			return
		if _headline_skip_requested:
			_popup_headline_text.text = headline_text
			return
		_popup_headline_text.text = headline_text.substr(0, index)
		await get_tree().create_timer(HEADLINE_TYPE_SPEED).timeout
	_popup_headline_text.text = headline_text

func _start_headline_cta(token: int) -> void:
	if _countdown_blinking:
		return
	_countdown_blinking = true
	_blink_headline_cta(token)

func _blink_headline_cta(token: int) -> void:
	while _countdown_blinking and token == _headline_reveal_token:
		_popup_countdown_label.modulate.a = 1.0 if _popup_countdown_label.modulate.a < 0.5 else 0.2
		await get_tree().create_timer(COUNTDOWN_BLINK_SPEED).timeout

func _start_breaking_pulse(token: int) -> void:
	if _breaking_pulsing:
		return
	_breaking_pulsing = true
	_pulse_breaking_loop(token)

func _pulse_breaking_loop(token: int) -> void:
	while _breaking_pulsing and token == _headline_reveal_token:
		if _popup_breaking_label:
			_popup_breaking_label.modulate.a = 1.0 if _popup_breaking_label.modulate.a < 0.75 else 0.55
		await get_tree().create_timer(BREAKING_PULSE_SPEED).timeout
	if _popup_breaking_label:
		_popup_breaking_label.modulate.a = 1.0

func _skip_headline_animation() -> void:
	if not _headline_animating:
		return
	_headline_reveal_token += 1
	_headline_skip_requested = true
	_complete_headline_animation_immediately()

func _complete_headline_animation_immediately() -> void:
	var cycle_data: CrashCycle = SimulationManager.get_cycle_data(SimulationManager.current_cycle)
	var display_headline: String = _sanitize_headline(cycle_data.headline)
	_popup_breaking_label.modulate.a = 1.0
	_popup_headline_text.text = display_headline
	_popup_headline_text.modulate.a = 1.0
	_popup_subtext_text.text = _build_headline_briefing(cycle_data)
	_popup_subtext_text.modulate.a = 1.0
	_popup_countdown_label.text = "PRESS SPACE TO OPEN MARKETS"
	_popup_countdown_label.modulate.a = 1.0
	_headline_label.text = display_headline
	_headline_label.modulate = Color("ffd700")
	_headline_animating = false
	_start_headline_cta(_headline_reveal_token)
	_enable_cycle_input()

func _build_headline_briefing(cycle_data: CrashCycle) -> String:
	var narrative: String = ""
	match cycle_data.cycle_number:
		1:
			narrative = "Shock hits the tape immediately. Traders scramble to price in escalation, panic selling, and first-wave volatility."
		2:
			narrative = "Energy desks go into emergency mode as supply risk intensifies. Volatility spikes and liquidity gets thinner."
		3:
			narrative = "Escalation broadens into a regional market shock. Capital rotates fast while fear, uncertainty, and repricing spread."
		4:
			narrative = "War footing is now explicit. Markets react to force, logistics stress, and a deeper risk-off panic across sectors."
		5:
			narrative = "This is full crisis pricing. Recession fear, systemic panic, and extreme volatility dominate every asset on the board."
		_:
			narrative = "Markets are repricing the crisis in real time."
	return cycle_data.subtext + "\n\n" + narrative

func _sanitize_headline(headline: String) -> String:
	if headline.begins_with("BREAKING: "):
		return headline.trim_prefix("BREAKING: ")
	if headline.begins_with("BREAKING:"):
		return headline.trim_prefix("BREAKING:").strip_edges()
	return headline

func _stop_headline_cta() -> void:
	_countdown_blinking = false
	_headline_reveal_token += 1
	_headline_animating = false
	_headline_skip_requested = false
	_breaking_pulsing = false
	if _popup_breaking_label:
		_popup_breaking_label.modulate.a = 1.0
	if _popup_headline_text:
		_popup_headline_text.modulate.a = 1.0

func _start_cycle_label_pulse(cycle_num: int) -> void:
	if _cycle_label_pulsing:
		return
	_cycle_label_pulsing = true
	_cycle_label_pulse_loop(cycle_num)

func _cycle_label_pulse_loop(cycle_num: int) -> void:
	while _cycle_label_pulsing and SimulationManager.current_cycle == cycle_num:
		if _cycle_label:
			_cycle_label.modulate.a = 1.0 if _cycle_label.modulate.a < 0.8 else 0.72
		await get_tree().create_timer(CYCLE_PULSE_SPEED).timeout
	if _cycle_label:
		_cycle_label.modulate.a = 1.0

func _reset_cycle_label_pulse() -> void:
	_cycle_label_pulsing = false
	if _cycle_label:
		_cycle_label.modulate.a = 1.0

func _enable_cycle_input() -> void:
	input_locked = false
	SimulationManager.enable_cycle_input_state()
	print("Cycle:", SimulationManager.current_cycle)
	print("can_advance:", SimulationManager.can_advance)
	print("has_advanced:", SimulationManager.has_advanced)

func _on_etf_selected(ticker: String) -> void:
	_set_active_etf(ticker)

func _select_ticker(ticker: String) -> void:
	_set_active_etf(ticker)

func _on_summary_card_pressed(button: Button) -> void:
	var ticker: String = String(button.get_meta("ticker", ""))
	if not ticker.is_empty():
		_select_ticker(ticker)

func _setup_time_range_controls() -> void:
	print("Setting up time range controls")
	_time_range_buttons = {
		"1D": _range_1d_button,
		"1W": _range_1w_button,
		"1M": _range_1m_button,
		"3M": _range_3m_button,
		"YTD": _range_ytd_button,
		"1Y": _range_1y_button,
		"5Y": _range_5y_button,
		"MAX": _range_max_button
	}
	_time_range_underlines.clear()
	for range_name in _time_range_buttons:
		var button: Button = _time_range_buttons[range_name]
		if button == null:
			print("Missing time range button:", range_name)
			continue
		if not button.is_in_group("time_range_buttons"):
			button.add_to_group("time_range_buttons")
		var on_pressed: Callable = _on_time_range_selected.bind(range_name)
		if not button.pressed.is_connected(on_pressed):
			button.pressed.connect(on_pressed)
		var underline: ColorRect = button.get_node_or_null("Underline") as ColorRect
		if underline == null:
			print("Missing underline for range:", range_name)
			continue
		_time_range_underlines[range_name] = underline

func _on_time_range_selected(range_name: String) -> void:
	print("Clicked:", range_name)
	selected_range = range_name
	update_time_range_ui()

func update_time_range_ui() -> void:
	for range_name in _time_range_buttons:
		var button: Button = _time_range_buttons[range_name]
		if button == null:
			continue
		var is_active: bool = range_name == selected_range
		var color: Color = RANGE_ACTIVE if is_active else RANGE_INACTIVE
		button.add_theme_color_override("font_color", color)
		button.add_theme_color_override("font_hover_color", color)
		button.add_theme_color_override("font_pressed_color", color)
		button.add_theme_color_override("font_focus_color", color)
		var underline: ColorRect = _time_range_underlines.get(range_name) as ColorRect
		if underline:
			underline.visible = is_active

func _on_chart_info_requested(ticker: String) -> void:
	_select_ticker(ticker)
	BehaviorTracker.record_info_panel_opened(ticker)
	_info_ticker_label.text = "$" + ticker
	_info_name_label.text = SimulationManager.get_etf_name(ticker)
	_info_desc_label.text = SimulationManager.get_etf_description(ticker)
	_info_context_label.text = SimulationManager.get_etf_context(ticker)
	_info_panel.visible = true

func _on_info_modal_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_info_panel.visible = false
			BehaviorTracker.record_headline_viewed()

func _refresh_all() -> void:
	_refresh_top_bar()
	_apply_active_etf_state()

func _refresh_top_bar() -> void:
	var simulation_cycle: int = SimulationManager.current_cycle
	_set_cycle_label_text(simulation_cycle, SimulationManager.get_cycle_count())
	_update_cash_display()
	_portfolio_label.text = "Portfolio  %s" % _format_currency(SimulationManager.get_portfolio_value())
	_update_portfolio_display()

	var portfolio_value: float = SimulationManager.get_portfolio_value()
	if portfolio_value > SimulationManager.starting_cash:
		_portfolio_label.modulate = Color("00ff41")
	elif portfolio_value < SimulationManager.starting_cash:
		_portfolio_label.modulate = Color("ff4444")
	else:
		_portfolio_label.modulate = Color(1.0, 1.0, 1.0, 0.92)

	if SimulationManager.current_state != SimulationManager.State.TRADING:
		_timer_label.modulate = Color(1.0, 1.0, 1.0, 0.45)

func _update_cash_display() -> void:
	var cash: float = SimulationManager.get_cash()
	if cash_label:
		cash_label.text = "Cash: $%.2f" % cash
	if buying_power_label:
		buying_power_label.text = "$%.2f" % cash

func _update_portfolio_display() -> void:
	var total: float = SimulationManager.get_portfolio_value()
	var cash: float = SimulationManager.get_cash()
	var pnl: float = total - SimulationManager.starting_cash

	if cash_label:
		cash_label.text = "Cash: $%.2f" % cash
	if _portfolio_label:
		_portfolio_label.text = "Portfolio: $%.2f" % total
	if pnl_label:
		pnl_label.modulate = Color("00ff41") if pnl >= 0.0 else Color("ff4444")
		pnl_label.text = "P/L: $%.2f" % pnl

func _update_position_display() -> void:
	var shares: float = SimulationManager.get_shares(current_ticker)
	position_label.text = "Position %.4f shares" % shares

func _get_cycle_narrative(cycle_num: int) -> String:
	var difficulty: String = SimulationManager.selected_difficulty
	if CYCLE_NARRATIVES.has(difficulty) and CYCLE_NARRATIVES[difficulty].has(cycle_num):
		return CYCLE_NARRATIVES[difficulty][cycle_num]
	return "Cycle %d of %d complete." % [cycle_num, SimulationManager.get_cycle_count()]

func _show_cycle_result(cycle_num: int, _trade_data: Dictionary) -> void:
	_showing_cycle_result = true

	var narrative: String = _get_cycle_narrative(cycle_num)

	var banner: PanelContainer = PanelContainer.new()
	banner.name = "CycleResultBanner"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 10

	var viewport_size: Vector2 = get_viewport_rect().size
	var banner_w: float = viewport_size.x * 0.82

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.84, 0.0, 0.18)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color("ffd700")
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	banner.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var cycle_lbl: Label = Label.new()
	cycle_lbl.text = "CYCLE %d / %d" % [cycle_num, SimulationManager.get_cycle_count()]
	cycle_lbl.add_theme_font_size_override("font_size", 15)
	cycle_lbl.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.55))
	cycle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cycle_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var narrative_lbl: Label = Label.new()
	narrative_lbl.text = narrative
	narrative_lbl.add_theme_font_size_override("font_size", 24)
	narrative_lbl.add_theme_color_override("font_color", Color("ff4444"))
	narrative_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narrative_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative_lbl.custom_minimum_size = Vector2(banner_w - 96.0, 0.0)
	narrative_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	vbox.add_child(cycle_lbl)
	vbox.add_child(narrative_lbl)
	margin.add_child(vbox)
	banner.add_child(margin)

	var target_x: float = (viewport_size.x - banner_w) / 2.0
	var target_y: float = viewport_size.y * 0.35

	banner.set_anchors_preset(Control.PRESET_TOP_LEFT)
	banner.custom_minimum_size = Vector2(banner_w, 0.0)
	banner.position = Vector2(-banner_w, target_y)

	add_child(banner)

	var tween: Tween = create_tween()
	tween.tween_property(banner, "position:x", target_x, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(4.0)
	tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	await tween.finished
	if is_instance_valid(banner):
		banner.queue_free()
	_showing_cycle_result = false

func _update_tab_highlight() -> void:
	for ticker in etf_tabs:
		var btn: Button = etf_tabs[ticker]
		if ticker == current_ticker:
			btn.modulate = Color(1, 0.85, 0.2)
		else:
			btn.modulate = Color(0.5, 0.5, 0.5)
		var shares: float = SimulationManager.get_shares(ticker)
		btn.text = "$" + ticker + (" ●" if shares > 0.0 else "")

func _refresh_market_focus() -> void:
	_apply_active_etf_state()

func _set_active_etf(ticker: String) -> void:
	if not SimulationManager.ETF_DATA.has(ticker):
		return
	current_ticker = ticker
	_apply_active_etf_state()

func _apply_active_etf_state() -> void:
	_update_tab_highlight()
	for ticker in etf_tabs:
		var button: Button = etf_tabs[ticker]
		button.add_theme_color_override("font_color", TAB_YELLOW)
		button.add_theme_color_override("font_focus_color", TAB_YELLOW_ACTIVE)
		button.add_theme_color_override("font_hover_color", TAB_YELLOW_ACTIVE)
		button.add_theme_color_override("font_pressed_color", TAB_YELLOW_ACTIVE)

	for ticker in _charts:
		_charts[ticker].visible = ticker == current_ticker
		_charts[ticker].set_chart_focused(ticker == current_ticker)

	_active_ticker_label.text = "$" + current_ticker
	_active_name_label.text = SimulationManager.get_etf_name(current_ticker)
	var price: float = SimulationManager.get_price(current_ticker)
	_active_price_label.text = "$%.2f" % price

	var change: float = SimulationManager.get_cycle_change(current_ticker) * 100.0
	var sign_str: String = "+" if change >= 0.0 else ""
	_active_change_label.text = "%s%.2f%% this cycle" % [sign_str, change]
	_active_change_label.modulate = Color("00ff41") if change >= 0.0 else Color("ff4444")
	_update_etf_explanation(current_ticker)
	_hint_label.text = _get_hint(current_ticker)
	_update_position_display()

	_refresh_summary_cards()
	_trade_panel.select_etf(current_ticker)

func _update_price_display() -> void:
	var price: float = SimulationManager.get_price(current_ticker)
	_active_price_label.text = "$%.2f" % price
	var change: float = SimulationManager.get_cycle_change(current_ticker) * 100.0
	percent_label.text = "%.2f%% this cycle" % change
	if change < 0.0:
		percent_label.modulate = Color(1, 0.2, 0.2)
	else:
		percent_label.modulate = Color(0, 1, 0)
	percent_label.modulate.a = 1.0

func _update_chart() -> void:
	var raw_history: Array = SimulationManager.get_price_history(current_ticker)
	print(typeof(raw_history), raw_history)
	var price_history: Array[float] = []
	for value in raw_history:
		price_history.append(float(value))
	print("Chart data:", price_history)
	if price_history.is_empty():
		print("No price data for chart")
		return
	if price_history.size() < 2:
		price_history = [price_history[0], price_history[0]]

	var chart_controller: CandlestickChart = _charts.get(current_ticker)
	if chart_controller:
		chart_controller.set_data(price_history)
		chart_controller.queue_redraw()

func _update_etf_explanation(ticker: String) -> void:
	var sections: Dictionary = SimulationManager.get_etf_behavior_sections(ticker)
	var primary_effect: String = String(sections.get("primary", ""))
	var investor_behavior: String = String(sections.get("behavior", ""))

	_active_context_label.text = (
		"[color=#ff4444][b]PRIMARY EFFECT:[/b][/color] [color=#ffffff]%s[/color]\n\n" +
		"[color=#00ff41][b]INVESTOR BEHAVIOR:[/b][/color] [color=#f2f2f2]%s[/color]"
	) % [primary_effect, investor_behavior]

func _get_hint(ticker: String) -> String:
	match ticker:
		"CIQM":
			return "Most players SELL during panic"
		"CIQE":
			return "Many BUY energy in crises"
		"CIQD":
			return "Defense often rises in war"
		"CIQS":
			return "Safe haven = lower risk"
		"CIQG":
			return "Shipping weak in conflict"
		_:
			return ""

func _refresh_summary_cards() -> void:
	var other_tickers: Array[String] = []
	for ticker in SimulationManager.get_etf_order():
		if ticker != current_ticker:
			other_tickers.append(ticker)

	for index in range(_summary_cards.size()):
		var card: Dictionary = _summary_cards[index]
		if index >= other_tickers.size():
			card["button"].visible = false
			card["button"].set_meta("ticker", "")
			continue

		var ticker: String = other_tickers[index]
		card["button"].visible = true
		card["button"].set_meta("ticker", ticker)
		card["ticker"].text = "$" + ticker
		var price: float = SimulationManager.get_price(ticker)
		card["price"].text = "$%.2f" % price
		var change: float = SimulationManager.get_cycle_change(ticker) * 100.0
		var sign_str: String = "+" if change >= 0.0 else ""
		card["change"].text = "%s%.2f%%" % [sign_str, change]
		card["change"].modulate = Color("00ff41") if change >= 0.0 else Color("ff4444")

func _return_to_start() -> void:
	SimulationManager.reset()
	BehaviorTracker.reset()
	var target_scene: String = "res://scenes/StartScreen.tscn"
	print("TRANSITIONING TO:", target_scene)
	get_tree().change_scene_to_file(target_scene)

func _on_decision_made(choice) -> void:
	SimulationManager.process_decision(choice)

func _on_decision_result(data) -> void:
	current_cash = data["cash"]
	_update_cash_display()
	show_feedback(data["delta"])

func show_feedback(delta) -> void:
	var label: Label = Label.new()
	if delta >= 0:
		label.text = "+$" + str(round(delta))
		label.modulate = Color.GREEN
	else:
		label.text = "-$" + str(round(abs(delta)))
		label.modulate = Color.RED
	add_child(label)
	var tween: Tween = create_tween()
	tween.tween_property(label, "modulate:a", 0, 0.6)

func show_final_profile() -> void:
	var result = SimulationManager.get_primary_profile()
	print("FINAL TYPE: ", result)

func _format_currency(value: float) -> String:
	return "$%s" % _format_number(value)

func _format_number(value: float) -> String:
	var raw: String = "%.2f" % value
	var parts: PackedStringArray = raw.split(".")
	var integer_part: String = parts[0]
	var prefix: String = ""
	if integer_part.begins_with("-"):
		prefix = "-"
		integer_part = integer_part.substr(1)
	var result: String = ""
	var count: int = 0
	for index in range(integer_part.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = integer_part[index] + result
		count += 1
	return prefix + result + "." + parts[1]

func _set_cycle_label_text(cycle_num: int, total_cycles: int) -> void:
	if not _cycle_label:
		return
	_cycle_label.text = "[b][color=#FFD700]CYCLE[/color][/b] [color=#FFFFFF]%d/%d[/color]" % [cycle_num, total_cycles]

func _add_debug_label():
	var label = Label.new()
	label.name = "TopRightDebugLabel"
	var current_scene_path: String = ""
	var scene := get_tree().current_scene
	if scene:
		current_scene_path = scene.scene_file_path
	var script_file_path := ""
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
	label.add_theme_color_override("font_color", Color(0,1,0))
	add_child(label)
