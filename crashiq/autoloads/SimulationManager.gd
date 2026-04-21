extends Node

signal difficulty_set(tier: String, cash: float, timer: float)
signal cycle_started(cycle_num: int, cycle_data: CrashCycle)
signal headline_shown(headline: String, subtext: String)
signal trading_opened(time_limit: float)
signal trade_confirmed(trade_data: Dictionary)
signal cycle_complete(cycle_num: int, portfolio_value: float)
signal liquidation_triggered(final_data: Dictionary)
signal simulation_complete(final_data: Dictionary)

const TOTAL_CYCLES: int = 5
const LIQUIDATION_THRESHOLD: float = 1.0

var DIFFICULTY: Dictionary = {
	"Student": {"cash": 500.0, "timer": 0.0},
	"Young Pro": {"cash": 5000.0, "timer": 0.0},
	"Mid-career": {"cash": 25000.0, "timer": 0.0},
	"Veteran": {"cash": 100000.0, "timer": 0.0}
}

var ETF_ORDER: Array[String] = ["CIQM", "CIQE", "CIQD", "CIQS", "CIQG"]

var ETF_DATA: Dictionary = {
	"CIQM": {
		"name": "CIQ Broad Market",
		"short_name": "Broad Market",
		"description": "US total market analog",
		"context": "PRIMARY EFFECT: System-wide panic selling\nINVESTOR BEHAVIOR: Investors rapidly exit positions",
		"start_price": 100.0,
		"cycle_changes": [-0.08, 0.05, -0.18, -0.12, -0.25]
	},
	"CIQE": {
		"name": "CIQ Energy Fund",
		"short_name": "Energy",
		"description": "Oil and gas producers",
		"context": "PRIMARY EFFECT: Oil supply disruption\nINVESTOR BEHAVIOR: Aggressive buying on oil spikes",
		"start_price": 80.0,
		"cycle_changes": [0.12, 0.35, 0.20, -0.08, 0.40]
	},
	"CIQD": {
		"name": "CIQ Defense Fund",
		"short_name": "Defense",
		"description": "Defense contractors",
		"context": "PRIMARY EFFECT: Military escalation increases\nINVESTOR BEHAVIOR: Institutional inflows into defense",
		"start_price": 90.0,
		"cycle_changes": [0.15, -0.08, 0.25, 0.30, 0.15]
	},
	"CIQS": {
		"name": "CIQ Safe Haven",
		"short_name": "Safe Haven",
		"description": "Gold and Treasury analog",
		"context": "PRIMARY EFFECT: Fear dominates markets\nINVESTOR BEHAVIOR: Flight to safety assets",
		"start_price": 70.0,
		"cycle_changes": [0.06, 0.12, 0.10, 0.08, 0.20]
	},
	"CIQG": {
		"name": "CIQ Global Shipping",
		"short_name": "Shipping",
		"description": "Ocean freight and logistics",
		"context": "PRIMARY EFFECT: Global trade disruption\nINVESTOR BEHAVIOR: Investors dump logistics exposure",
		"start_price": 60.0,
		"cycle_changes": [-0.05, -0.22, -0.15, 0.15, -0.30]
	}
}

var ETF_START_PRICE: Dictionary = {}
var ETF_NAMES: Dictionary = {}
var ETF_CYCLE_CHANGES: Dictionary = {}

enum State {
	START,
	BRIEFING,
	HEADLINE,
	TRADING,
	CYCLE_RESULT,
	LIQUIDATED,
	PROFILE
}

var current_state: State = State.START

var selected_difficulty: String = ""
var starting_cash: float = 0.0
var decision_timer: float = 0.0

var current_cycle: int = 0
var can_advance: bool = false
var has_advanced: bool = false
var cash: float = 0.0
var holdings: Dictionary = {}
var etf_prices: Dictionary = {}
var price_history: Dictionary = {}
var cycle_history: Array = []
var cycle_open_prices: Dictionary = {}

var _cycles: Array[CrashCycle] = []
var _trading_timer: float = 0.0
var _timer_running: bool = false

func _is_simulation_scene_active() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var scene: Node = tree.current_scene
	if scene == null:
		return false
	return scene.name == "SimulationScreen"

func _ready() -> void:
	_build_etf_indexes()
	_build_cycles()
	_reset_holdings()
	_reset_etf_prices()

