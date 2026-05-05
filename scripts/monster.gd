extends CharacterBody2D

@export var speed: float = 120.0
@export var touch_damage_per_second: float = 22.0

var _player: Node2D
var _manager
var _life_time: float = 22.0
var _health: float = 40.0

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_manager = get_tree().get_first_node_in_group("game_manager")
	var body := $Body as Sprite2D
	if body:
		body.texture = load("res://assets/blockpack/character_wizard.png")
		body.modulate = Color(1.0, 0.6, 0.6, 1.0)

func _physics_process(delta: float) -> void:
	_life_time -= delta
	if _life_time <= 0.0:
		queue_free()
		return
	if not _manager or not _manager.is_night:
		queue_free()
		return
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return

	var to_player := _player.global_position - global_position
	velocity = to_player.normalized() * speed
	move_and_slide()

	if to_player.length() < 44.0:
		_manager.damage_player(touch_damage_per_second * delta)

func receive_damage(amount: float) -> void:
	_health -= amount
	var body := $Body as Sprite2D
	if body:
		body.modulate = Color(1.0, 0.72, 0.72, 1.0)
		var tween := create_tween()
		tween.tween_interval(0.08)
		tween.finished.connect(func() -> void:
			if is_instance_valid(body):
				body.modulate = Color(1.0, 0.6, 0.6, 1.0))
	if _health <= 0.0:
		queue_free()
