extends Area2D

@export var wood_yield: int = 5
@export var hits_required: int = 4

var _hits_taken: int = 0

func _ready() -> void:
	add_to_group("resource_nodes")
	z_index = 1

func gather(selected_tool: String = "", gather_power: float = 1.0) -> Dictionary:
	var effective_power := gather_power
	if selected_tool == "axe":
		effective_power *= 1.8
	_hits_taken += maxi(1, int(round(effective_power)))
	_play_hit_feedback()
	if _hits_taken < hits_required:
		return {
			"done": false,
			"amount": 0,
			"kind": "wood",
			"progress": float(_hits_taken) / float(hits_required),
		}
	queue_free()
	return {"done": true, "amount": wood_yield, "kind": "wood", "progress": 1.0}

func _play_hit_feedback() -> void:
	var trunk := $Trunk as Sprite2D
	var trunk_upper := $TrunkUpper as Sprite2D
	var leaves_a := $LeavesLeft as Sprite2D
	var leaves_b := $LeavesMid as Sprite2D
	var leaves_c := $LeavesRight as Sprite2D
	var leaves_top := $LeavesTop as Sprite2D
	var nodes := [trunk, trunk_upper, leaves_a, leaves_b, leaves_c, leaves_top]
	for n in nodes:
		if n:
			n.modulate = Color(1.0, 0.92, 0.82, 1.0)
	var tween := create_tween()
	tween.tween_interval(0.08)
	tween.finished.connect(func() -> void:
		for n in nodes:
			if n:
				n.modulate = Color(1, 1, 1, 1)
	)