func _process(_delta: float) -> void:
	if not _is_simulation_scene_active():
		return
	if _timer_running and current_state == State.TRADING:
		pass

func reset() -> void:
	current_cycle = 0
	can_advance = false
	has_advanced = false
	current_state = State.START
	selected_difficulty = ""
	starting_cash = 0.0
	decision_timer = 0.0
	cash = 0.0
	_trading_timer = 0.0
	_timer_running = false
	cycle_history.clear()
	cycle_open_prices.clear()
	_reset_holdings()
	_reset_etf_prices()

func set_difficulty(tier: String) -> void:
	assert(tier in DIFFICULTY, "Unknown difficulty tier: " + tier)
	current_cycle = 0
	can_advance = false
	has_advanced = false
	cycle_history.clear()
	cycle_open_prices.clear()
	selected_difficulty = tier
	starting_cash = DIFFICULTY[tier]["cash"]
	decision_timer = DIFFICULTY[tier]["timer"]
	cash = starting_cash
	_trading_timer = 0.0
	_timer_running = false
	_reset_holdings()
	_reset_etf_prices()
	current_state = State.BRIEFING
	difficulty_set.emit(tier, starting_cash, decision_timer)

func start_next_cycle() -> void:
	if not _is_simulation_scene_active():
		return
	assert(current_cycle < TOTAL_CYCLES, "All cycles already complete.")
	current_cycle += 1
	reset_cycle_input_state()
	_snapshot_cycle_open_prices()
	current_state = State.HEADLINE
	var cycle_data: CrashCycle = _cycles[current_cycle - 1]
	cycle_started.emit(current_cycle, cycle_data)
	headline_shown.emit(cycle_data.headline, cycle_data.subtext)

func open_trading_phase() -> void:
	if not _is_simulation_scene_active():
		return
	current_state = State.TRADING
	lock_cycle_advance()
	_trading_timer = decision_timer
	_timer_running = false
	trading_opened.emit(decision_timer)

func confirm_trade(trade_data: Dictionary) -> bool:
	assert(current_state == State.TRADING, "Trade confirmed outside TRADING state.")
	var validation: Dictionary = validate_trade(trade_data)
	if not validation.get("ok", false):
		return false

	var action: String = String(trade_data.get("trade_action", "HOLD")).to_upper()
	var normalized_trade: Dictionary = _normalized_trade_data(trade_data)

	if action == "BUY" or action == "SELL":
		_apply_trade(normalized_trade)
		var portfolio_value: float = get_portfolio_value()
		normalized_trade["portfolio_value_after"] = portfolio_value
		trade_confirmed.emit(normalized_trade)
		if portfolio_value <= LIQUIDATION_THRESHOLD:
			_emit_liquidation()
		return true

	# HOLD / DONE — ends the cycle
	var portfolio_value: float = get_portfolio_value()
	normalized_trade["portfolio_value_after"] = portfolio_value
	trade_confirmed.emit(normalized_trade)
	cycle_history.append({
		"cycle": current_cycle,
		"portfolio_value": portfolio_value,
		"trade_data": normalized_trade
	})
	current_state = State.CYCLE_RESULT
	cycle_complete.emit(current_cycle, portfolio_value)
	if current_cycle == TOTAL_CYCLES:
		_finish_simulation()
	return true

func reset_cycle_input_state() -> void:
	can_advance = false
	has_advanced = false

func enable_cycle_input_state() -> void:
	can_advance = true
	has_advanced = false

func lock_cycle_advance() -> void:
	has_advanced = true
	can_advance = false

func validate_trade(trade_data: Dictionary) -> Dictionary:
	var action: String = String(trade_data.get("trade_action", "HOLD")).to_upper()
	var ticker: String = String(trade_data.get("etf_traded", ""))
	var quantity_mode: String = String(trade_data.get("quantity_mode", "DOLLARS")).to_upper()
	var quantity: float = maxf(float(trade_data.get("quantity", trade_data.get("dollar_amount", 0.0))), 0.0)
	var price: float = get_etf_price(ticker)

	if action == "HOLD":
		return {"ok": true, "message": ""}

	if ticker.is_empty() or not ETF_DATA.has(ticker):
		return {"ok": false, "message": "Select an ETF before placing an order."}
	if quantity <= 0.0:
		return {"ok": false, "message": "Enter a quantity greater than zero."}
	if price <= 0.0:
		return {"ok": false, "message": "This ETF price is unavailable right now."}

	var shares: float = quantity if quantity_mode == "SHARES" else quantity / price
	var estimated_total: float = shares * price

	match action:
		"BUY":
			if estimated_total - cash > 0.0001:
				return {"ok": false, "message": "Not enough buying power for this order."}
		"SELL":
			if shares - get_shares(ticker) > 0.0001:
				return {"ok": false, "message": "You cannot sell more shares than you own."}
		_:
			return {"ok": false, "message": "Unsupported trade action."}

	return {
		"ok": true,
		"message": "",
		"shares": shares,
		"estimated_total": estimated_total
	}

