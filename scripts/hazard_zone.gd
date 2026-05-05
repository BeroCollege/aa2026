extends Area2D

@export var damage_per_second: float = 18.0

var _player_inside: bool = false
var _manager

func _ready() -> void:
	add_to_group("hazards")
	_manager = get_tree().get_first_node_in_group("game_manager")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if _player_inside and _manager:
		_manager.damage_player(damage_per_second * delta)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
