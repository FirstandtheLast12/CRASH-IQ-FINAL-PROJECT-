extends Node

signal pathway_updated(amplitudes: Dictionary)

var _cycle_amplitudes: Array[Dictionary] = []
var _decision_log: Array[Dictionary] = []
var _decisions_by_cycle: Dictionary = {}

var _amplitude_sums: Dictionary = {
	"EXPEDIENT": 0.0,
	"ANALYTICAL": 0.0,
	"VALUE_DRIVEN": 0.0,
	"RULING_GUIDE": 0.0,
	"REVISIONIST": 0.0,
	"GLOBAL": 0.0
}

var _current: Dictionary = {}
var _prev_etf_traded: String = ""

func _ready() -> void:
	SimulationManager.cycle_started.connect(_on_cycle_started)
	SimulationManager.trading_opened.connect(_on_trading_opened)
	SimulationManager.trade_confirmed.connect(_on_trade_confirmed)

func record_info_panel_opened(ticker: String) -> void:
	if _current.is_empty():
		return
	if not _current["info_panel_opened"]:
		_current["info_panel_opened"] = true
		_current["first_action"] = "INFO"
	_current["info_panel_switches"] += 1
	if ticker not in _current["etfs_checked"]:
		_current["etfs_checked"].append(ticker)

func record_headline_viewed() -> void:
	if _current.is_empty():
		return
	_current["info_panel_switches"] += 1
	_current["headline_reread"] = true

func get_final_amplitudes() -> Dictionary:
	var cycle_count: int = _cycle_amplitudes.size()
	if cycle_count == 0:
		return _amplitude_sums.duplicate()

	var result: Dictionary = {}
	for key in _amplitude_sums:
		result[key] = _amplitude_sums[key] / float(cycle_count)
	return result

func get_dominant_pathway() -> String:
	var amplitudes: Dictionary = get_final_amplitudes()
	var best_key: String = "EXPEDIENT"
	var best_value: float = -1.0
	for key in amplitudes:
		if amplitudes[key] >= best_value:
			best_value = amplitudes[key]
			best_key = key
	return best_key

func get_learning_delta() -> float:
	if _cycle_amplitudes.size() < 2:
		return 0.0

	var first: Dictionary = _cycle_amplitudes[0]
	var last: Dictionary = _cycle_amplitudes[_cycle_amplitudes.size() - 1]
	var keys: Array = ["ANALYTICAL", "VALUE_DRIVEN", "RULING_GUIDE", "REVISIONIST", "GLOBAL"]
	var first_sum: float = 0.0
	var last_sum: float = 0.0
	for key in keys:
		first_sum += first.get(key, 0.0)
		last_sum += last.get(key, 0.0)
	return last_sum - first_sum

func get_cycle_amplitudes() -> Array:
	return _cycle_amplitudes.duplicate(true)

func get_decision_log() -> Array:
	return _decision_log.duplicate(true)

func get_cycle_decisions() -> Array:
	var ordered: Array[Dictionary] = []
	for cycle_num in range(1, SimulationManager.get_cycle_count() + 1):
		if _decisions_by_cycle.has(cycle_num):
			ordered.append(_decisions_by_cycle[cycle_num].duplicate(true))
	return ordered

func get_cycle_decision(cycle_num: int) -> Dictionary:
	if not _decisions_by_cycle.has(cycle_num):
		return {}
	return _decisions_by_cycle[cycle_num].duplicate(true)

func get_tpm_classification() -> String:
	var dominant: String = get_dominant_pathway()
	match dominant:
		"EXPEDIENT":
			return "Impulse Trader"
		"ANALYTICAL":
			return "Strategic"
		"VALUE_DRIVEN":
			return "Systematic"
		"RULING_GUIDE":
			return "Methodical"
		"REVISIONIST":
			return "Contrarian"
		"GLOBAL":
			return "Adaptive"
		_:
			return "Adaptive"

func get_tpm_explanation() -> String:
	var classification: String = get_tpm_classification()
	match classification:
		"Impulse Trader":
			return "You moved fast and skipped analysis. Decisions fired before the full picture settled — speed dominated over deliberation under pressure."
		"Strategic":
			return "You checked the data before acting and took your time. Your pattern points to calculated positioning driven by information rather than panic."
		"Systematic":
			return "You returned to the same ETF cycle after cycle. Consistency under pressure is a signal of rule-based conviction rather than emotional reaction."
		"Methodical":
			return "You reviewed multiple ETFs and cross-checked information before every decision. Full deliberation under crisis pressure defines your throughput pathway."
		"Contrarian":
			return "You bought into the crash. Reading against the crowd and acting on macro context under maximum stress is a rare and high-conviction behavioral signal."
		"Adaptive":
			return "Your behavior shifted across cycles, mixing macro-awareness, timing, and directional positioning as the crisis escalated. No single pathway dominated."
		_:
			return "Your behavior adapted across the crisis. You mixed defense, patience, and directional conviction as market conditions escalated."

