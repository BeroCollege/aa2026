class_name GameSfx
extends RefCounted

const BUS_SFX := &"SFX"

const MINE_HIT := preload("res://assets/audio/sfx/mine_hit.wav")
const BOB_BITE := preload("res://assets/audio/sfx/bob_bite.wav")
const UI_CLICK := preload("res://assets/audio/sfx/ui_click.wav")
const BOB_MODE_ANGRY := preload("res://assets/audio/sfx/bob_mode_angry.wav")
const CRAFT_OPEN := preload("res://assets/audio/sfx/craft_open.wav")
const PLACE_BLOCK := preload("res://assets/audio/sfx/place_block.wav")


static func play_ui(parent: Node, stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null or parent == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = BUS_SFX
	player.stream = stream
	player.volume_db = volume_db
	parent.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


static func play_at(
	parent: Node,
	stream: AudioStream,
	world_pos: Vector2,
	volume_db: float = 0.0
) -> void:
	if stream == null or parent == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.bus = BUS_SFX
	player.stream = stream
	player.volume_db = volume_db
	player.global_position = world_pos
	parent.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
