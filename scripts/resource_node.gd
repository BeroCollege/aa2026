extends Area2D

@export var resource_kind: String = "wood"
@export var gather_value: int = 2
@export var gather_hits_required: int = 1

var _gather_progress: float = 0.0

func _ready() -> void:
	add_to_group("resource_nodes")
	_apply_texture()

func gather(selected_tool: String = "", gather_power: float = 1.0) -> Dictionary:
	var effective_power := gather_power
	if resource_kind == "wood" and selected_tool == "axe":
		effective_power *= 1.7
	elif resource_kind == "stone" and selected_tool == "pickaxe":
		effective_power *= 1.7
	_gather_progress += effective_power
	_play_hit_feedback()
	var need := float(gather_hits_required)
	if _gather_progress + 1e-4 < need:
		return {"done": false, "amount": 0, "kind": resource_kind, "progress": _gather_progress / need}
	queue_free()
	return {"done": true, "amount": gather_value, "kind": resource_kind, "progress": 1.0}

func _apply_texture() -> void:
	var sprite := $Sprite as Sprite2D
	if not sprite:
		return
	sprite.scale = Vector2.ONE
	match resource_kind:
		"wood":
			sprite.texture = load("res://assets/blockpack/resource_wood.png")
		"stone":
			sprite.texture = load("res://assets/tiles/stone.png")
		"food":
			sprite.texture = load("res://assets/food/berry_bush_ripe.png")
		_:
			sprite.texture = load("res://assets/tiles/dirt.png")

func _play_hit_feedback() -> void:
	var sprite := $Sprite as Sprite2D
	if not sprite:
		return
	var tween := create_tween()
	var base_scale := sprite.scale
	sprite.modulate = Color(1.0, 0.86, 0.72, 1.0)
	tween.tween_property(sprite, "scale", base_scale * 1.16, 0.06)
	tween.tween_property(sprite, "scale", base_scale, 0.10)
	tween.finished.connect(func() -> void: sprite.modulate = Color(1, 1, 1, 1))
