class_name TradePanel
extends Control

const COLOR_ACTIVE: Color = Color("00ff41")
const COLOR_SELL: Color = Color("ff4444")
const COLOR_HOLD: Color = Color("ffd700")
const COLOR_DIM: Color = Color(1.0, 1.0, 1.0, 0.35)
const COLOR_TEXT: Color = Color(1.0, 1.0, 1.0, 0.92)
const COLOR_PANEL_BUTTON: Color = Color("111111")
const COLOR_MODE_ACTIVE: Color = Color("ffd700")

@onready var _ticker_label: Label = %OrderTickerLabel
@onready var _name_label: Label = %OrderNameLabel
@onready var _action_buy_btn: Button = %ActionBuyButton
@onready var _action_sell_btn: Button = %ActionSellButton
@onready var _mode_shares_btn: Button = %ModeSharesButton
@onready var _mode_dollars_btn: Button = %ModeDollarsButton
@onready var _quantity_input: LineEdit = %QuantityInput
@onready var _position_label: Label = %PositionLabel
@onready var _market_price_label: Label = %MarketPriceValue
@onready var _estimate_label: Label = %EstimateValue
@onready var _buying_power_label: Label = %BuyingPowerValue
@onready var _status_label: Label = %OrderStatusLabel
@onready var _review_button: Button = %ReviewButton
@onready var _hold_button: Button = %HoldButton

@onready var _review_popup: Control = %ReviewPopup
@onready var _review_action_label: Label = %ReviewActionLabel
@onready var _review_ticker_label: Label = %ReviewTickerLabel
@onready var _review_quantity_label: Label = %ReviewQuantityLabel
@onready var _review_price_label: Label = %ReviewPriceLabel
@onready var _review_total_label: Label = %ReviewTotalLabel
@onready var _confirm_button: Button = %ConfirmReviewButton
@onready var _cancel_button: Button = %CancelReviewButton

var _selected_ticker: String = "CIQM"
var _action: String = "BUY"
var _quantity_mode: String = "DOLLARS"
var _trade_start_us: int = 0
var use_dollars: bool = true
var _input_attention_active: bool = false
var _input_attention_on: bool = false
const INPUT_PULSE_SPEED: float = 0.7

func _ready() -> void:
	visible = false
	_review_popup.visible = false
	use_dollars = true

	SimulationManager.trading_opened.connect(_on_trading_opened)
	SimulationManager.trade_confirmed.connect(_on_trade_confirmed)
	SimulationManager.cycle_complete.connect(_on_cycle_finished)
	SimulationManager.liquidation_triggered.connect(_on_cycle_finished)
	SimulationManager.simulation_complete.connect(_on_cycle_finished)

	_action_buy_btn.pressed.connect(_set_action.bind("BUY"))
	_action_sell_btn.pressed.connect(_set_action.bind("SELL"))
	_mode_shares_btn.pressed.connect(_set_quantity_mode.bind("SHARES"))
	_mode_dollars_btn.pressed.connect(_set_quantity_mode.bind("DOLLARS"))
	_quantity_input.text_changed.connect(_on_quantity_changed)
	_quantity_input.focus_entered.connect(_stop_input_attention)
	_review_button.pressed.connect(_open_review_popup)
	_hold_button.pressed.connect(_submit_hold)
	_confirm_button.pressed.connect(_confirm_review)
	_cancel_button.pressed.connect(_close_review_popup)

	_style_button(_action_buy_btn, COLOR_PANEL_BUTTON, Color("ffffff"))
	_style_button(_action_sell_btn, COLOR_PANEL_BUTTON, Color("ffffff"))
	_style_button(_mode_shares_btn, COLOR_PANEL_BUTTON, Color("ffffff"))
	_style_button(_mode_dollars_btn, COLOR_PANEL_BUTTON, Color("ffffff"))
	_style_button(_review_button, COLOR_ACTIVE, Color("000000"))
	_style_button(_hold_button, COLOR_HOLD, Color("000000"))
	_style_button(_confirm_button, COLOR_ACTIVE, Color("000000"))
	_style_button(_cancel_button, COLOR_PANEL_BUTTON, Color("ffffff"))

	_hold_button.text = "END CYCLE"
	_refresh_ui()

func select_etf(ticker: String) -> void:
	if not SimulationManager.ETF_DATA.has(ticker):
		return
	_selected_ticker = ticker
	_refresh_ui()

func get_selected_ticker() -> String:
	return _selected_ticker

func _on_trading_opened(_time_limit: float) -> void:
	visible = true
	_trade_start_us = Time.get_ticks_usec()
	if not SimulationManager.ETF_DATA.has(_selected_ticker):
		_selected_ticker = SimulationManager.get_etf_order()[0]
	_action = "BUY"
	_quantity_mode = "DOLLARS"
	_quantity_input.text = ""
	_status_label.text = "Orders execute at market price. Fractional shares enabled."
	_close_review_popup()
	_refresh_ui()
	_start_input_attention()

