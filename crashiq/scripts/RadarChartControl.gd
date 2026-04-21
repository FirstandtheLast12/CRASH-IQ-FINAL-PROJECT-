class_name RadarChartControl
extends Control

# ─── Pathway order (clockwise from top) ─────────────────────────────────────
var KEYS: Array[String] = [
	"EXPEDIENT", "ANALYTICAL", "VALUE_DRIVEN", "REVISIONIST",
]
var LABELS: Array[String] = [
	"EXPEDIENT", "ANALYTICAL", "VALUE\nDRIVEN", "REVISIONIST",
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

# Per-pathway highlight colors. Pathways not listed fall back to the default
# green outline with no pulse animation.
var PATHWAY_COLORS: Dictionary = {
	"EXPEDIENT":    Color(1.0, 0.267, 0.267),  # red   — panic / speed
	"ANALYTICAL":   Color(0.267, 0.6,  1.0),   # blue  — data-driven / strategic
	"VALUE_DRIVEN": Color(1.0, 0.843, 0.0),    # gold  — consistent conviction
	"REVISIONIST":  Color(0.0, 1.0,   0.314),  # green — contrarian / signal reader
}

var _amplitudes: Dictionary = {
	"EXPEDIENT": 0.0, "ANALYTICAL": 0.0, "VALUE_DRIVEN": 0.0, "REVISIONIST": 0.0,
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
	if PATHWAY_COLORS.has(_dominant) and _amplitudes.get(_dominant, 0.0) > 0.0:
		_pulse_t += delta * 3.0
		queue_redraw()

func _draw() -> void:
	var cx: float  = size.x * 0.5
	var cy: float  = size.y * 0.5
	var r: float   = minf(cx, cy) - label_pad - 6.0
	var n: int     = KEYS.size()
	var font: Font = ThemeDB.fallback_font

	var dom_idx: int     = KEYS.find(_dominant)
	var dom_active: bool = PATHWAY_COLORS.has(_dominant) and _amplitudes.get(_dominant, 0.0) > 0.0
	var pulse_a: float   = 0.60 + 0.40 * sin(_pulse_t)
	var base_dom: Color  = PATHWAY_COLORS.get(_dominant, Color(0, 1, 0))
	var color_dom: Color = Color(base_dom.r, base_dom.g, base_dom.b, pulse_a)

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
		if dom_active and i == dom_idx:
			spoke_c = Color(base_dom.r, base_dom.g, base_dom.b, 0.45 * pulse_a)
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

	if dom_active:
		# Draw outline segment-by-segment so edges touching the dominant
		# vertex get the pathway color and a thicker stroke.
		for i in n:
			var next_i: int  = (i + 1) % n
			var seg_c: Color = color_outline
			var seg_w: float = 2.0
			if i == dom_idx or next_i == dom_idx:
				seg_c = color_dom
				seg_w = 2.5
			draw_line(poly[i], poly[next_i], seg_c, seg_w)
		# Dots — dominant pulses in pathway color, others draw normally
		for i in n:
			if i == dom_idx:
				var dot_r: float = 4.0 + 2.0 * sin(_pulse_t * 1.5)
				draw_circle(poly[i], dot_r, color_dom)
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
		var lbl_c:  Color  = color_dom if (dom_active and i == dom_idx) else color_label
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
	if dom_active:
		var center_r: float = 4.0 + 1.5 * sin(_pulse_t * 1.5)
		draw_circle(Vector2(cx, cy), center_r, color_dom)
	else:
		draw_circle(Vector2(cx, cy), 4.0, color_dot)
