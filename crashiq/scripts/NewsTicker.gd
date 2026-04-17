class_name NewsTicker
extends Control

@export var scroll_speed: float          = 90.0
@export var font_size:    int            = 12
@export var bg_color:     Color          = Color(0.071, 0.071, 0.071, 1)
@export var text_color:   Color          = Color(1, 1, 1, 0.65)
@export var separator:    String         = "    ◆    "
@export var messages:     PackedStringArray = PackedStringArray()

var _scroll_x:    float = 0.0
var _full_text:   String = ""
var _text_width:  float = 0.0
var _font:        Font

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_build_text()
	_scroll_x = size.x
	resized.connect(_on_resized)

func _on_resized() -> void:
	if _scroll_x < size.x:
		_scroll_x = size.x

## Replace the scrolling messages at runtime.
func set_messages(msgs: PackedStringArray) -> void:
	messages = msgs
	_build_text()
	_scroll_x = size.x

func _build_text() -> void:
	if messages.is_empty():
		_full_text   = ""
		_text_width  = 0.0
		return
	var joined: String = separator.join(messages) + separator
	_full_text  = joined
	_text_width = _font.get_string_size(
		_full_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x

func _process(delta: float) -> void:
	if _full_text.is_empty():
		return
	_scroll_x -= scroll_speed * delta
	if _scroll_x < -_text_width:
		_scroll_x = size.x
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), bg_color)
	if _full_text.is_empty():
		return
	var baseline_y: float = (size.y + float(font_size)) * 0.5
	draw_string(_font, Vector2(_scroll_x, baseline_y),
				_full_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				font_size, text_color)
