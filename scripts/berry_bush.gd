extends Area2D

## Ground food that regrows after harvest (bush stays; cooldown before next pick).

const TEX_RIPE := preload("res://assets/food/berry_bush_ripe.png")
const TEX_HARVESTED := preload("res://assets/food/berry_bush_harvested.png")
const GROUND_SINK_PX := 4.0

@export var base_food_yield: int = 2
@export var regrow_seconds: float = 12.0
@export var hoe_bonus_food: int = 1

var _regrow_remaining: float = 0.0

func _ready() -> void:
	add_to_group("resource_nodes")
	add_to_group("berry_bushes")
	z_index = 1
	_update_visual()

func _process(delta: float) -> void:
	if _regrow_remaining <= 0.0:
		return
	_regrow_remaining = maxf(0.0, _regrow_remaining - delta)
	if _regrow_remaining <= 0.0:
		_update_visual()

func is_ripe() -> bool:
	return _regrow_remaining <= 0.0

func gather(selected_tool: String = "", _gather_power: float = 1.0) -> Dictionary:
	if _regrow_remaining > 0.0:
		var regen_progress := 1.0 - clampf(_regrow_remaining / maxf(0.001, regrow_seconds), 0.0, 1.0)
		return {
			"done": true,
			"amount": 0,
			"kind": "food",
			"progress": regen_progress,
			"message": "Berries are regrowing...",
		}
	var amount := base_food_yield
	if selected_tool == "hoe":
		amount += hoe_bonus_food
	_regrow_remaining = regrow_seconds
	_update_visual()
	_play_hit_feedback()
	return {"done": true, "amount": amount, "kind": "food", "progress": 1.0}

func _update_visual() -> void:
	var sprite := $Sprite as Sprite2D
	if not sprite:
		return
	sprite.texture = TEX_RIPE if is_ripe() else TEX_HARVESTED
	sprite.modulate = Color.WHITE
	_align_sprite_feet_to_tile_top(sprite)

func _align_sprite_feet_to_tile_top(sprite: Sprite2D) -> void:
	var tex := sprite.texture as Texture2D
	if tex == null:
		return
	# Root sits on surface tile top (y=0); centered sprite: shift up by half scaled height,
	# then sink a few pixels so the bush sits slightly into the ground.
	var half_h := float(tex.get_height()) * sprite.scale.y * 0.5
	sprite.position.y = -half_h + GROUND_SINK_PX

func _play_hit_feedback() -> void:
	var sprite := $Sprite as Sprite2D
	if not sprite:
		return
	var tween := create_tween()
	var base_scale := sprite.scale
	sprite.modulate = Color(1.0, 0.88, 0.55, 1.0)
	tween.tween_property(sprite, "scale", base_scale * 1.12, 0.06)
	tween.tween_property(sprite, "scale", base_scale, 0.10)
	tween.finished.connect(func() -> void: _update_visual())
