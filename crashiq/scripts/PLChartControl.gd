class_name PLChartControl
extends Control

@export var color_line:   Color = Color(0.0, 0.784, 0.02, 1.0)
@export var color_fill:   Color = Color(0.0, 0.784, 0.02, 0.12)
@export var color_down:   Color = Color(1.0, 0.231, 0.188, 1.0)
@export var color_ref:    Color = Color(1, 1, 1, 0.22)
@export var color_label:  Color = Color(1, 1, 1, 0.50)
@export var pad:          float = 32.0

var _values: Array[float] = []   # index 0 = start, 1-5 = cycle ends
var _starting_cash: float = 0.0

func set_data(history: Array, starting_cash: float) -> void:
	_starting_cash = starting_cash
	_values.clear()
	_values.append(starting_cash)
	for entry in history:
		_values.append(entry.get("portfolio_value", starting_cash))
	queue_redraw()

func _draw() -> void:
	if _values.size() < 2:
		return

	var w: float     = size.x
	var h: float     = size.y
	var font: Font   = ThemeDB.fallback_font

	# ── Y scale ───────────────────────────────────────────────────────────
	var pmin: float = _starting_cash
	var pmax: float = _starting_cash
	for v in _values:
		pmin = minf(pmin, v)
		pmax = maxf(pmax, v)
	var span: float = maxf(pmax - pmin, 1.0)
	pmin -= span * 0.12
	pmax += span * 0.12
	span = pmax - pmin

	var chart_w: float = w - pad * 2.0
	var chart_h: float = h - pad * 2.0
	var n: int         = _values.size()  # up to 6
	var x_step: float  = chart_w / float(n - 1)

	# ── Screen points ─────────────────────────────────────────────────────
	var pts: PackedVector2Array = PackedVector2Array()
	for i in n:
		var x: float = pad + i * x_step
		var y: float = pad + chart_h * (1.0 - (_values[i] - pmin) / span)
		pts.append(Vector2(x, y))

	# ── Determine line color (gain or loss vs start) ──────────────────────
	var final_val: float = _values[_values.size() - 1]
	var line_col: Color  = color_line if final_val >= _starting_cash else color_down
	var fill_col: Color  = color_fill if final_val >= _starting_cash else Color(color_down, 0.12)

	# ── Filled area ───────────────────────────────────────────────────────
	var fill_pts: PackedVector2Array = PackedVector2Array()
	fill_pts.append(Vector2(pts[0].x, pad + chart_h))
	for pt in pts:
		fill_pts.append(pt)
	fill_pts.append(Vector2(pts[pts.size() - 1].x, pad + chart_h))
	draw_colored_polygon(fill_pts, fill_col)

	# ── Starting-cash reference line ──────────────────────────────────────
	var ref_y: float = pad + chart_h * (1.0 - (_starting_cash - pmin) / span)
	draw_dashed_line(Vector2(pad, ref_y), Vector2(w - pad, ref_y),
					 color_ref, 1.0, 5.0)
	draw_string(font, Vector2(pad + 2, ref_y - 4),
				"START  $%.0f" % _starting_cash,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color_ref)

	# ── Line ─────────────────────────────────────────────────────────────
	draw_polyline(pts, line_col, 2.0)

	# ── Dots + labels ─────────────────────────────────────────────────────
	for i in n:
		draw_circle(pts[i], 4.5, line_col)
		var x_lbl: float = pts[i].x
		# Cycle label below x axis
		var lbl: String = "S" if i == 0 else "C%d" % i
		draw_string(font, Vector2(x_lbl - 5, pad + chart_h + 14),
					lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color_label)
		# Value above dot
		var val_str: String = "$%.0f" % _values[i]
		var val_w: float = font.get_string_size(val_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		draw_string(font, Vector2(x_lbl - val_w * 0.5, pts[i].y - 7),
					val_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, line_col)
