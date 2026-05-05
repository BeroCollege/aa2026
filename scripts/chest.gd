extends Area2D

@export var stash_amount: int = 8
var is_broken: bool = false

func _ready() -> void:
	add_to_group("chests")
	_update_visual()

func loot() -> int:
	if is_broken:
		return 0
	var amount := stash_amount
	stash_amount = 0
	_update_visual()
	return amount

func break_chest() -> int:
	if is_broken:
		return 0
	is_broken = true
	var dropped := stash_amount / 2
	stash_amount = 0
	_update_visual()
	return dropped

func _update_visual() -> void:
	var body := $Body as Sprite2D
	if not body:
		return
	var base := "res://assets/blockpack/"
	if is_broken:
		body.texture = load(base + "chest_broken.png")
		body.modulate = Color(0.45, 0.45, 0.45, 1.0)
	elif stash_amount > 0:
		body.texture = load(base + "chest_full.png")
		body.modulate = Color(1, 1, 1, 1)
	else:
		body.texture = load(base + "chest_empty.png")
		body.modulate = Color(1, 1, 1, 1)
