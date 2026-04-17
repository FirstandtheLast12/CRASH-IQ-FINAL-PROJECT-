extends VBoxContainer

signal decision_made(choice)

func _ready() -> void:
	%DefenseButton.pressed.connect(func() -> void: emit_signal("decision_made", "defense"))
	%EnergyButton.pressed.connect(func() -> void: emit_signal("decision_made", "energy"))
	%LiquidButton.pressed.connect(func() -> void: emit_signal("decision_made", "liquid"))
	%RiskButton.pressed.connect(func() -> void: emit_signal("decision_made", "risk"))
	%WaitButton.pressed.connect(func() -> void: emit_signal("decision_made", "wait"))
