class_name CandlestickChart
extends Control

signal chart_info_requested(ticker: String)

@export var ticker: String = "CIQM"
@export var etf_description: String = ""
@export var etf_context: String = ""
@export var pulse_speed: float = 3.0
@export var pulse_radius_base: float = 4.5
@export var pulse_radius_amp: float = 2.2
@export var color_up: Color = Color("00c805")
@export var color_down: Color = Color("ff3b30")
@export var color_bg: Color = Color("0d0d0d")
@export var color_grid: Color = Color(1, 1, 1, 0.05)
@export var color_label: Color = Color(1, 1, 1, 0.85)
@export var color_label_dim: Color = Color(1, 1, 1, 0.35)
@export var color_border: Color = Color(1, 1, 1, 0.10)
@export var color_reference: Color = Color(1, 1, 1, 0.30)

@export var price_font: Font

var _is_focused: bool = false
var _pulse_t: float = 0.0
var _override_prices: Array[float] = []
var full_data: Array[float] = []
var visible_points: int = 0
var reveal_speed: float = 20.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	SimulationManager.cycle_started.connect(_queue_redraw_safe)
	SimulationManager.trade_confirmed.connect(_queue_redraw_safe)
	SimulationManager.cycle_complete.connect(_queue_redraw_safe)
	SimulationManager.trading_opened.connect(_queue_redraw_safe)
	queue_redraw()

func _process(delta: float) -> void:
	_pulse_t += delta * pulse_speed
	if visible_points < full_data.size():
		visible_points += int(reveal_speed * delta)
		visible_points = mini(visible_points, full_data.size())
	queue_redraw()

