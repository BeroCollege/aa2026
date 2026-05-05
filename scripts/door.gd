extends Area2D

var is_open: bool = false

func _ready() -> void:
	add_to_group("doors")
	_update_visual()

func toggle() -> void:
	is_open = not is_open
	_update_visual()

func force_close() -> void:
	is_open = false
	_update_visual()

func _update_visual() -> void:
	var panel := $Panel as Sprite2D
	if panel:
		var base := "res://assets/blockpack/"
		panel.texture = load(base + ("door_open.png" if is_open else "door_closed.png"))