func get_trading_time_remaining() -> float:
	return 0.0

func get_portfolio_value() -> float:
	var total: float = cash
	for ticker in ETF_ORDER:
		total += get_position_value(ticker)
	return total

func get_position_value(ticker: String) -> float:
	return get_shares(ticker) * get_etf_price(ticker)

func get_etf_price(ticker: String) -> float:
	return float(etf_prices.get(ticker, 0.0))

func get_price(ticker: String) -> float:
	return get_etf_price(ticker)

func get_price_history(ticker: String) -> Array:
	var history: Array = price_history.get(ticker, [])
	return history.duplicate()

func get_cycle_open_price(ticker: String) -> float:
	return float(cycle_open_prices.get(ticker, 0.0))

func get_cycle_change(ticker: String) -> float:
	if current_cycle == 0:
		return 0.0
	return ETF_CYCLE_CHANGES[ticker][current_cycle - 1]

func get_shares(ticker: String) -> float:
	return float(holdings.get(ticker, 0.0))

func get_cash() -> float:
	return cash

func get_cycle_data(cycle_num: int) -> CrashCycle:
	assert(cycle_num >= 1 and cycle_num <= TOTAL_CYCLES)
	return _cycles[cycle_num - 1]

func get_cycle_count() -> int:
	return TOTAL_CYCLES

func get_etf_order() -> Array[String]:
	return ETF_ORDER.duplicate()

func get_etf_name(ticker: String) -> String:
	return String(ETF_DATA.get(ticker, {}).get("name", ticker))

func get_etf_short_name(ticker: String) -> String:
	return String(ETF_DATA.get(ticker, {}).get("short_name", ticker))

func get_etf_description(ticker: String) -> String:
	return String(ETF_DATA.get(ticker, {}).get("description", ""))

func get_etf_context(ticker: String) -> String:
	return String(ETF_DATA.get(ticker, {}).get("context", ""))

func get_etf_behavior_sections(ticker: String) -> Dictionary:
	var sections: Dictionary = {
		"primary": "",
		"behavior": ""
	}
	var context_text: String = get_etf_context(ticker)
	var lines: PackedStringArray = context_text.split("\n")
	for line in lines:
		if line.begins_with("PRIMARY EFFECT:"):
			sections["primary"] = line.trim_prefix("PRIMARY EFFECT:").strip_edges()
		elif line.begins_with("INVESTOR BEHAVIOR:"):
			sections["behavior"] = line.trim_prefix("INVESTOR BEHAVIOR:").strip_edges()
	if sections["primary"] == "" and not context_text.is_empty():
		sections["primary"] = context_text
	return sections

func get_market_intro_data() -> Array:
	var result: Array = []
	for ticker in ETF_ORDER:
		var data: Dictionary = ETF_DATA[ticker]
		result.append({
			"ticker": ticker,
			"name": data["name"],
			"price": "$%.2f" % float(data["start_price"]),
			"behavior": data["context"]
		})
	return result

func get_order_estimate(ticker: String, quantity_mode: String, quantity: float) -> Dictionary:
	var price: float = get_etf_price(ticker)
	var normalized_mode: String = quantity_mode.to_upper()
	var shares: float = 0.0
	var total: float = 0.0
	if price > 0.0 and quantity > 0.0:
		if normalized_mode == "SHARES":
			shares = quantity
			total = quantity * price
		else:
			total = quantity
			shares = quantity / price
	return {
		"shares": shares,
		"total": total,
		"price": price
	}