func _on_trade_confirmed(trade_data: Dictionary) -> void:
	_stop_input_attention()
	var action: String = String(trade_data.get("trade_action", "HOLD")).to_upper()
	if action == "BUY" or action == "SELL":
		_quantity_input.text = ""
		_status_label.text = "%s order filled. Make another trade or press END CYCLE." % action.capitalize()
	_update_cash_display()
	_update_position_display()
	_update_portfolio_value()
	_refresh_ui()

func _on_cycle_finished(_data_a = null, _data_b = null) -> void:
	visible = false
	_stop_input_attention()
	_close_review_popup()

func _set_action(action: String) -> void:
	_action = action
	_close_review_popup()
	_refresh_ui()

func _set_quantity_mode(quantity_mode: String) -> void:
	_quantity_mode = quantity_mode
	use_dollars = quantity_mode == "DOLLARS"
	_close_review_popup()
	_refresh_ui()

func _on_quantity_changed(_new_text: String) -> void:
	_stop_input_attention()
	_close_review_popup()
	var dollars: float = float(_quantity_input.text)
	var price: float = SimulationManager.get_price(_selected_ticker)

	if price <= 0.0:
		return

	var shares: float = dollars / price
	_estimate_label.text = "$%.2f" % dollars
	_status_label.text = "You will own %.4f shares" % shares

	var remaining_cash: float = SimulationManager.get_cash() - dollars
	if remaining_cash < 0.0:
		_estimate_label.modulate = Color(1, 0, 0)
	else:
		_estimate_label.modulate = Color(1, 1, 1)
	_refresh_ui()

func _refresh_ui() -> void:
	_ticker_label.text = "$" + _selected_ticker
	_name_label.text = SimulationManager.get_etf_name(_selected_ticker)
	_position_label.text = "Position  %s shares" % _format_shares(SimulationManager.get_shares(_selected_ticker))
	_market_price_label.text = _format_currency(SimulationManager.get_etf_price(_selected_ticker))
	_buying_power_label.text = _format_currency(SimulationManager.get_cash())

	var estimate: Dictionary = _current_estimate()
	_estimate_label.text = _format_currency(estimate.get("total", 0.0))
	_estimate_label.modulate = Color(1, 1, 1)

	_set_button_state(_action_buy_btn, COLOR_ACTIVE if _action == "BUY" else COLOR_PANEL_BUTTON, Color("ffffff"))
	_set_button_state(_action_sell_btn, COLOR_SELL if _action == "SELL" else COLOR_PANEL_BUTTON, Color("ffffff"))
	_set_button_state(_mode_shares_btn, COLOR_MODE_ACTIVE if _quantity_mode == "SHARES" else COLOR_PANEL_BUTTON, Color("ffffff"))
	_set_button_state(_mode_dollars_btn, COLOR_MODE_ACTIVE if _quantity_mode == "DOLLARS" else COLOR_PANEL_BUTTON, Color("ffffff"))

	_quantity_input.placeholder_text = "Enter $ amount to invest"
	_review_button.text = "Review %s Order" % _action.capitalize()

	var validation: Dictionary = _validate_current_order()
	_review_button.disabled = not validation.get("ok", false)
	_set_button_state(_review_button, COLOR_ACTIVE if _action == "BUY" else COLOR_SELL, Color("000000"))
	if _review_button.disabled:
		_set_button_state(_review_button, COLOR_PANEL_BUTTON, Color("ffffff"))

	_set_button_state(_hold_button, COLOR_HOLD, Color("000000"))

	if _quantity_input.text.strip_edges().is_empty():
		_status_label.text = "Enter %s to preview this order." % ("shares" if _quantity_mode == "SHARES" else "dollars")
	elif validation.get("ok", false):
		var shares: float = estimate.get("shares", 0.0)
		_status_label.text = "Estimated %s shares at %s." % [
			_format_shares(shares),
			_format_currency(estimate.get("price", 0.0))
		]
	else:
		_status_label.text = validation.get("message", "")

func _current_estimate() -> Dictionary:
	if use_dollars:
		var dollars: float = maxf(_quantity_input.text.to_float(), 0.0)
		var price: float = SimulationManager.get_etf_price(_selected_ticker)
		return {
			"shares": _get_quantity_value(),
			"total": dollars,
			"price": price
		}

	var quantity: float = maxf(_quantity_input.text.to_float(), 0.0)
	return SimulationManager.get_order_estimate(_selected_ticker, _get_quantity_mode(), quantity)

func _validate_current_order() -> Dictionary:
	var trade_data: Dictionary = _build_trade_data()
	return SimulationManager.validate_trade(trade_data)

