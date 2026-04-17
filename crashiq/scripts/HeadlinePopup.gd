class_name HeadlinePopup
extends Control

@onready var _breaking: Label = %BreakingLabel
@onready var _headline: RichTextLabel = %HeadlineText
@onready var _subtext: Label = %SubtextText
@onready var _countdown: Label = %CountdownLabel

func _ready() -> void:
	visible = false
	reset_view()

func reset_view() -> void:
	visible = false
	modulate.a = 1.0
	_breaking.visible = true
	_breaking.modulate.a = 1.0
	_breaking.text = "BREAKING:"
	_headline.visible = true
	_headline.text = ""
	_headline.visible_characters = 0
	_subtext.visible = true
	_subtext.text = ""
	_subtext.modulate.a = 0.0
	_countdown.visible = true
	_countdown.text = ""
	_countdown.modulate.a = 0.0

func dismiss() -> void:
	reset_view()
