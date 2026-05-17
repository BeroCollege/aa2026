extends Area2D

@export var yield_amount: int = 2
@export var regrow_seconds: float = 14.0

var _ready_to_harvest: bool = true
var _timer: float = 0.0

func _ready() -> void:
	add_to_group("crops")
	_update_visual()

func _process(delta: float) -> void:
	if _ready_to_harvest:
		return
	_timer -= delta
	if _timer <= 0.0:
		_ready_to_harvest = true
		_update_visual()

func harvest(with_hoe: bool = false) -> Dictionary:
	if not _ready_to_harvest:
		return {"food": 0}
	_ready_to_harvest = false
	_timer = regrow_seconds
	_update_visual()
	var food_gain := yield_amount + (1 if with_hoe else 0)
	return {"food": food_gain}

func _update_visual() -> void:
	var sprite := $Sprite as Sprite2D
	if not sprite:
		return
	sprite.modulate = Color(1, 1, 1, 1) if _ready_to_harvest else Color(0.45, 0.45, 0.45, 1)