func _build_etf_indexes() -> void:
	ETF_START_PRICE.clear()
	ETF_NAMES.clear()
	ETF_CYCLE_CHANGES.clear()
	for ticker in ETF_ORDER:
		ETF_START_PRICE[ticker] = ETF_DATA[ticker]["start_price"]
		ETF_NAMES[ticker] = ETF_DATA[ticker]["name"]
		ETF_CYCLE_CHANGES[ticker] = ETF_DATA[ticker]["cycle_changes"]

func _reset_holdings() -> void:
	holdings.clear()
	for ticker in ETF_ORDER:
		holdings[ticker] = 0.0

func _reset_etf_prices() -> void:
	etf_prices.clear()
	price_history.clear()
	for ticker in ETF_ORDER:
		etf_prices[ticker] = ETF_START_PRICE[ticker]
	price_history["CIQM"] = _generate_price_series(100.0, -8.0)
	price_history["CIQE"] = _generate_price_series(80.0, 12.0)
	price_history["CIQD"] = _generate_price_series(90.0, 15.0)
	price_history["CIQS"] = _generate_price_series(70.0, 6.0)
	price_history["CIQG"] = _generate_price_series(60.0, -5.0)

func _snapshot_cycle_open_prices() -> void:
	for ticker in ETF_ORDER:
		var start_price: float = etf_prices[ticker]
		var change: float = ETF_CYCLE_CHANGES[ticker][current_cycle - 1]
		cycle_open_prices[ticker] = start_price
		etf_prices[ticker] = start_price * (1.0 + change)
		price_history[ticker].append(etf_prices[ticker])

func _generate_price_series(start_price: float, percent_change: float) -> Array:
	var points: int = 40
	var prices: Array = []
	var target_price: float = start_price * (1.0 + percent_change / 100.0)
	var current: float = start_price

	for i in range(points):
		var progress: float = float(i) / points
		var trend: float = lerpf(start_price, target_price, progress)
		var noise: float = randf_range(-0.015, 0.015) * start_price
		current = trend + noise
		current = maxf(current, 1.0)
		prices.append(current)

	return prices

func _normalized_trade_data(trade_data: Dictionary) -> Dictionary:
	var normalized: Dictionary = trade_data.duplicate(true)
	var action: String = String(normalized.get("trade_action", "HOLD")).to_upper()
	var ticker: String = String(normalized.get("etf_traded", ""))
	var quantity_mode: String = String(normalized.get("quantity_mode", "DOLLARS")).to_upper()
	var quantity: float = maxf(float(normalized.get("quantity", normalized.get("dollar_amount", 0.0))), 0.0)
	var estimate: Dictionary = get_order_estimate(ticker, quantity_mode, quantity)

	normalized["trade_action"] = action
	normalized["quantity_mode"] = quantity_mode
	normalized["quantity"] = quantity
	normalized["shares"] = estimate.get("shares", 0.0)
	normalized["price"] = estimate.get("price", 0.0)
	normalized["estimated_total"] = estimate.get("total", 0.0)
	normalized["dollar_amount"] = estimate.get("total", 0.0)
	if not normalized.has("portfolio_value_before"):
		normalized["portfolio_value_before"] = get_portfolio_value()
	if not normalized.has("time_to_decide"):
		normalized["time_to_decide"] = 0.0
	if not normalized.has("stop_loss_set"):
		normalized["stop_loss_set"] = false
	if not normalized.has("perception_severity"):
		normalized["perception_severity"] = _get_perception_severity()
	# info_panel_opened / info_panel_switches / etfs_checked are tracked by
	# BehaviorTracker and must NOT be defaulted here — the merge in
	# BehaviorTracker._on_trade_confirmed uses overwrite=true, so defaulting
	# them to false/0/[] here would clobber live tracker state.
	if not normalized.has("portfolio_value_after"):
		normalized["portfolio_value_after"] = 0.0
	return normalized

func _apply_trade(trade_data: Dictionary) -> void:
	var action: String = trade_data.get("trade_action", "HOLD")
	var ticker: String = trade_data.get("etf_traded", "")
	if action == "HOLD" or ticker.is_empty():
		return

	var shares: float = float(trade_data.get("shares", 0.0))
	var price: float = float(trade_data.get("price", get_etf_price(ticker)))
	var total: float = shares * price

	if action == "BUY":
		cash -= total
		holdings[ticker] += shares
	elif action == "SELL":
		holdings[ticker] -= shares
		cash += total

