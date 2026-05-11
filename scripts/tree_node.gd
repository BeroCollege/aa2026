extends Area2D

@export var wood_yield: int = 5
## Overridden per variant in `_apply_variant` (small 5, classic 6, big 7 bare-hand swings).
@export var hits_required: int = 6

const TEX_FULL_TREE_BIG := preload("res://assets/decor/tree_big.png")
const TEX_FULL_TREE_SMALL := preload("res://assets/decor/tree_small.png")
const FULL_TREE_GROUND_SINK_PX := 0.0
const FULL_TREE_FEET_NUDGE_Y_SMALL := 8.0
const FULL_TREE_FEET_NUDGE_Y_BIG := 12.0

enum TreeVariant { CLASSIC = 0, SMALL = 1, BIG = 2 }
@export var variant: TreeVariant = TreeVariant.CLASSIC
@export var full_tree_scale: float = 0.42
@export var full_tree_big_scale_x_multiplier: float = 0.96

var _gather_progress: float = 0.0

func _ready() -> void:
	add_to_group("resource_nodes")
	add_to_group("trees")
	z_index = 1
	_apply_variant()

func gather(selected_tool: String = "", gather_power: float = 1.0) -> Dictionary:
	# Only the axe is a proper tree tool; every other equipped tool chops at bare-hand speed.
	var effective_power: float
	if selected_tool == "axe":
		effective_power = gather_power * 1.8
	elif selected_tool == "none" or selected_tool == "":
		effective_power = gather_power
	else:
		effective_power = 1.0
	_gather_progress += effective_power
	_play_hit_feedback()
	var need := float(hits_required)
	if _gather_progress + 1e-4 < need:
		return {
			"done": false,
			"amount": 0,
			"kind": "wood",
			"progress": _gather_progress / need,
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
	var full_tree := get_node_or_null("FullTree") as Sprite2D
	var nodes := [trunk, trunk_upper, leaves_a, leaves_b, leaves_c, leaves_top, full_tree]
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

func _apply_variant() -> void:
	match variant:
		TreeVariant.SMALL:
			hits_required = 5
		TreeVariant.BIG:
			hits_required = 7
		_:
			hits_required = 6

	var full_tree := get_node_or_null("FullTree") as Sprite2D
	var classic_nodes := [
		$Trunk as Sprite2D,
		$TrunkUpper as Sprite2D,
		$LeavesLeft as Sprite2D,
		$LeavesMid as Sprite2D,
		$LeavesRight as Sprite2D,
		$LeavesTop as Sprite2D,
	]

	var use_full := variant != TreeVariant.CLASSIC and full_tree != null
	if full_tree:
		full_tree.visible = use_full
	for n in classic_nodes:
		if n:
			n.visible = not use_full

	if not use_full:
		return

	full_tree.texture = TEX_FULL_TREE_BIG if variant == TreeVariant.BIG else TEX_FULL_TREE_SMALL
	full_tree.modulate = Color.WHITE
	var s := maxf(0.01, full_tree_scale)
	full_tree.scale = Vector2(s, s)
	if variant == TreeVariant.BIG:
		full_tree.scale.x *= maxf(0.01, full_tree_big_scale_x_multiplier)
	_align_sprite_feet_to_tile_top(full_tree)
	full_tree.position.y += FULL_TREE_FEET_NUDGE_Y_BIG if variant == TreeVariant.BIG else FULL_TREE_FEET_NUDGE_Y_SMALL

func _align_sprite_feet_to_tile_top(sprite: Sprite2D) -> void:
	var tex := sprite.texture as Texture2D
	if tex == null:
		return
	var half_h := float(tex.get_height()) * sprite.scale.y * 0.5
	sprite.position.y = -half_h + FULL_TREE_GROUND_SINK_PX