func _draw() -> void:
	var width: float = size.x
	var height: float = size.y
	var chart_top: float = 0.0
	var chart_height: float = height

	draw_rect(Rect2(0, 0, width, height), color_bg)

	draw_rect(Rect2(0, chart_top, width, chart_height), color_border, false, 1.0)
	if _is_focused:
		draw_rect(Rect2(1, chart_top + 1, width - 2, chart_height - 2), Color(color_up, 0.18), false, 2.0)

	var prices: Array[float] = []
	for override_price in _override_prices:
		prices.append(float(override_price))
	if prices.is_empty():
		var history: Array = SimulationManager.get_price_history(ticker)
		for history_price in history:
			prices.append(float(history_price))
	if prices.is_empty():
		prices.append(SimulationManager.get_price(ticker))
	elif prices[prices.size() - 1] != SimulationManager.get_price(ticker):
		prices.append(SimulationManager.get_price(ticker))
	if not full_data.is_empty():
		prices.clear()
		for sliced_price in full_data.slice(0, visible_points):
			prices.append(float(sliced_price))

	if prices.size() < 2:
		return

	var min_price: float = INF
	var max_price: float = -INF
	for price in prices:
		min_price = min(min_price, price)
		max_price = max(max_price, price)

	var span: float = maxf(max_price - min_price, 0.01)
	min_price -= span * 0.10
	max_price += span * 0.10
	span = max_price - min_price

	var font: Font = price_font if price_font else ThemeDB.fallback_font
	for index in range(1, 4):
		var fraction: float = float(index) / 4.0
		var grid_price: float = min_price + span * fraction
		var y: float = chart_top + chart_height * (1.0 - fraction)
		draw_line(Vector2(0, y), Vector2(width, y), color_grid, 1.0)
		draw_string(font, Vector2(4, y - 3), "$%.2f" % grid_price, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color_label_dim)

	var points: PackedVector2Array = PackedVector2Array()
	for index in range(prices.size()):
		var x: float = width * float(index) / float(prices.size() - 1)
		var y: float = chart_top + chart_height * (1.0 - (prices[index] - min_price) / span)
		points.append(Vector2(x, clampf(y, chart_top, chart_top + chart_height)))

	var change: float = SimulationManager.get_cycle_change(ticker)
	var line_color: Color = color_up if change >= 0.0 else color_down

	var fill_points: PackedVector2Array = PackedVector2Array()
	fill_points.append(Vector2(0, chart_top + chart_height))
	for point in points:
		fill_points.append(point)
	fill_points.append(Vector2(width, chart_top + chart_height))
	draw_colored_polygon(fill_points, Color(line_color, 0.13))
	draw_polyline(points, line_color, 1.5)

	var total_history: Array = SimulationManager.get_price_history(ticker)
	var points_per_cycle: int = 40
	var completed_cycles: int = SimulationManager.current_cycle - 1
	var cycle_labels: Array = ["C1", "C2", "C3", "C4", "C5"]
	var marker_color: Color = Color(Color("ff3b30"), 0.75)

	for cycle_index in range(completed_cycles):
		var boundary_index: int = points_per_cycle + cycle_index
		if boundary_index >= prices.size():
			break
		var marker_x: float = width * float(boundary_index) / float(prices.size() - 1)
		draw_line(
			Vector2(marker_x, chart_top + 30.0),
			Vector2(marker_x, chart_top + chart_height - 28.0),
			marker_color,
			1.2
		)
		var label: String = cycle_labels[cycle_index] if cycle_index < cycle_labels.size() else ""
		if not label.is_empty():
			draw_string(
				font,
				Vector2(marker_x + 3.0, chart_top + chart_height - 22.0),
				label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				10,
				marker_color
			)
			var marker_price: float = prices[boundary_index]
			draw_string(
				font,
				Vector2(marker_x + 3.0, chart_top + chart_height - 11.0),
				"$%.0f" % marker_price,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				10,
				Color(1, 1, 1, 0.38)
			)

	var open_price: float = SimulationManager.get_cycle_open_price(ticker)
	if open_price > 0.0 and span > 0.0:
		var open_y: float = chart_top + chart_height * (1.0 - (open_price - min_price) / span)
		open_y = clampf(open_y, chart_top, chart_top + chart_height)
		var dash_width: float = 6.0
		var gap_width: float = 4.0
		var x_pos: float = 0.0
		while x_pos < width:
			var dash_end: float = minf(x_pos + dash_width, width)
			draw_line(
				Vector2(x_pos, open_y),
				Vector2(dash_end, open_y),
				color_reference,
				1.0
			)
			x_pos += dash_width + gap_width
		var label_text: String = "$%.2f" % open_price
		var label_x: float = width - 44.0
		draw_string(
			font,
			Vector2(label_x, open_y - 3.0),
			label_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			9,
			color_reference
		)

	var last_index: int = visible_points - 1
	if full_data.is_empty():
		last_index = prices.size() - 1
	last_index = clampi(last_index, 0, prices.size() - 1)
	var last_price: float = prices[last_index]
	var latest_point: Vector2 = Vector2(
		width * float(last_index) / float(prices.size() - 1),
		chart_top + chart_height * (1.0 - (last_price - min_price) / span)
	)
	latest_point.y = clampf(latest_point.y, chart_top, chart_top + chart_height)
	var pulse_radius: float = pulse_radius_base + sin(_pulse_t) * pulse_radius_amp
	draw_circle(latest_point, pulse_radius * 2.8, Color(line_color, 0.12))
	draw_circle(latest_point, pulse_radius * 1.7, Color(line_color, 0.22))
	draw_circle(latest_point, pulse_radius, line_color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_is_focused = true
			BehaviorTracker.record_info_panel_opened(ticker)
			chart_info_requested.emit(ticker)

func set_chart_focused(focused: bool) -> void:
	_is_focused = focused

func set_data(price_history: Array[float]) -> void:
	_override_prices = []
	full_data = []
	for price in price_history:
		var parsed_price: float = float(price)
		_override_prices.append(parsed_price)
		full_data.append(parsed_price)
	visible_points = 1
	if _override_prices.is_empty():
		return
	queue_redraw()

func _queue_redraw_safe(_arg_a = null, _arg_b = null) -> void:
	queue_redraw()