func get_tpm_metrics() -> Dictionary:
	var buy_count: int = 0
	var sell_count: int = 0
	var hold_count: int = 0
	var total_time: float = 0.0
	var info_open_count: int = 0

	for decision in _decision_log:
		var action: String = String(decision.get("trade_action", "HOLD")).to_upper()
		match action:
			"BUY":
				buy_count += 1
			"SELL":
				sell_count += 1
			_:
				hold_count += 1
		total_time += float(decision.get("time_to_decide", 0.0))
		if bool(decision.get("info_panel_opened", false)):
			info_open_count += 1

	var total_decisions: int = _decision_log.size()
	var avg_time: float = total_time / float(total_decisions) if total_decisions > 0 else 0.0
	var info_open_rate: float = float(info_open_count) / float(total_decisions) if total_decisions > 0 else 0.0

	return {
		"buy_count": buy_count,
		"sell_count": sell_count,
		"hold_count": hold_count,
		"avg_time": avg_time,
		"info_open_rate": info_open_rate,
		"risk_tolerance": _get_risk_tolerance_label(buy_count, sell_count, hold_count),
		"reaction_speed": _get_reaction_speed_label(avg_time),
		"decision_count": total_decisions
	}

func reset() -> void:
	_cycle_amplitudes.clear()
	_decision_log.clear()
	_decisions_by_cycle.clear()
	for key in _amplitude_sums:
		_amplitude_sums[key] = 0.0
	_current = {}
	_prev_etf_traded = ""

func _on_cycle_started(_cycle_num: int, _cycle_data: Object) -> void:
	print("[BT] _on_cycle_started fired — cycle=%d" % _cycle_num)
	_current = {
		"cycle": SimulationManager.current_cycle,
		"time_to_decide": 0.0,
		"info_panel_opened": false,
		"info_panel_switches": 0,
		"etfs_checked": [],
		"headline_reread": false,
		"first_action": "HEADLINE",
		"trade_action": "HOLD",
		"etf_traded": "",
		"stop_loss_set": false,
		"perception_severity": SimulationManager._get_perception_severity(),
		"quantity_mode": "DOLLARS",
		"quantity": 0.0,
		"dollar_amount": 0.0,
		"portfolio_value_before": SimulationManager.get_portfolio_value(),
		"portfolio_value_after": 0.0
	}

func _on_trading_opened(_time_limit: float) -> void:
	# _current already initialized in _on_cycle_started (headline phase)
	# Just refresh the portfolio snapshot now that cycle prices are applied
	if not _current.is_empty():
		_current["portfolio_value_before"] = SimulationManager.get_portfolio_value()

func _on_trade_confirmed(trade_data: Dictionary) -> void:
	if _current.is_empty():
		return

	_current.merge(trade_data, true)
	_current["portfolio_value_after"] = SimulationManager.get_portfolio_value()
	var cycle_num: int = int(_current.get("cycle", SimulationManager.current_cycle))
	var decision_entry: Dictionary = {
		"cycle": cycle_num,
		"selected_etf": _current.get("etf_traded", ""),
		"etf_traded": _current.get("etf_traded", ""),
		"trade_action": _current.get("trade_action", "HOLD"),
		"timing": _current.get("time_to_decide", 0.0),
		"time_to_decide": _current.get("time_to_decide", 0.0),
		"info_panel_opened": _current.get("info_panel_opened", false),
		"context": "Cycle %d" % cycle_num,
		"portfolio_value_before": _current.get("portfolio_value_before", 0.0),
		"portfolio_value_after": _current.get("portfolio_value_after", 0.0)
	}
	_record_cycle_decision(decision_entry)

	var amplitudes: Dictionary = _score_cycle(_current)
	_cycle_amplitudes.append(amplitudes)
	for key in _amplitude_sums:
		_amplitude_sums[key] += amplitudes.get(key, 0.0)

	_prev_etf_traded = _current.get("etf_traded", "")
	_current = {}
	pathway_updated.emit(get_final_amplitudes())

func _record_cycle_decision(decision_entry: Dictionary) -> void:
	var cycle_num: int = int(decision_entry.get("cycle", 0))
	if cycle_num <= 0:
		return
	_decisions_by_cycle[cycle_num] = decision_entry.duplicate(true)
	_rebuild_decision_log()

func _rebuild_decision_log() -> void:
	_decision_log.clear()
	for cycle_num in range(1, SimulationManager.get_cycle_count() + 1):
		if _decisions_by_cycle.has(cycle_num):
			_decision_log.append(_decisions_by_cycle[cycle_num].duplicate(true))

