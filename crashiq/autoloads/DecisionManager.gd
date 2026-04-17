extends Node

signal decision_processed(result)

var current_cash: float = 0.0

var profile: Dictionary = {
	"aggressive": 0,
	"analytical": 0,
	"conservative": 0,
	"reactive": 0
}

func _ready() -> void:
	current_cash = 5000.0

func process_decision(choice: String) -> void:
	var delta: float = 0.0
	var risk: float = 0.0

	match choice:
		"defense":
			delta = randf_range(500.0, 1200.0)
			risk = 0.7
			profile["analytical"] += 1
		"energy":
			delta = randf_range(300.0, 1500.0)
			risk = 0.8
			profile["analytical"] += 1
		"liquid":
			delta = randf_range(-200.0, 200.0)
			risk = 0.2
			profile["conservative"] += 1
		"risk":
			delta = randf_range(-1500.0, 2000.0)
			risk = 1.0
			profile["aggressive"] += 1
		"wait":
			delta = randf_range(-300.0, 300.0)
			risk = 0.1
			profile["reactive"] += 1

	current_cash += delta

	emit_signal("decision_processed", {
		"delta": delta,
		"cash": current_cash,
		"risk": risk,
		"choice": choice
	})

func get_primary_profile() -> String:
	var max_key: String = "aggressive"
	var max_val: int = 0

	for key in profile:
		if profile[key] > max_val:
			max_val = profile[key]
			max_key = key

	return max_key
