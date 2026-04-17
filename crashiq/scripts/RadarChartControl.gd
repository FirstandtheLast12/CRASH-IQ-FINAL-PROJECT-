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

func set_amplitudes(amps: Dictionary) -> void:
	for k in _amplitudes:
		_amplitudes[k] = amps.get(k, 0.0)
	queue_redraw()

func _draw() -> void:
	var cx: float  = size.x * 0.5
	var cy: float  = size.y * 0.5
	var r: float   = minf(cx, cy) - label_pad - 6.0
	var n: int     = KEYS.size()
	var font: Font = ThemeDB.fallback_font

	# ── Reference rings ───────────────────────────────────────────────────
	for ring in range(1, ring_count + 1):
		var frac: float = float(ring) / float(ring_count)
		var ring_pts: PackedVector2Array = PackedVector2Array()
		for i in n:
			var a: float = -PI * 0.5 + i * TAU / float(n)
			ring_pts.append(Vector2(cx + cos(a) * r * frac, cy + sin(a) * r * frac))
		draw_polyline(ring_pts, color_web, 1.0, true)
		# Percentage label on right-side ring
		var pct_str: String = "%d%%" % roundi(frac * 100)
		draw_string(font, Vector2(cx + r * frac + 3, cy - 4),
					pct_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color_dim)

	# ── Spokes ────────────────────────────────────────────────────────────
	for i in n:
		var a: float = -PI * 0.5 + i * TAU / float(n)
		draw_line(Vector2(cx, cy),
				  Vector2(cx + cos(a) * r, cy + sin(a) * r),
				  color_spoke, 1.0)

	# ── Amplitude polygon ─────────────────────────────────────────────────
	var poly: PackedVector2Array = PackedVector2Array()
	for i in n:
		var a:   float = -PI * 0.5 + i * TAU / float(n)
		var amp: float = clampf(_amplitudes.get(KEYS[i], 0.0), 0.0, 1.0)
		poly.append(Vector2(cx + cos(a) * r * amp, cy + sin(a) * r * amp))

	draw_colored_polygon(poly, color_fill)
	draw_polyline(poly, color_outline, 2.0, true)
	for pt in poly:
		draw_circle(pt, 4.0, color_dot)

	# ── Axis labels ───────────────────────────────────────────────────────
	for i in n:
		var a:      float  = -PI * 0.5 + i * TAU / float(n)
		var lx:     float  = cx + cos(a) * (r + label_pad)
		var ly:     float  = cy + sin(a) * (r + label_pad)
		var text:   String = LABELS[i]
		var lines:  PackedStringArray = text.split("\n")
		var line_h: float  = float(font_size_lbl) + 3.0
		var block_h: float = lines.size() * line_h
		var start_y: float = ly - block_h * 0.5 + float(font_size_lbl)
		for li in lines.size():
			var lw: float = font.get_string_size(
				lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_lbl).x
			draw_string(font, Vector2(lx - lw * 0.5, start_y + li * line_h),
						lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1,
						font_size_lbl, color_label)
