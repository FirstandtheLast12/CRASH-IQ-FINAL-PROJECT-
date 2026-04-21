class_name RadarChartControl
extends Control

# ─── Pathway order (clockwise from top) ─────────────────────────────────────
var KEYS: Array[String] = [
	"EXPEDIENT", "ANALYTICAL", "VALUE_DRIVEN",
	"RULING_GUIDE", "REVISIONIST", "GLOBAL",
]
var LABELS: Array[String] = [
	"EXPEDIENT", "ANALYTICAL", "VALUE\nDRIVEN",
	"RULING\nGUIDE", "REVISIONIST", "GLOBAL",
]

@export var color_web:     Color = Color(1, 1, 1, 0.10)
@export var color_spoke:   Color = Color(1, 1, 1, 0.18)
@export var color_fill:    Color = Color(0.0, 0.784, 0.02, 0.22)
@export var color_outline: Color = Color(0.0, 0.784, 0.02, 0.90)
@export var color_dot:     Color = Color(0.0, 0.784, 0.02, 1.0)
@export var color_label:   Color = Color(1, 1, 1, 0.70)
@export var color_dim:     Color = Color(1, 1, 1, 0.25)
@export var label_pad:     float = 30.0
@export var ring_count:    int   = 4
@export var font_size_lbl: int   = 10

var _amplitudes: Dictionary = {
	"EXPEDIENT": 0.0, "ANALYTICAL": 0.0, "VALUE_DRIVEN": 0.0,
	"RULING_GUIDE": 0.0, "REVISIONIST": 0.0, "GLOBAL": 0.0,
}

var _dominant: String = ""
var _pulse_t: float = 0.0

func set_amplitudes(amps: Dictionary) -> void:
	for k in _amplitudes:
		_amplitudes[k] = amps.get(k, 0.0)
	queue_redraw()

func set_dominant(pathway: String) -> void:
	_dominant = pathway
	_pulse_t = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if _dominant == "EXPEDIENT" and _amplitudes.get("EXPEDIENT", 0.0) > 0.0:
		_pulse_t += delta * 3.0
		queue_redraw()

func _draw() -> void:
	var cx: float  = size.x * 0.5
	var cy: float  = size.y * 0.5
	var r: float   = minf(cx, cy) - label_pad - 6.0
	var n: int     = KEYS.size()
	var font: Font = ThemeDB.fallback_font

	var exp_idx: int   = KEYS.find("EXPEDIENT")
	var exp_active: bool = _dominant == "EXPEDIENT" and _amplitudes.get("EXPEDIENT", 0.0) > 0.0
	var pulse_a: float  = 0.60 + 0.40 * sin(_pulse_t)
	var color_exp: Color = Color(1.0, 0.267, 0.267, pulse_a)

	# ── Reference rings ───────────────────────────────────────────────────
	for ring in range(1, ring_count + 1):
		var frac: float = float(ring) / float(ring_count)
		var ring_pts: PackedVector2Array = PackedVector2Array()
		for i in n:
			var a: float = -PI * 0.5 + i * TAU / float(n)
			ring_pts.append(Vector2(cx + cos(a) * r * frac, cy + sin(a) * r * frac))
		draw_polyline(ring_pts, color_web, 1.0, true)
		var pct_str: String = "%d%%" % roundi(frac * 100)
		draw_string(font, Vector2(cx + r * frac + 3, cy - 4),
					pct_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color_dim)

	# ── Spokes ────────────────────────────────────────────────────────────
	for i in n:
		var a: float = -PI * 0.5 + i * TAU / float(n)
		var spoke_c: Color = color_spoke
		if exp_active and i == exp_idx:
			spoke_c = Color(1.0, 0.267, 0.267, 0.45 * pulse_a)
		draw_line(Vector2(cx, cy),
				  Vector2(cx + cos(a) * r, cy + sin(a) * r),
				  spoke_c, 1.0)

	# ── Amplitude polygon ─────────────────────────────────────────────────
	var poly: PackedVector2Array = PackedVector2Array()
	for i in n:
		var a:   float = -PI * 0.5 + i * TAU / float(n)
		var raw: float = _amplitudes.get(KEYS[i], 0.0)
		var amp: float = clampf(raw if (_dominant.is_empty() or KEYS[i] == _dominant) else 0.0, 0.0, 1.0)
		poly.append(Vector2(cx + cos(a) * r * amp, cy + sin(a) * r * amp))

	draw_colored_polygon(poly, color_fill)

	if exp_active:
		# Draw outline segment-by-segment so EXPEDIENT edges can be red
		for i in n:
			var next_i: int  = (i + 1) % n
			var seg_c: Color = color_outline
			var seg_w: float = 2.0
			if i == exp_idx or next_i == exp_idx:
				seg_c = color_exp
				seg_w = 2.5
			draw_line(poly[i], poly[next_i], seg_c, seg_w)
		# Dots — EXPEDIENT pulsing red, others normal
		for i in n:
			if i == exp_idx:
				var dot_r: float = 4.0 + 2.0 * sin(_pulse_t * 1.5)
				draw_circle(poly[i], dot_r, color_exp)
			else:
				draw_circle(poly[i], 4.0, color_dot)
	else:
		draw_polyline(poly, color_outline, 2.0, true)
		for pt in poly:
			draw_circle(pt, 4.0, color_dot)

	# ── Axis labels ───────────────────────────────────────────────────────
	for i in n:
		var a:      float  = -PI * 0.5 + i * TAU / float(n)
		var lx:     float  = cx + cos(a) * (r + label_pad)
		var ly:     float  = cy + sin(a) * (r + label_pad)
		var text:   String = LABELS[i]
		var lbl_c:  Color  = color_exp if (exp_active and i == exp_idx) else color_label
		var lines:  PackedStringArray = text.split("\n")
		var line_h: float  = float(font_size_lbl) + 3.0
		var block_h: float = lines.size() * line_h
		var start_y: float = ly - block_h * 0.5 + float(font_size_lbl)
		for li in lines.size():
			var lw: float = font.get_string_size(
				lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_lbl).x
			draw_string(font, Vector2(lx - lw * 0.5, start_y + li * line_h),
						lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1,
						font_size_lbl, lbl_c)

	# ── Center dot ────────────────────────────────────────────────────────
	if exp_active:
		var center_r: float = 4.0 + 1.5 * sin(_pulse_t * 1.5)
		draw_circle(Vector2(cx, cy), center_r, color_exp)
	else:
		draw_circle(Vector2(cx, cy), 4.0, color_dot)
