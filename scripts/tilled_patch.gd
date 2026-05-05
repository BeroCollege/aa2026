extends Area2D

var has_crop: bool = false

func _ready() -> void:
	add_to_group("tilled_patches")
	_update_visual()

func set_has_crop(value: bool) -> void:
	has_crop = value
	_update_visual()

func _update_visual() -> void:
	var sprite := $Sprite as Sprite2D
	if sprite:
		sprite.modulate = Color(0.58, 0.45, 0.28, 1.0) if not has_crop else Color(0.40, 0.34, 0.21, 1.0)