func _score_cycle(cycle_data: Dictionary) -> Dictionary:
	var info_opened: bool = cycle_data.get("info_panel_opened", false)
	var info_switches: int = cycle_data.get("info_panel_switches", 0)
	var checked_etfs: Array = cycle_data.get("etfs_checked", [])
	var action: String = cycle_data.get("trade_action", "HOLD")
	var ticker: String = cycle_data.get("etf_traded", "")
<<<<<<< HEAD
	print("[BT] SCORE_INPUT C%d — info_opened=%s info_switches=%d etfs_checked=%s action=%s ticker=%s prev=%s" % [
		SimulationManager.current_cycle, info_opened, info_switches,
		str(checked_etfs), action, ticker, _prev_etf_traded
	])
=======
	print("[BT] Cycle %d | info_opened=%s | time=%.2fs | action=%s | ticker=%s" % [
		cycle_data.get("cycle", 0), str(info_opened), time_to_decide, action, ticker
	])
	var reread_headline: bool = cycle_data.get("headline_reread", false)
>>>>>>> 0f05d15beff61510ac9312cdec37e3f41d684596

	var broad_market_change: float = SimulationManager.ETF_CYCLE_CHANGES["CIQM"][
		SimulationManager.current_cycle - 1
	]
	var is_crash_cycle: bool = broad_market_change < 0.0
	var bought_during_crash: bool = action == "BUY" and is_crash_cycle

	# EXPEDIENT: no research at all — reacted to headline blind
	var expedient: float = 1.0 if not info_opened else 0.0

<<<<<<< HEAD
	# REVISIONIST: opened panel AND bought into the crash (contrarian)
	var revisionist: float = 1.0 if (info_opened and bought_during_crash) else 0.0

	# ANALYTICAL: opened panel but did NOT buy into a crash (data-driven, non-contrarian)
	# Blocked in the same cycle REVISIONIST fires — they are mutually exclusive
	var analytical: float = 1.0 if (revisionist == 0.0 and info_opened) else 0.0

	# VALUE_DRIVEN: same ETF traded as previous cycle — consistent thesis
=======
>>>>>>> 0f05d15beff61510ac9312cdec37e3f41d684596
	var value_driven: float = 0.0
	if not ticker.is_empty() and action != "HOLD" and ticker == _prev_etf_traded:
		value_driven = 1.0

	# RULING_GUIDE: opened all 5 ETF panels, most thorough review
	var ruling_guide: float = 1.0 if (
		info_switches >= 2 and checked_etfs.size() == SimulationManager.get_etf_order().size()
	) else 0.0

	# GLOBAL: macro-aware — traded rising macro ETF after checking 3+ panels
	var macro_trade: bool = false
	if ticker in ["CIQE", "CIQD", "CIQS"]:
		macro_trade = SimulationManager.ETF_CYCLE_CHANGES[ticker][
			SimulationManager.current_cycle - 1
		] > 0.0
	var global_amplitude: float = 1.0 if (info_switches >= 3 and macro_trade) else 0.0

<<<<<<< HEAD
	print("[BT] SCORE_RESULT C%d — EXP=%.1f ANA=%.1f VAL=%.1f RUL=%.1f REV=%.1f GLO=%.1f" % [
		SimulationManager.current_cycle,
		expedient, analytical, value_driven, ruling_guide, revisionist, global_amplitude
	])
=======
	# ANALYTICAL scores only when info was opened but no more-specific info-based
	# pathway also fired that cycle. VALUE_DRIVEN (same ETF), REVISIONIST, RULING_GUIDE,
	# and GLOBAL all carry their own information-stage signals that take precedence.
	var analytical: float = 0.0
	if info_opened and value_driven == 0.0 and revisionist == 0.0 and ruling_guide == 0.0 and global_amplitude == 0.0:
		analytical = 1.0

>>>>>>> 0f05d15beff61510ac9312cdec37e3f41d684596
	return {
		"EXPEDIENT": expedient,
		"ANALYTICAL": analytical,
		"VALUE_DRIVEN": value_driven,
		"RULING_GUIDE": ruling_guide,
		"REVISIONIST": revisionist,
		"GLOBAL": global_amplitude
	}

func _get_risk_tolerance_label(buy_count: int, sell_count: int, hold_count: int) -> String:
	if buy_count > sell_count and buy_count > hold_count:
		return "High"
	if hold_count >= buy_count and hold_count >= sell_count:
		return "Low"
	return "Moderate"

func _get_reaction_speed_label(avg_time: float) -> String:
	if avg_time <= 3.0:
		return "Fast"
	if avg_time <= 7.0:
		return "Measured"
	return "Deliberate"