func _auto_hold() -> void:
	var auto_trade: Dictionary = {
		"cycle": current_cycle,
		"time_to_decide": decision_timer,
		"info_panel_opened": false,
		"info_panel_switches": 0,
		"etfs_checked": [],
		"trade_action": "HOLD",
		"etf_traded": "",
		"stop_loss_set": false,
		"perception_severity": _get_perception_severity(),
		"quantity_mode": "DOLLARS",
		"quantity": 0.0,
		"dollar_amount": 0.0,
		"portfolio_value_before": get_portfolio_value(),
		"portfolio_value_after": get_portfolio_value()
	}
	confirm_trade(auto_trade)

func _emit_liquidation() -> void:
	current_state = State.LIQUIDATED
	var final_data: Dictionary = {
		"difficulty": selected_difficulty,
		"starting_cash": starting_cash,
		"final_value": get_portfolio_value(),
		"cycle_history": cycle_history,
		"etf_prices": etf_prices.duplicate(),
		"liquidated_cycle": current_cycle
	}
	liquidation_triggered.emit(final_data)

func _get_perception_severity() -> float:
	if current_cycle == 0:
		return 0.0
	var change: float = ETF_CYCLE_CHANGES["CIQM"][current_cycle - 1]
	return clampf(abs(change) / 0.40, 0.0, 1.0)

func _finish_simulation() -> void:
	current_state = State.PROFILE
	var final_data: Dictionary = {
		"difficulty": selected_difficulty,
		"starting_cash": starting_cash,
		"final_value": get_portfolio_value(),
		"cycle_history": cycle_history,
		"etf_prices": etf_prices.duplicate()
	}
	simulation_complete.emit(final_data)

func _build_cycles() -> void:
	_cycles.clear()

	var c1 := CrashCycle.new()
	c1.cycle_number = 1
	c1.headline = "BREAKING: US and Israel launch Operation Epic Fury - airstrikes hit Iranian command, navy, and nuclear sites"
	c1.subtext = "Initial shock. Energy and defense lead. Broad market bleeds. Watch for dip buyers."
	c1.etf_changes = {"CIQM": -0.08, "CIQE": 0.12, "CIQD": 0.15, "CIQS": 0.06, "CIQG": -0.05}
	_cycles.append(c1)

	var c2 := CrashCycle.new()
	c2.cycle_number = 2
	c2.headline = "BREAKING: Iran closes Strait of Hormuz - tankers under missile attack. 20% of global oil supply cut off"
	c2.subtext = "Hormuz closes — oil explodes. Broad market bounces as dip buyers enter. Defense profit-taking hits. Did you sell too early?"
	c2.etf_changes = {"CIQM": -0.15, "CIQE": 0.35, "CIQD": 0.08, "CIQS": 0.12, "CIQG": -0.18}
	_cycles.append(c2)

	var c3 := CrashCycle.new()
	c3.cycle_number = 3
	c3.headline = "BREAKING: China warns US to stand down - Iran strikes Saudi oil facilities. Kuwait and UAE infrastructure hit"
	c3.subtext = "China enters. The bounce is over. Broad market resumes its fall. Defense surges again on ground war expectations."
	c3.etf_changes = {"CIQM": -0.22, "CIQE": 0.48, "CIQD": 0.20, "CIQS": 0.18, "CIQG": -0.25}
	_cycles.append(c3)

	var c4 := CrashCycle.new()
	c4.cycle_number = 4
	c4.headline = "BREAKING: US 82nd Airborne deployed - ground invasion begins to reopen Strait of Hormuz by force"
	c4.subtext = "Boots on the ground. Defense peaks. Energy reverses — invasion signals Hormuz may reopen. Shipping surprises to the upside."
	c4.etf_changes = {"CIQM": -0.30, "CIQE": 0.60, "CIQD": 0.35, "CIQS": 0.22, "CIQG": -0.32}
	_cycles.append(c4)

	var c5 := CrashCycle.new()
	c5.cycle_number = 5
	c5.headline = "BREAKING: Iran mines Persian Gulf - global recession declared. Chinese naval vessels enter conflict zone"
	c5.subtext = "Gulf mined. Recession confirmed. Energy rips again. Shipping collapses. Maximum fear. Every decision you made led here."
	c5.etf_changes = {"CIQM": -0.40, "CIQE": 0.75, "CIQD": 0.28, "CIQS": 0.30, "CIQG": -0.38}
	_cycles.append(c5)
