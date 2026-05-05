extends Node2D

@export var max_monsters: int = 6
@export var spawn_interval: float = 3.0
@export var spawner_enabled: bool = false

var _timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _manager
var _player: Node2D
var _monster_scene := preload("res://scenes/Monster.tscn")

func _ready() -> void:
	_rng.randomize()
	_manager = get_tree().get_first_node_in_group("game_manager")
	_player = get_tree().get_first_node_in_group("player") as Node2D

func _process(delta: float) -> void:
	if not spawner_enabled:
		return
	if not _manager or not _manager.is_night:
		return
	_timer += delta
	if _timer < spawn_interval:
		return
	_timer = 0.0

	var count := get_tree().get_nodes_in_group("monsters").size()
	if count >= max_monsters:
		return
	_spawn_monster()

func _spawn_monster() -> void:
	if not _player:
		return
	var monster := _monster_scene.instantiate() as CharacterBody2D
	monster.add_to_group("monsters")
	var offset := Vector2(_rng.randf_range(-280.0, 280.0), _rng.randf_range(-160.0, 160.0))
	if offset.length() < 120.0:
		offset = offset.normalized() * 120.0
	monster.global_position = _player.global_position + offset
	add_child(monster)
