class_name CrisisRing
extends Control

@export var ring_color:   Color = Color(1.0, 0.18, 0.18, 1.0)
@export var border_width: float = 5.0

var alpha: float = 0.0   # set by SimulationScreen.gd; drives opacity

func _draw() -> void:
	if alpha < 0.01:
		return
	var c:  Color = Color(ring_color.r, ring_color.g, ring_color.b, alpha)
	var w:  float = size.x
	var h:  float = size.y
	var bw: float = border_width
	draw_rect(Rect2(0,      0,      w,  bw), c)
	draw_rect(Rect2(0,      h - bw, w,  bw), c)
	draw_rect(Rect2(0,      bw,     bw, h - bw * 2.0), c)
	draw_rect(Rect2(w - bw, bw,     bw, h - bw * 2.0), c)