func _build_trade_data() -> Dictionary:
	var quantity_value: float = maxf(_quantity_input.text.to_float(), 0.0)
	return {
		"time_to_decide": _elapsed_decision_time(),
		"trade_action": _action,
		"etf_traded": _selected_ticker,
		"quantity_mode": "DOLLARS" if use_dollars else "SHARES",
		"quantity": quantity_value,
		"dollar_amount": maxf(_quantity_input.text.to_float(), 0.0),
		"stop_loss_set": false,
		"portfolio_value_before": SimulationManager.get_portfolio_value()
	}

func _get_quantity_mode() -> String:
	return "DOLLARS" if use_dollars else "SHARES"

func _get_quantity_value() -> float:
	var dollars: float = float(_quantity_input.text)
	var price: float = SimulationManager.get_etf_price(_selected_ticker)

	if price <= 0.0:
		return 0.0

	return dollars / price

func _open_review_popup() -> void:
	var validation: Dictionary = _validate_current_order()
	if not validation.get("ok", false):
		_status_label.text = validation.get("message", "")
		return

	var estimate: Dictionary = _current_estimate()
	_review_action_label.text = "%s %s" % [_action, SimulationManager.get_etf_name(_selected_ticker)]
	_review_ticker_label.text = "$" + _selected_ticker
	_review_quantity_label.text = "%s %s" % [
		_format_shares(estimate.get("shares", 0.0)),
		"shares"
	]
	_review_price_label.text = _format_currency(estimate.get("price", 0.0))
	_review_total_label.text = _format_currency(estimate.get("estimated_total", estimate.get("total", 0.0)))
	_review_popup.visible = true

func _confirm_review() -> void:
	var dollars: float = float(_quantity_input.text)
	if use_dollars and dollars > SimulationManager.get_cash():
		print("Not enough cash")
		_status_label.text = "Not enough cash"
		return

	var trade_data: Dictionary = _build_trade_data()
	var ok: bool = SimulationManager.confirm_trade(trade_data)
	if ok:
		_close_review_popup()
		_status_label.text = "%s order filled." % _action.capitalize()
	else:
		var validation: Dictionary = SimulationManager.validate_trade(trade_data)
		_status_label.text = validation.get("message", "Order failed.")

func _submit_hold() -> void:
	var hold_trade: Dictionary = {
		"time_to_decide": _elapsed_decision_time(),
		"trade_action": "HOLD",
		"etf_traded": "",
		"quantity_mode": "DOLLARS",
		"quantity": 0.0,
		"dollar_amount": 0.0,
		"stop_loss_set": false,
		"portfolio_value_before": SimulationManager.get_portfolio_value()
	}
	if SimulationManager.confirm_trade(hold_trade):
		_status_label.text = "Position held for this cycle."

func _close_review_popup() -> void:
	_review_popup.visible = false

func _start_input_attention() -> void:
	_input_attention_active = true
	_input_attention_on = false
	_quantity_input.modulate = Color(1, 1, 1, 1)
	_pulse_input_attention()

func _pulse_input_attention() -> void:
	while _input_attention_active and visible and _quantity_input.text.strip_edges().is_empty():
		_quantity_input.modulate = Color(1.0, 0.95, 0.55, 1.0) if _input_attention_on else Color(1.0, 1.0, 1.0, 1.0)
		_input_attention_on = not _input_attention_on
		await get_tree().create_timer(INPUT_PULSE_SPEED).timeout
	_quantity_input.modulate = Color(1, 1, 1, 1)

func _stop_input_attention() -> void:
	_input_attention_active = false
	_input_attention_on = false
	_quantity_input.modulate = Color(1, 1, 1, 1)

func _update_cash_display() -> void:
	_buying_power_label.text = "$%.2f" % SimulationManager.get_cash()

func _update_position_display() -> void:
	var shares: float = SimulationManager.get_shares(_selected_ticker)
	_position_label.text = "Position %.4f shares" % shares

func _update_portfolio_value() -> void:
	var value: float = SimulationManager.get_portfolio_value()
	_estimate_label.text = "$%.2f" % value

func _style_button(button: Button, bg_color: Color, text_color: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(1.0, 1.0, 1.0, 0.12)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_right = 4
	normal.corner_radius_bottom_left = 4

	var hover: StyleBoxFlat = normal.duplicate()
	hover.border_color = Color(1.0, 1.0, 1.0, 0.25)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = bg_color.lightened(0.1)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)

func _set_button_state(button: Button, bg_color: Color, text_color: Color) -> void:
	_style_button(button, bg_color, text_color)

func _elapsed_decision_time() -> float:
	if _trade_start_us <= 0:
		return 0.0
	return (Time.get_ticks_usec() - _trade_start_us) / 1000000.0

func _format_currency(value: float) -> String:
	return "$%s" % _format_number(value)

func _format_shares(value: float) -> String:
	return "%.4f" % value

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
