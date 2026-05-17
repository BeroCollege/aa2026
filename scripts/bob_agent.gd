extends CharacterBody2D

enum BobMode {
	FRIENDLY,
	ATTACK
}

@export var move_speed: float = 254.0
@export var forage_distance: float = 260.0
@export var surface_foot_offset: float = 30.0
@export var gravity_force: float = 1550.0
@export var jump_velocity: float = -495.0
@export var max_fall_speed: float = 980.0
@export var collider_half_width: float = 14.0
@export var collider_head_offset: float = -80.0
@export var body_visual_scale: float = 0.175
@export var body_width_scale: float = 1.06
@export var body_visual_y_offset: float = -18.0
@export var actor_world_z_index: int = 3
@export var walk_bob_amplitude: float = 1.45
@export var walk_bob_frequency: float = 9.2
@export var walk_tilt_amplitude: float = 0.028
@export var walk_tilt_frequency: float = 10.5
@export var walk_squash_amplitude: float = 0.0
@export var walk_baseline_offset: float = 0.7
@export var idle_bob_amplitude: float = 0.5
@export var idle_bob_frequency: float = 3.4
@export var idle_tilt_amplitude: float = 0.007
@export var idle_tilt_frequency: float = 4.3
@export var attack_lean_radians: float = 0.01
@export var mine_reach_cells_x: int = 1
@export var mine_reach_cells_up: int = 2
@export var mine_reach_cells_down: int = 1
## Cooldown after Bob’s friendly forage mine attempts (escape digs use `bob_escape_mine_cooldown`).
@export_range(0.06, 0.55, 0.01) var mine_action_cooldown: float = 0.2
## Extra damage multiplier applied only on Bob’s `try_mine_cell` calls (player unchanged).
@export_range(0.35, 4.0, 0.05) var bob_mine_damage_multiplier: float = 1.55
## When Bob’s tool does not match the tile (e.g. pickaxe on dirt), damage divisor — lower is faster (player uses 5.0).
@export_range(1.0, 8.0, 0.1) var bob_mine_wrong_tool_slowdown: float = 2.15
## Passed into tile mining as tier multiplier (clamped 1.0–2.5 inside tilemap).
@export_range(1.0, 2.5, 0.05) var bob_mine_tier_damage_mult: float = 1.28
## Cooldown after each escape dig when stuck mining toward the player.
@export_range(0.06, 0.55, 0.01) var bob_escape_mine_cooldown: float = 0.13
## Lateral stuck time before escape mining activates.
@export_range(0.12, 1.1, 0.02) var bob_escape_stuck_threshold: float = 0.4
## Consecutive escape digs before the brake cooldown applies.
@export_range(1, 10, 1) var bob_escape_mine_chain_limit: int = 3
## Cooldown applied after `bob_escape_mine_chain_limit` escape digs in a row.
@export_range(0.2, 2.0, 0.05) var bob_escape_mine_chain_brake_cooldown: float = 0.52
@export var forage_mine_interval: float = 1.05
@export var place_action_cooldown: float = 1.45
## Minimum vertical delta (player above Bob, in pixels) required before Bob will
## consider stacking blocks. Roughly 1.5 tiles — slightly above his jump reach
## (~79 px). Below this, Bob just walks/jumps; he never builds towers on flat ground.
@export var climb_place_min_vertical_delta: float = 96.0
## Maximum horizontal distance to the climb target before Bob will start stacking.
## Keeps him from building random pillars when the player is far away horizontally.
@export var climb_place_max_horizontal_distance: float = 240.0
## Roll chance for actually placing a step on a given tick (after gating).
@export var climb_place_chance: float = 0.55
@export var escape_mine_reach_cells_x: int = 2
@export var escape_mine_reach_cells_up: int = 3
@export var friendly_mode_min_seconds: float = 2.8
@export var friendly_mode_max_seconds: float = 5.8
@export var attack_mode_min_seconds: float = 7.2
@export var attack_mode_max_seconds: float = 12.5
@export var attack_mode_base_bias: float = 0.72
@export var attack_bias_early_grace_first_window: float = 16.0
@export var attack_bias_early_grace_first_penalty: float = 0.12
@export var attack_bias_early_grace_second_window: float = 38.0
@export var attack_bias_early_grace_second_penalty: float = 0.04
@export var attack_bias_hunger_threshold: float = 62.0
@export var attack_bias_hunger_bonus: float = 0.22
@export var attack_bias_low_trust_threshold: float = 55.0
@export var attack_bias_low_trust_bonus: float = 0.20
@export var attack_bias_low_energy_threshold: float = 20.0
@export var attack_bias_low_energy_penalty: float = 0.18
@export var attack_bias_sword_distance: float = 115.0
@export var attack_bias_sword_penalty: float = 0.12
@export var attack_bias_randomness: float = 0.14
@export var attack_bias_min: float = 0.28
@export var attack_bias_max: float = 0.94
@export var attack_chase_lead_distance: float = 126.0
## Extra horizontal speed fraction while chasing in ATTACK (applied on top of the 0.82–1.0 energy gate).
@export_range(0.0, 0.55, 0.01) var attack_pace_boost: float = 0.31
@export_range(1.0, 1.45, 0.01) var attack_pace_max: float = 1.30
@export var attack_annoy_distance: float = 102.0
@export var attack_annoy_damage: float = 7.8
@export var friendly_annoy_damage: float = 2.5
@export var attack_annoy_cooldown: float = 0.11
@export var friendly_annoy_cooldown: float = 0.28
@export var attack_shove_range: float = 122.0
@export var attack_shove_min_distance: float = 16.0
@export var attack_shove_strength: float = 505.0
@export var attack_shove_harass_strength_multiplier: float = 1.32
@export var attack_shove_cooldown: float = 1.38
@export var attack_shove_harass_cooldown: float = 0.68
@export var attack_shove_cooldown_floor: float = 0.44
## After sword HP damage, B.O.B. stays aggressive with faster shove/annoy bite pacing until this timer expires or the player backs off far enough.
@export_range(0.5, 18.0, 0.1) var hurt_enrage_duration_seconds: float = 8.5
## Extra attack-mode roll bias while enraged (`_select_mode`).
@export_range(0.0, 0.55, 0.01) var hurt_enrage_attack_bias_add: float = 0.42
## While enraged, do not apply `attack_bias_sword_penalty` when the player wields a sword at close range.
@export var hurt_enrage_ignore_sword_distance_penalty: bool = true
## After a damaging sword hit, keep ATTACK mode at least this long before a roll can switch out (only if Calm Totem is not active).
@export_range(0.0, 12.0, 0.1) var hurt_enrage_mode_timer_floor_seconds: float = 6.0
@export_range(1.0, 2.5, 0.05) var hurt_enrage_annoy_damage_multiplier: float = 1.72
@export_range(0.2, 1.0, 0.05) var hurt_enrage_annoy_cooldown_scale: float = 0.42
@export_range(1.0, 2.5, 0.05) var hurt_enrage_bite_damage_multiplier: float = 1.72
@export_range(0.2, 1.0, 0.05) var hurt_enrage_shove_cooldown_scale: float = 0.48
@export_range(0.0, 0.5, 0.01) var hurt_enrage_pace_boost_add: float = 0.30
## Raises bite hunger ceiling while enraged so bites proc sooner under pressure.
@export_range(0.0, 35.0, 0.5) var hurt_enrage_bite_hunger_max_bonus: float = 18.0
## While enraged, sustain timer while the player stays in melee with the sword drawn.
@export_range(40.0, 200.0, 2.0) var hurt_enrage_melee_pressure_range: float = 120.0
@export_range(0.0, 2.5, 0.05) var hurt_enrage_melee_pressure_recharge_per_second: float = 0.42
## Ends enrage when the player backs beyond this distance (cancels sustained melee pressure).
@export_range(80.0, 420.0, 4.0) var hurt_enrage_player_back_off_clear_range: float = 190.0
@export var hurt_knockback_decay: float = 940.0
@export var hurt_knockback_max_speed: float = 660.0
@export var bite_contact_range: float = 86.0
@export var bite_attack_hunger_max: float = 64.0
@export var bite_friendly_hunger_max: float = 40.0
## Continuous player damage per second while Bob is in bite range and hunger allows (`_try_bite_player`).
@export_range(2.0, 22.0, 0.1) var bite_damage_per_second: float = 12.2
@export var steering_direction_deadzone: float = 10.0
@export var steering_flip_hold_time: float = 0.11
@export var steering_accel: float = 2125.0
@export var steering_decel: float = 2620.0
@export var steering_turn_brake: float = 3400.0

@export var berry_seek_hunger_below: float = 62.0
@export var berry_seek_max_distance: float = 520.0
@export var berry_gather_distance: float = 54.0
@export var berry_gather_cooldown: float = 0.95
@export var berry_seek_speed_multiplier: float = 1.85
@export var berry_seek_speed_override: float = 0.0
@export var deny_food_player_health_ratio_threshold: float = 0.4
@export var deny_food_destroy_radius: float = 160.0
@export var deny_food_destroy_chance: float = 0.7
@export var deny_food_destroy_cooldown: float = 1.1
## Multiplier on all incoming damage (player melee, etc.). Also scales `max_health` in `_sync_max_health_from_sword_balance`, so changing this alone does **not** change committed swing count vs a matching sword hit amount.
@export_range(0.2, 1.2, 0.01) var damage_received_multiplier: float = 0.5
## Sword-hit budget at tier-matched damage: `max_health` / (sword_damage × this multiplier) ≈ this value when `receive_damage` uses the same sword damage as the sync. Raise to force spacing, terrain, and Bob pressure instead of straight-line spam.
@export_range(35.0, 220.0, 1.0) var target_sword_hits_to_kill: float = 120.0
## Extra max-HP factor per stone-tipped (or higher) sword tier from GameManager — keeps upgraded blades from collapsing the fight too fast (`get_tool_tier("sword")`).
@export_range(0.0, 0.35, 0.01) var bob_hp_bonus_per_sword_tier: float = 0.14
## Extra annoy chip + bite DPS when the player is close with sword and swinging recently (`Player.is_sword_melee_commit_recent`). Does not change sword HP math or LOS rules.
@export_range(0.0, 1.25, 0.02) var face_tank_player_damage_bonus_mult: float = 0.36
@export_range(56.0, 150.0, 2.0) var face_tank_player_max_distance: float = 100.0
@export_range(0.08, 0.42, 0.01) var face_tank_swing_recency_seconds: float = 0.24
## Only this player melee weapon reduces B.O.B. HP (must match Player.BOB_HP_LOSS_WEAPON_ID).
const PLAYER_HP_DAMAGE_WEAPON_ID := "sword"
## After HP hits zero, B.O.B. respawns off-screen delay (death only; initial spawn unchanged).
@export var death_respawn_delay_seconds: float = 5.0
## Euclidean distance from player in tile units (matches WorldTiles tile size).
@export var respawn_offset_tiles: float = 10.0

## Synced from sword damage × target_sword_hits_to_kill in _ready (inspector value is overwritten).
@export var max_health: float = 10.0
@export var health: float = 10.0
@export var hunger: float = 80.0
@export var safety: float = 100.0
@export var curiosity: float = 40.0
@export var energy: float = 85.0
@export var trust_to_player: float = 50.0
@export var affection: float = 35.0

var _mode: BobMode = BobMode.FRIENDLY
var _bite_sfx_cd: float = 0.0
var _mode_timer: float = 0.0
var _player: Node2D
var _manager
var _forage_target: Vector2
var _rng := RandomNumberGenerator.new()
var _action_text: String = "shadowing player..."
var _time_alive: float = 0.0
var _world_tiles: TileMapLayer
var _vertical_velocity: float = 0.0
var _is_grounded: bool = false
var _last_annoy_tick: float = 0.0
var _mine_cooldown_timer: float = 0.0
var _place_cooldown_timer: float = 0.0
var _forage_mine_timer: float = 0.0
var _intended_move_x: float = 0.0
var _stuck_move_timer: float = 0.0
var _escape_mine_chain: int = 0
var _shove_player_timer: float = 0.0
var _sword_scare_cd: float = 0.0
var _calm_aura_count: int = 0
var _berry_gather_cd: float = 0.0
var _deny_food_cd: float = 0.0
var _hurt_knockback_velocity: float = 0.0
var _hurt_enrage_timer: float = 0.0
var _smoothed_move_x: float = 0.0
var _horizontal_intent_sign: float = 0.0
var _intent_flip_hold_timer: float = 0.0
var _is_dead: bool = false
var _alive_collision_layer: int = 1
var _alive_collision_mask: int = 1

func _ready() -> void:
	add_to_group("bob_agent")
	z_index = actor_world_z_index
	_alive_collision_layer = collision_layer
	_alive_collision_mask = collision_mask
	_rng.randomize()
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_manager = get_tree().get_first_node_in_group("game_manager")
	_world_tiles = get_tree().current_scene.get_node("WorldTiles") as TileMapLayer
	_sync_max_health_from_sword_balance()
	health = max_health
	_pick_new_forage_target()
	_roll_mode_timer()

func _process(delta: float) -> void:
	if _is_dead:
		return
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if not _player:
			return
	_mode_timer = maxf(0.0, _mode_timer - delta)
	_last_annoy_tick = maxf(0.0, _last_annoy_tick - delta)
	_mine_cooldown_timer = maxf(0.0, _mine_cooldown_timer - delta)
	_place_cooldown_timer = maxf(0.0, _place_cooldown_timer - delta)
	_forage_mine_timer = maxf(0.0, _forage_mine_timer - delta)
	_sword_scare_cd = maxf(0.0, _sword_scare_cd - delta)
	_hurt_enrage_timer = maxf(0.0, _hurt_enrage_timer - delta)
	_bite_sfx_cd = maxf(0.0, _bite_sfx_cd - delta)
	_update_enrage_melee_pressure(delta)
	_update_needs(delta)
	_select_mode(delta)

func _physics_process(_delta: float) -> void:
	if _is_dead:
		return
	_time_alive += _delta
	_berry_gather_cd = maxf(0.0, _berry_gather_cd - _delta)
	_deny_food_cd = maxf(0.0, _deny_food_cd - _delta)
	var desired_velocity := Vector2.ZERO
	var denying_food := _mode == BobMode.ATTACK and _is_player_health_below_threshold()
	var berry_vel: Variant = null if denying_food else _try_berry_food_steering()
	if berry_vel != null:
		desired_velocity = berry_vel as Vector2
	else:
		match _mode:
			BobMode.FRIENDLY:
				desired_velocity = _move_toward_forage()
				_action_text = "friendly wandering..."
				_try_forage_mine()
			BobMode.ATTACK:
				desired_velocity = _move_toward_player(false)
				_action_text = "attack mode: annoying player"
				if denying_food:
					_try_deny_player_food()
				if _manager and _manager.can_bob_sabotage() and global_position.distance_to(_player.global_position) < 60.0:
					var stolen: int = _manager.bob_sabotage()
					if stolen > 0:
						hunger = minf(100.0, hunger + float(stolen) * 8.0)
						curiosity = maxf(0.0, curiosity - 10.0)
						_action_text = "snatched supplies from you!"
				_try_sabotage_world()
				_try_bite_player(_delta)
				_try_annoy_player(_delta)
				_try_shove_player(_delta)
				_try_place_blocks()

	_shove_player_timer = maxf(0.0, _shove_player_timer - _delta)
	var filtered_move_x := _resolve_smoothed_move_x(desired_velocity.x, _delta)
	_intended_move_x = filtered_move_x
	var before_x := global_position.x
	_move_character(filtered_move_x, _delta)
	var moved_x := absf(global_position.x - before_x)
	if absf(_intended_move_x) > 8.0 and moved_x < 0.35:
		_stuck_move_timer += _delta
	else:
		_stuck_move_timer = maxf(0.0, _stuck_move_timer - _delta * 2.0)
	_try_mine_escape()
	_update_visuals()

func _try_place_blocks() -> void:
	if _place_cooldown_timer > 0.0 or not _world_tiles or not _player or not _manager:
		return
	if not _manager.inventory is Dictionary:
		return
	# Block placement is reserved for vertical navigation only. Bob no longer builds
	# bridges, lane obstructions, or self-fortifying walls — those caused him to box
	# himself in. He only stacks a stair-step block adjacent to his feet when the
	# target is meaningfully above him AND no walk/jump path exists.
	_try_place_climb_step()

func _try_place_climb_step() -> bool:
	# Must be standing on something; mid-jump placement just makes Bob land on his
	# own block and feel stuck.
	if not _is_grounded:
		return false
	if _manager.has_method("is_bob_sabotage_suppressed") and _manager.is_bob_sabotage_suppressed():
		return false

	var to_target := _player.global_position - global_position
	# Target must be meaningfully ABOVE Bob (negative y in screen space) by more than
	# a single jump's reach. Otherwise walking/jumping is enough — no tower needed.
	if -to_target.y < climb_place_min_vertical_delta:
		return false
	# Don't bother stacking when the player is far horizontally; close in first.
	if absf(to_target.x) > climb_place_max_horizontal_distance:
		return false
	# If a normal walk+jump path already exists to the player, don't build.
	if _bob_has_walk_jump_path_to_player():
		return false
	if _rng.randf() > climb_place_chance:
		return false

	var feet_cell: Vector2i = _world_tiles.world_to_cell(global_position + Vector2(0, surface_foot_offset))
	var dir := signi(int(round(_player.global_position.x - global_position.x)))
	if dir == 0:
		dir = 1 if _rng.randf() < 0.5 else -1

	# Stair-step candidates, in priority order: adjacent to Bob at foot height in
	# the direction of the target (he'll jump onto it next frame), then the
	# opposite side as a fallback. We never pick a cell in Bob's own column —
	# that's his footprint and would trap him inside the placed block.
	var candidates: Array[Vector2i] = [
		Vector2i(feet_cell.x + dir, feet_cell.y),
		Vector2i(feet_cell.x - dir, feet_cell.y),
	]

	var mat := _choose_place_material_for("climb")
	if mat == "":
		return false
	for c in candidates:
		if _is_cell_in_bob_footprint(c, feet_cell):
			continue
		# Skip cells that already have a block — nothing to step onto we don't
		# already have.
		if _world_tiles.is_solid_cell(c):
			continue
		if _attempt_place_cell(c, mat):
			_action_text = "stacking a step to climb"
			return true
	return false

func _is_cell_in_bob_footprint(cell: Vector2i, feet_cell: Vector2i) -> bool:
	# Mirrors world_tilemap._cell_overlaps_actors: Bob spans feet, torso (feet.y-1),
	# head (feet.y-2) in his own column.
	if cell.x != feet_cell.x:
		return false
	return cell.y >= feet_cell.y - 2 and cell.y <= feet_cell.y

func _choose_place_material_for(intent: String) -> String:
	var inv: Dictionary = _manager.inventory
	var order: Array[String]
	match intent:
		"climb":
			order = ["dirt", "stone"]
		_:
			order = ["dirt", "stone"]
	for k in order:
		if int(inv.get(k, 0)) > 0:
			return k
	return ""

func _attempt_place_cell(cell: Vector2i, kind: String) -> bool:
	if kind == "":
		return false
	if int(_manager.inventory.get(kind, 0)) <= 0:
		return false
	# Final hard guard: never let the AI place a block on the cells Bob's body
	# currently occupies, even if upstream checks miss the case.
	var feet_cell: Vector2i = _world_tiles.world_to_cell(global_position + Vector2(0, surface_foot_offset))
	if _is_cell_in_bob_footprint(cell, feet_cell):
		return false
	var result: Dictionary = _world_tiles.try_place_cell(cell, kind)
	if not bool(result.get("ok", false)):
		return false
	_manager.inventory[kind] = int(_manager.inventory.get(kind, 0)) - 1
	if _manager.has_method("notify_inventory_changed"):
		_manager.notify_inventory_changed()
	_place_cooldown_timer = place_action_cooldown
	return true

func get_status_text() -> String:
	return "B.O.B | Hunger: %.0f  Safety: %.0f  Curiosity: %.0f  Mode: %s  Action: %s" % [
		hunger,
		safety,
		curiosity,
		_mode_to_string(_mode),
		_action_text
	]

func _update_needs(delta: float) -> void:
	# Hunger no longer passively decays over time; feeding / forage / bites still change it.
	curiosity = minf(100.0, curiosity + 4.2 * delta)
	energy = maxf(0.0, energy - (0.9 + velocity.length() * 0.0025) * delta)
	trust_to_player = move_toward(trust_to_player, 48.0, 0.9 * delta)

	# At night B.O.B. feels less safe and seeks caution.
	if _manager and _manager.is_night:
		safety = maxf(0.0, safety - 6.5 * delta)
	else:
		safety = minf(100.0, safety + 3.2 * delta)
	if energy < 30.0:
		safety = maxf(0.0, safety - 1.2 * delta)

	# If hunger gets critical, safety drops due to risky behavior.
	if hunger < 20.0:
		safety = maxf(0.0, safety - 3.0 * delta)
		trust_to_player = maxf(0.0, trust_to_player - 1.8 * delta)
	if hunger < 30.0:
		_action_text = "hungry... seeking food or player bites"

	# Social bonding while in friendly mode.
	if _player and _mode == BobMode.FRIENDLY:
		var near_player := global_position.distance_to(_player.global_position) < 120.0
		if near_player:
			affection = minf(100.0, affection + 2.8 * delta)
			trust_to_player = minf(100.0, trust_to_player + 1.6 * delta)
		else:
			affection = maxf(0.0, affection - 0.55 * delta)

	# Slow energy recovery while calm.
	if _mode == BobMode.FRIENDLY and velocity.length() < 5.0:
		energy = minf(100.0, energy + 5.4 * delta)

func _select_mode(delta: float) -> void:
	if not _player:
		return

	# Calm Totem aura forces friendly mode for as long as B.O.B. is inside it.
	if _calm_aura_count > 0:
		if _mode != BobMode.FRIENDLY:
			_mode = BobMode.FRIENDLY
			_action_text = "soothed by Calm Totem..."
		_mode_timer = maxf(_mode_timer, 1.5)
		return

	var player_distance := global_position.distance_to(_player.global_position)
	var player_wields_sword := _player.has_method("get_selected_tool") and str(_player.get_selected_tool()) == "sword"

	if _mode_timer > 0.0:
		return

	var bias_to_attack := attack_mode_base_bias
	# Early-game grace: stay friendly for ~30s so the player can ramp up tools.
	if _time_alive < attack_bias_early_grace_first_window:
		bias_to_attack -= attack_bias_early_grace_first_penalty
	elif _time_alive < attack_bias_early_grace_second_window:
		bias_to_attack -= attack_bias_early_grace_second_penalty
	if hunger < attack_bias_hunger_threshold:
		bias_to_attack += attack_bias_hunger_bonus
	if trust_to_player < attack_bias_low_trust_threshold:
		bias_to_attack += attack_bias_low_trust_bonus
	if energy < attack_bias_low_energy_threshold:
		bias_to_attack -= attack_bias_low_energy_penalty
	var enraged := _hurt_enrage_timer > 0.0
	if player_wields_sword and player_distance < attack_bias_sword_distance:
		if not (enraged and hurt_enrage_ignore_sword_distance_penalty):
			bias_to_attack -= attack_bias_sword_penalty
	if enraged:
		bias_to_attack += hurt_enrage_attack_bias_add
	bias_to_attack = clampf(bias_to_attack + _rng.randf_range(-attack_bias_randomness, attack_bias_randomness), attack_bias_min, attack_bias_max)

	var prev_mode := _mode
	_mode = BobMode.ATTACK if _rng.randf() < bias_to_attack else BobMode.FRIENDLY
	if prev_mode == BobMode.FRIENDLY and _mode == BobMode.ATTACK:
		_play_attack_mode_sfx()
	_roll_mode_timer()

func set_calm_aura_active(active: bool) -> void:
	if active:
		_calm_aura_count += 1
		_hurt_enrage_timer = 0.0
		_mode = BobMode.FRIENDLY
		_roll_mode_timer()
	else:
		_calm_aura_count = maxi(0, _calm_aura_count - 1)

func _roll_mode_timer() -> void:
	if _mode == BobMode.FRIENDLY:
		_mode_timer = _rng.randf_range(friendly_mode_min_seconds, friendly_mode_max_seconds)
	else:
		_mode_timer = _rng.randf_range(attack_mode_min_seconds, attack_mode_max_seconds)

func _move_toward_player(stop_at_distance: bool) -> Vector2:
	if not _player:
		return Vector2.ZERO
	var target := _player.global_position
	# Cut off escape routes: lead slightly in the direction the player is moving.
	if not stop_at_distance and _player.has_method("get_last_move_x"):
		var lx: float = float(_player.get_last_move_x())
		target.x += lx * attack_chase_lead_distance
	var to_target := target - global_position
	var social_closeness := clampf((trust_to_player + affection) * 0.005, 0.0, 1.0)
	var desired_follow_distance := lerpf(160.0, 72.0, social_closeness)
	if stop_at_distance and absf(to_target.x) <= desired_follow_distance:
		return Vector2.ZERO
	var pace := 0.82 if energy < 28.0 else 1.0
	if not stop_at_distance and energy > 18.0:
		var pace_extra := attack_pace_boost
		if _hurt_enrage_timer > 0.0:
			pace_extra += hurt_enrage_pace_boost_add
		pace = minf(attack_pace_max, pace + pace_extra)
	return Vector2(signf(to_target.x) * move_speed * pace, 0.0)

func _move_toward_forage() -> Vector2:
	if _mode == BobMode.FRIENDLY and _player and global_position.distance_to(_player.global_position) < 150.0:
		var keep_offset := _player.global_position + Vector2(-110.0 if _player.global_position.x > global_position.x else 110.0, 0)
		var to_keep := keep_offset - global_position
		return Vector2(signf(to_keep.x) * move_speed * 0.72, 0.0)
	var to_target := _forage_target - global_position
	if absf(to_target.x) < 20.0:
		_pick_new_forage_target()
		if _manager:
			_manager.collect_for_bob(1)
		hunger = minf(100.0, hunger + 4.0)
		energy = minf(100.0, energy + 6.0)
		curiosity = maxf(0.0, curiosity - 35.0)
		return Vector2.ZERO
	return Vector2(signf(to_target.x) * move_speed, 0.0)

func _bob_try_mine_cell(cell: Vector2i, tool: String) -> Dictionary:
	if not _world_tiles:
		return {"ok": false, "reason": "no_tilemap"}
	return _world_tiles.try_mine_cell(
		cell,
		tool,
		bob_mine_tier_damage_mult,
		bob_mine_wrong_tool_slowdown,
		bob_mine_damage_multiplier,
	)


func _try_forage_mine() -> void:
	if _mine_cooldown_timer > 0.0 or _forage_mine_timer > 0.0 or not _world_tiles:
		return
	if not _should_forage_mine():
		return
	var feet_cell: Vector2i = _world_tiles.world_to_cell(global_position + Vector2(0, surface_foot_offset))
	var candidates := [
		Vector2i(feet_cell.x + 1, feet_cell.y - 1),
		Vector2i(feet_cell.x - 1, feet_cell.y - 1),
		Vector2i(feet_cell.x, feet_cell.y - 1),
	]
	var best_target := Vector2i(-999, -999)
	var best_score := -100000.0
	for target in candidates:
		if not _can_mine_target(feet_cell, target):
			continue
		var score := _score_mine_target(feet_cell, target)
		if score > best_score:
			best_score = score
			best_target = target
	if best_target.x < -100:
		_forage_mine_timer = forage_mine_interval
		return
	var tool := "axe" if best_target.y <= feet_cell.y else "pickaxe"
	var result: Dictionary = _bob_try_mine_cell(best_target, tool)
	_mine_cooldown_timer = mine_action_cooldown
	_forage_mine_timer = forage_mine_interval
	if not bool(result.get("ok", false)):
		return
	if bool(result.get("mined", false)):
		var drops: Array = result.get("drops", [])
		if _manager:
			_manager.collect_for_bob(1)
		for drop in drops:
			var kind := str(drop.get("kind", ""))
			var amount := float(int(drop.get("amount", 0)))
			match kind:
				"food":
					hunger = minf(100.0, hunger + 6.0 * amount)
					if not _is_dead:
						health = minf(max_health, health + 2.0 * amount)
				"dirt", "wood":
					hunger = minf(100.0, hunger + 1.0 * amount)
		energy = minf(100.0, energy + 2.0)
		_action_text = "targeted forage mining"

const _BOB_PATH_MAP_H := 40
const _BOB_PATH_MAX_COL_SPAN := 24
const _BOB_PATH_MAX_JUMPS := 2

func _bob_path_key(v: Vector3i) -> String:
	return "%d,%d,%d" % [int(v.x), int(v.y), int(v.z)]

func _bob_is_valid_stand_cell(x: int, y: int) -> bool:
	if y < 0 or y >= _BOB_PATH_MAP_H:
		return false
	var c := Vector2i(x, y)
	if not _world_tiles.is_solid_cell(c):
		return false
	return not _world_tiles.is_solid_cell(Vector2i(x, y - 1))

func _bob_find_stand_y_near_column(col_x: int, hint_y: int) -> int:
	for y in range(maxi(0, hint_y - 6), mini(_BOB_PATH_MAP_H, hint_y + 7)):
		if _bob_is_valid_stand_cell(col_x, y):
			return y
	return -1

func _bob_jump_vertical_clear(cx: int, from_ground_y: int) -> bool:
	if from_ground_y < 2:
		return false
	return not _world_tiles.is_solid_cell(Vector2i(cx, from_ground_y - 2))

func _bob_jump_diag_clear(cx: int, nx: int, from_ground_y: int) -> bool:
	if from_ground_y < 2:
		return false
	if _world_tiles.is_solid_cell(Vector2i(nx, from_ground_y)):
		return false
	return not _world_tiles.is_solid_cell(Vector2i(nx, from_ground_y - 2))

func _bob_walk_body_clear(cx: int, cy: int, nx: int, ny: int) -> bool:
	var top_y := mini(cy, ny) - 2
	if top_y < 0:
		return true
	for tx in range(mini(cx, nx), maxi(cx, nx) + 1):
		if _world_tiles.is_solid_cell(Vector2i(tx, top_y)):
			return false
	return true

func _bob_has_walk_jump_path_to_player() -> bool:
	if not _world_tiles or not _player:
		return false
	var w := _world_tiles
	var bc: Vector2i = w.world_to_cell(global_position + Vector2(0, surface_foot_offset)) as Vector2i
	var pc: Vector2i = w.world_to_cell(_player.global_position + Vector2(0, 30.0)) as Vector2i
	var x0 := mini(bc.x, pc.x) - 1
	var x1 := maxi(bc.x, pc.x) + 1
	if x1 - x0 + 1 > _BOB_PATH_MAX_COL_SPAN + 2:
		return false
	var start_y := _bob_find_stand_y_near_column(bc.x, bc.y)
	if start_y < 0:
		return false
	var visited: Dictionary = {}
	var queue: Array[Vector3i] = []
	var start := Vector3i(bc.x, start_y, 0)
	queue.append(start)
	visited[_bob_path_key(start)] = true
	var qidx := 0
	while qidx < queue.size():
		var cur: Vector3i = queue[qidx]
		qidx += 1
		var cx := int(cur.x)
		var cy := int(cur.y)
		var ju := int(cur.z)
		if maxi(absi(cx - pc.x), absi(cy - pc.y)) <= 2:
			return true
		for dir in [-1, 1]:
			var nxc: int = cx + dir
			if nxc < x0 or nxc > x1:
				continue
			var ny := _bob_find_stand_y_near_column(nxc, cy)
			if ny < 0:
				continue
			if absi(ny - cy) > 1:
				continue
			var nk := Vector3i(nxc, ny, ju)
			var wk := _bob_path_key(nk)
			if visited.get(wk, false):
				continue
			if not _bob_walk_body_clear(cx, cy, nxc, ny):
				continue
			visited[wk] = true
			queue.append(nk)
		if ju >= _BOB_PATH_MAX_JUMPS:
			continue
		var up_y := cy - 1
		if up_y >= 0 and _bob_is_valid_stand_cell(cx, up_y) and _bob_jump_vertical_clear(cx, cy):
			var vk := _bob_path_key(Vector3i(cx, up_y, ju + 1))
			if not visited.get(vk, false):
				visited[vk] = true
				queue.append(Vector3i(cx, up_y, ju + 1))
		for dir in [-1, 1]:
			var jx: int = cx + dir
			if jx < x0 or jx > x1:
				continue
			var land_y := cy - 1
			if land_y < 0 or not _bob_is_valid_stand_cell(jx, land_y):
				continue
			if not _bob_jump_diag_clear(cx, jx, cy):
				continue
			var dk := _bob_path_key(Vector3i(jx, land_y, ju + 1))
			if visited.get(dk, false):
				continue
			visited[dk] = true
			queue.append(Vector3i(jx, land_y, ju + 1))
	return false

func _try_mine_escape() -> void:
	if _mine_cooldown_timer > 0.0 or not _world_tiles or not _player:
		return
	# Never mine while simply following; walk/jump should handle traversal.
	if _mode == BobMode.FRIENDLY:
		return
	# Mine only when actually stuck for a short period.
	if _stuck_move_timer < bob_escape_stuck_threshold:
		return
	var feet_cell: Vector2i = _world_tiles.world_to_cell(global_position + Vector2(0, surface_foot_offset))
	var player_above: bool = _player.global_position.y < global_position.y - 40.0
	var trapped_by_front: bool = _would_hit_side(10.0) or _would_hit_side(-10.0)
	if not player_above and not trapped_by_front:
		_escape_mine_chain = 0
		return
	if _bob_has_walk_jump_path_to_player():
		_escape_mine_chain = 0
		_stuck_move_timer *= 0.35
		return
	var target := _choose_escape_mine_target(feet_cell)
	if target.x < -100:
		return
	var result: Dictionary = _bob_try_mine_cell(target, "pickaxe")
	if not bool(result.get("ok", false)):
		return
	_mine_cooldown_timer = bob_escape_mine_cooldown
	_stuck_move_timer = 0.0
	_escape_mine_chain += 1
	_action_text = "mining smart path toward player"
	if bool(result.get("mined", false)):
		energy = maxf(0.0, energy - 0.5)
		if _manager:
			_manager.collect_for_bob(1)
	# Safety brake: prevent runaway excavation loops.
	if _escape_mine_chain >= bob_escape_mine_chain_limit:
		_escape_mine_chain = 0
		_mine_cooldown_timer = bob_escape_mine_chain_brake_cooldown

func _can_mine_target(origin: Vector2i, target: Vector2i) -> bool:
	var dx := absi(target.x - origin.x)
	var dy := target.y - origin.y
	if dx > mine_reach_cells_x:
		return false
	if dy < -mine_reach_cells_up:
		return false
	if dy > mine_reach_cells_down:
		return false
	if not _world_tiles.is_solid_cell(target):
		return false
	# Do not let B.O.B mine the base world bottom out entirely.
	if target.y >= 34:
		return false
	# Avoid undermining his own footing while foraging.
	if target.x == origin.x and target.y >= origin.y:
		return false
	return true

func _choose_escape_mine_target(origin: Vector2i) -> Vector2i:
	var toward_player := signi(int(round(_player.global_position.x - global_position.x)))
	if toward_player == 0:
		toward_player = 1
	var ahead_x := origin.x + toward_player
	var two_ahead_x := origin.x + toward_player * 2
	var three_ahead_x := origin.x + toward_player * 3
	# Candidate order is intentionally top/forward first (ledge opening),
	# avoiding downward digs that trap B.O.B further.
	var candidates := [
		Vector2i(two_ahead_x, origin.y - 3),
		Vector2i(ahead_x, origin.y - 2),
		Vector2i(two_ahead_x, origin.y - 2),
		Vector2i(ahead_x, origin.y - 1),
		Vector2i(two_ahead_x, origin.y - 1),
		Vector2i(origin.x, origin.y - 2),
		Vector2i(origin.x, origin.y - 1),
		Vector2i(three_ahead_x, origin.y - 1),
		Vector2i(ahead_x, origin.y),
	]
	var best := Vector2i(-999, -999)
	var best_score := -100000.0
	for cell in candidates:
		if not _can_mine_escape_target(origin, cell):
			continue
		var score := _score_escape_target(origin, cell, toward_player)
		if score > best_score:
			best_score = score
			best = cell
	return best

func _score_escape_target(origin: Vector2i, target: Vector2i, toward_player: int) -> float:
	var score := 0.0
	# Prefer opening upward routes first.
	if target.y < origin.y:
		score += 8.0 + float(origin.y - target.y) * 2.0
	# Prefer breaking in the player's horizontal direction.
	if (target.x - origin.x) * toward_player > 0:
		score += 5.0
	# Penalize mining at/below foot level.
	if target.y >= origin.y:
		score -= 6.0
	# Prefer blocks with air above; usually cap/ledge blockers like your red-marked example.
	if not _world_tiles.is_solid_cell(Vector2i(target.x, target.y - 1)):
		score += 3.5
	# Slightly punish farther targets.
	score -= float(absi(target.x - origin.x)) * 0.8
	# Strongly prefer targets that expose immediate air pocket for climb.
	if not _world_tiles.is_solid_cell(Vector2i(target.x, target.y - 1)):
		score += 2.5
	return score

func _can_mine_escape_target(origin: Vector2i, target: Vector2i) -> bool:
	var dx := absi(target.x - origin.x)
	var dy := target.y - origin.y
	if dx > escape_mine_reach_cells_x:
		return false
	if dy < -escape_mine_reach_cells_up:
		return false
	if dy > 0:
		return false
	if not _world_tiles.is_solid_cell(target):
		return false
	if target.y >= 34:
		return false
	# Never dig directly under feet during escape.
	if target.x == origin.x and target.y >= origin.y:
		return false
	return true

func _should_forage_mine() -> bool:
	# Mine only when it serves a purpose; avoid constant world destruction.
	if hunger < 68.0:
		return true
	if curiosity > 88.0 and energy > 22.0:
		return true
	return false

func _score_mine_target(origin: Vector2i, target: Vector2i) -> float:
	var source_id := _world_tiles.get_cell_source_id(target)
	var score := 0.0
	match source_id:
		0: # grass => food-like
			score += 8.0
		1: # dirt => wood-like drop in this prototype
			score += 4.0
		2: # stone
			score += 1.5
		_:
			score += 0.2
	if not _is_exposed_block(target):
		score -= 3.0
	if target.y < origin.y:
		score += 1.0
	score -= float(absi(target.x - origin.x)) * 0.6
	return score

func _is_exposed_block(cell: Vector2i) -> bool:
	# Prefer blocks with sky/air above to emulate harvesting visible resources.
	return not _world_tiles.is_solid_cell(Vector2i(cell.x, cell.y - 1))

func _pick_new_forage_target() -> void:
	if _world_tiles and _world_tiles.has_method("get_random_surface_world_position"):
		_forage_target = _world_tiles.get_random_surface_world_position(_rng)
		return
	if not _player:
		_forage_target = global_position
		return
	_forage_target = _player.global_position + Vector2(_rng.randf_range(-forage_distance, forage_distance), 0.0)

func _resolve_smoothed_move_x(desired_x: float, delta: float) -> float:
	var desired_sign := 0.0
	if absf(desired_x) > steering_direction_deadzone:
		desired_sign = signf(desired_x)

	if desired_sign == 0.0:
		_horizontal_intent_sign = 0.0
		_intent_flip_hold_timer = 0.0
	elif _horizontal_intent_sign == 0.0:
		_horizontal_intent_sign = desired_sign
		_intent_flip_hold_timer = 0.0
	elif desired_sign != _horizontal_intent_sign:
		if _intent_flip_hold_timer <= 0.0:
			_intent_flip_hold_timer = steering_flip_hold_time
		_intent_flip_hold_timer = maxf(0.0, _intent_flip_hold_timer - delta)
		if _intent_flip_hold_timer <= 0.0:
			_horizontal_intent_sign = desired_sign
	else:
		_intent_flip_hold_timer = 0.0

	var target_x := 0.0
	if desired_sign != 0.0:
		target_x = absf(desired_x) * _horizontal_intent_sign
	var rate := steering_accel if absf(target_x) > absf(_smoothed_move_x) else steering_decel
	if target_x != 0.0 and _smoothed_move_x != 0.0 and signf(target_x) != signf(_smoothed_move_x):
		rate = steering_turn_brake
	_smoothed_move_x = move_toward(_smoothed_move_x, target_x, rate * delta)
	return _smoothed_move_x

func _move_character(move_x: float, delta: float) -> void:
	if not _world_tiles:
		global_position.x += (move_x + _hurt_knockback_velocity) * delta
		_hurt_knockback_velocity = move_toward(_hurt_knockback_velocity, 0.0, hurt_knockback_decay * delta)
		velocity = Vector2(move_x + _hurt_knockback_velocity, 0.0)
		return
	if absf(_hurt_knockback_velocity) > 0.4:
		var kdx := _hurt_knockback_velocity * delta
		if absf(kdx) > 0.001 and not _would_hit_side(kdx):
			global_position.x += kdx
		_hurt_knockback_velocity = move_toward(_hurt_knockback_velocity, 0.0, hurt_knockback_decay * delta)
	var dx := move_x * delta
	var blocked_side := _would_hit_side(dx) if absf(dx) > 0.001 else false
	if absf(dx) > 0.001 and not blocked_side:
		global_position.x += dx

	_is_grounded = _has_floor_beneath()
	if _is_grounded and blocked_side and _can_jump_over_obstacle(signf(move_x)):
		_vertical_velocity = jump_velocity
		_is_grounded = false

	if not _is_grounded:
		_vertical_velocity = minf(max_fall_speed, _vertical_velocity + gravity_force * delta)
	else:
		_vertical_velocity = maxf(0.0, _vertical_velocity)

	var dy := _vertical_velocity * delta
	if dy > 0.0:
		if _would_hit_floor(dy):
			var foot_probe := global_position + Vector2(0, surface_foot_offset + dy)
			var cell: Vector2i = _world_tiles.world_to_cell(foot_probe)
			global_position.y = _world_tiles.get_cell_world_top_y(cell) - surface_foot_offset
			_vertical_velocity = 0.0
			_is_grounded = true
		else:
			global_position.y += dy
	elif dy < 0.0:
		if _would_hit_ceiling(dy):
			_vertical_velocity = 0.0
		else:
			global_position.y += dy
	velocity = Vector2(move_x + _hurt_knockback_velocity, _vertical_velocity)

func _has_floor_beneath() -> bool:
	var left := global_position + Vector2(-collider_half_width, surface_foot_offset + 2.0)
	var right := global_position + Vector2(collider_half_width, surface_foot_offset + 2.0)
	return _world_tiles.is_solid_world_point(left) or _world_tiles.is_solid_world_point(right)

func _would_hit_side(dx: float) -> bool:
	var side_x := collider_half_width + 2.0
	if dx < 0.0:
		side_x = -side_x
	var checks := [
		global_position + Vector2(side_x + dx, collider_head_offset + 8.0),
		global_position + Vector2(side_x + dx, -8.0),
		global_position + Vector2(side_x + dx, surface_foot_offset - 6.0),
	]
	for p in checks:
		if _world_tiles.is_solid_world_point(p):
			return true
	return false

func _would_hit_floor(dy: float) -> bool:
	var left := global_position + Vector2(-collider_half_width + 2.0, surface_foot_offset + dy)
	var right := global_position + Vector2(collider_half_width - 2.0, surface_foot_offset + dy)
	return _world_tiles.is_solid_world_point(left) or _world_tiles.is_solid_world_point(right)

func _would_hit_ceiling(dy: float) -> bool:
	var left := global_position + Vector2(-collider_half_width + 2.0, collider_head_offset + dy)
	var right := global_position + Vector2(collider_half_width - 2.0, collider_head_offset + dy)
	return _world_tiles.is_solid_world_point(left) or _world_tiles.is_solid_world_point(right)

func _can_jump_over_obstacle(direction: float) -> bool:
	if direction == 0.0:
		return false
	var front_x := direction * (collider_half_width + 8.0)
	var blocked_front: bool = _world_tiles.is_solid_world_point(global_position + Vector2(front_x, -8.0))
	var clear_above: bool = not _world_tiles.is_solid_world_point(global_position + Vector2(front_x, collider_head_offset - 16.0))
	return blocked_front and clear_above

func _mode_to_string(value: BobMode) -> String:
	match value:
		BobMode.FRIENDLY:
			return "FRIENDLY"
		BobMode.ATTACK:
			return "ATTACK"
		_:
			return "UNKNOWN"

func _try_sabotage_world() -> void:
	var nearest_door := _nearest_group_node("doors", 70.0)
	if nearest_door and nearest_door.has_method("force_close"):
		nearest_door.force_close()
		return

	var nearest_chest := _nearest_group_node("chests", 70.0)
	if nearest_chest and nearest_chest.has_method("break_chest"):
		var stolen_scraps: int = nearest_chest.break_chest()
		if stolen_scraps > 0 and _manager:
			_manager.collect_for_bob(stolen_scraps)

func _nearest_group_node(group_name: String, max_distance: float) -> Node2D:
	var nearest: Node2D
	var nearest_distance := max_distance
	for item in get_tree().get_nodes_in_group(group_name):
		if not (item is Node2D):
			continue
		var node := item as Node2D
		var d := global_position.distance_to(node.global_position)
		if d < nearest_distance:
			nearest_distance = d
			nearest = node
	return nearest

func _nearest_ripe_berry_bush(max_distance: float) -> Node2D:
	return _nearest_ripe_berry_bush_from(global_position, max_distance)

func _nearest_ripe_berry_bush_from(origin: Vector2, max_distance: float) -> Node2D:
	var nearest: Node2D
	var best := max_distance
	for item in get_tree().get_nodes_in_group("berry_bushes"):
		if not (item is Node2D):
			continue
		if item.has_method("is_ripe") and not item.is_ripe():
			continue
		var node := item as Node2D
		var d := origin.distance_to(node.global_position)
		if d < best:
			best = d
			nearest = node
	return nearest

func _is_player_health_below_threshold() -> bool:
	if not _manager:
		return false
	var max_hp := float(_manager.player_max_health)
	if max_hp <= 0.001:
		return false
	var hp_ratio := float(_manager.player_health) / max_hp
	return hp_ratio <= clampf(deny_food_player_health_ratio_threshold, 0.0, 1.0)

func _try_deny_player_food() -> void:
	if _deny_food_cd > 0.0 or not _player or not _world_tiles:
		return
	var bush := _nearest_ripe_berry_bush_from(_player.global_position, deny_food_destroy_radius)
	if not bush:
		return
	var bush_cell := _resolve_bush_placement_cell(bush as Node2D)
	if bush_cell.x < -1000000:
		return
	if global_position.distance_to(_world_tiles.get_cell_world_center(bush_cell)) > 166.0:
		return
	if _rng.randf() > clampf(deny_food_destroy_chance, 0.0, 1.0):
		_deny_food_cd = deny_food_destroy_cooldown
		return
	var mat := _choose_place_material_for("climb")
	if mat == "":
		return
	if _attempt_place_cell(bush_cell, mat):
		_deny_food_cd = deny_food_destroy_cooldown
		_action_text = "denying berries near player"

func _resolve_bush_placement_cell(bush: Node2D) -> Vector2i:
	var root: Vector2i = _world_tiles.world_to_cell(bush.global_position)
	var candidates: Array[Vector2i] = [
		root,
		Vector2i(root.x, root.y - 1),
		Vector2i(root.x + 1, root.y),
		Vector2i(root.x - 1, root.y),
	]
	for cell in candidates:
		if _world_tiles.is_solid_cell(cell):
			continue
		return cell
	return Vector2i(-9999999, -9999999)

func _try_berry_food_steering() -> Variant:
	if hunger >= berry_seek_hunger_below:
		return null
	var bush := _nearest_ripe_berry_bush(berry_seek_max_distance)
	if not bush:
		return null
	var to_bush: Vector2 = (bush as Node2D).global_position - global_position
	var dist := to_bush.length()
	if dist <= berry_gather_distance:
		_action_text = "munching nearby berries..."
		if _berry_gather_cd <= 0.0 and bush.has_method("gather"):
			_berry_gather_cd = berry_gather_cooldown
			var result: Dictionary = bush.gather("", 1.0)
			var amt := int(result.get("amount", 0))
			if amt > 0:
				if _manager:
					_manager.collect_for_bob(maxi(1, amt >> 1))
				hunger = minf(100.0, hunger + 6.0 * float(amt))
				energy = minf(100.0, energy + 3.5)
				if not _is_dead:
					health = minf(max_health, health + 1.5)
				curiosity = maxf(0.0, curiosity - 18.0)
				_action_text = "raiding berry patch!"
		return Vector2.ZERO
	_action_text = "hunting berry bushes..."
	var pace := 0.9 if energy < 26.0 else 1.0
	var berry_seek_speed := berry_seek_speed_override if berry_seek_speed_override > 0.0 else move_speed * berry_seek_speed_multiplier
	return Vector2(signf(to_bush.x) * berry_seek_speed * pace, 0.0)

func _update_visuals() -> void:
	var body := $Body as Sprite2D
	var base_scale := body_visual_scale
	if not body:
		return
	var horizontal_speed := absf(velocity.x)
	if horizontal_speed > 6.0:
		var move_intensity := clampf(horizontal_speed / maxf(1.0, move_speed), 0.35, 1.2)
		var walk_wave := sin(_time_alive * walk_bob_frequency)
		body.scale.x = -(base_scale * body_width_scale) if velocity.x < 0.0 else (base_scale * body_width_scale)
		body.position.y = body_visual_y_offset + walk_baseline_offset + walk_wave * walk_bob_amplitude * move_intensity
		body.rotation = sin(_time_alive * walk_tilt_frequency) * walk_tilt_amplitude * move_intensity
		if _mode == BobMode.ATTACK:
			body.rotation += attack_lean_radians * signf(velocity.x)
		body.scale.y = base_scale - absf(walk_wave) * walk_squash_amplitude * move_intensity
	else:
		body.position.y = body_visual_y_offset + sin(_time_alive * idle_bob_frequency) * idle_bob_amplitude
		body.rotation = sin(_time_alive * idle_tilt_frequency) * idle_tilt_amplitude
		body.scale.y = base_scale
	var mode_tint := Color(0.48, 0.9, 0.62, 1.0) if _mode == BobMode.FRIENDLY else Color(1.0, 0.36, 0.36, 1.0)
	if hunger < 30.0:
		body.modulate = mode_tint * Color(1.0, 0.78, 0.78, 1.0)
	else:
		body.modulate = mode_tint

func receive_food(amount: int) -> void:
	if _is_dead:
		return
	hunger = minf(100.0, hunger + float(amount) * 22.0)
	health = minf(max_health, health + float(amount) * 2.5)
	safety = minf(100.0, safety + float(amount) * 10.0)
	energy = minf(100.0, energy + float(amount) * 12.0)
	trust_to_player = minf(100.0, trust_to_player + float(amount) * 6.0)
	affection = minf(100.0, affection + float(amount) * 4.0)
	curiosity = maxf(0.0, curiosity - float(amount) * 8.0)
	_action_text = "eating food from player"

func _try_bite_player(delta: float) -> void:
	var bite_hunger_max := bite_attack_hunger_max if _mode == BobMode.ATTACK else bite_friendly_hunger_max
	if _hurt_enrage_timer > 0.0:
		bite_hunger_max += hurt_enrage_bite_hunger_max_bonus
	if hunger > bite_hunger_max:
		return
	if not _player or not _manager:
		return
	if global_position.distance_to(_player.global_position) > bite_contact_range:
		return
	var bite_tick := bite_damage_per_second
	if _hurt_enrage_timer > 0.0:
		bite_tick *= hurt_enrage_bite_damage_multiplier
	bite_tick *= _face_tank_pressure_damage_mult()
	_manager.damage_player(bite_tick * delta)
	if _bite_sfx_cd <= 0.0:
		GameSfx.play_at(self, GameSfx.BOB_BITE, global_position, -3.0)
		_bite_sfx_cd = 0.38
	hunger = minf(100.0, hunger + 9.0 * delta)
	trust_to_player = maxf(0.0, trust_to_player - 4.2 * delta)
	_action_text = "biting player (starving!)"

func _try_annoy_player(delta: float) -> void:
	if _last_annoy_tick > 0.0:
		return
	if not _player or not _manager:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist > attack_annoy_distance:
		return
	if _manager.has_method("is_bob_sabotage_suppressed") and _manager.is_bob_sabotage_suppressed():
		return
	# Discrete chip damage each proc (delta was too small to feel).
	var chip := attack_annoy_damage if _mode == BobMode.ATTACK else friendly_annoy_damage
	var tick_cd := attack_annoy_cooldown if _mode == BobMode.ATTACK else friendly_annoy_cooldown
	if _hurt_enrage_timer > 0.0 and _mode == BobMode.ATTACK:
		chip *= hurt_enrage_annoy_damage_multiplier
		tick_cd *= hurt_enrage_annoy_cooldown_scale
	chip *= _face_tank_pressure_damage_mult()
	_manager.damage_player(chip)
	trust_to_player = maxf(0.0, trust_to_player - 2.4)
	_last_annoy_tick = tick_cd
	if hunger < 68.0:
		_action_text = "harassing player at close range"

func _try_shove_player(delta: float) -> void:
	if _mode != BobMode.ATTACK or not _player or not _manager:
		return
	if _shove_player_timer > 0.0:
		return
	if _manager.has_method("is_bob_sabotage_suppressed") and _manager.is_bob_sabotage_suppressed():
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist > attack_shove_range or dist < attack_shove_min_distance:
		return
	if not _player.has_method("apply_bob_shove"):
		return
	var in_kill_window := hunger <= bite_attack_hunger_max and dist <= bite_contact_range
	var shove_strength := attack_shove_strength
	var shove_cooldown := attack_shove_cooldown
	if not in_kill_window:
		shove_strength *= attack_shove_harass_strength_multiplier
		shove_cooldown = attack_shove_harass_cooldown
	if _hurt_enrage_timer > 0.0:
		shove_cooldown *= hurt_enrage_shove_cooldown_scale
	var dir := signf(_player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0 if _rng.randf() < 0.5 else -1.0
	_player.apply_bob_shove(dir, shove_strength)
	_shove_player_timer = maxf(attack_shove_cooldown_floor, shove_cooldown)
	trust_to_player = maxf(0.0, trust_to_player - 1.8)
	curiosity = minf(100.0, curiosity + 3.5)
	_action_text = "shoving you aggressively" if not in_kill_window else "shoving you out of the way"

func _should_apply_player_melee_hp_loss(melee_weapon: String) -> bool:
	return melee_weapon == PLAYER_HP_DAMAGE_WEAPON_ID


func _sync_max_health_from_sword_balance() -> void:
	var sword_raw := 16.0
	if _player and _player.has_method("get_sword_damage_for_bob_hp_balance"):
		sword_raw = float(_player.get_sword_damage_for_bob_hp_balance())
	var hp_loss_per_sword_hit := sword_raw * damage_received_multiplier
	var tier_hp_mult := 1.0
	if _manager and _manager.has_method("get_tool_tier"):
		var st := maxi(0, int(_manager.get_tool_tier("sword")))
		tier_hp_mult = 1.0 + bob_hp_bonus_per_sword_tier * float(st)
	max_health = maxf(1.0, hp_loss_per_sword_hit * maxf(1.0, target_sword_hits_to_kill) * tier_hp_mult)


func _face_tank_pressure_damage_mult() -> float:
	if _mode != BobMode.ATTACK:
		return 1.0
	if not _player:
		return 1.0
	if global_position.distance_to(_player.global_position) > face_tank_player_max_distance:
		return 1.0
	if not _player.has_method("is_sword_melee_commit_recent"):
		return 1.0
	if not _player.is_sword_melee_commit_recent(face_tank_swing_recency_seconds):
		return 1.0
	return 1.0 + face_tank_player_damage_bonus_mult


func _update_enrage_melee_pressure(delta: float) -> void:
	if _hurt_enrage_timer <= 0.0 or not _player:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist > hurt_enrage_player_back_off_clear_range:
		_hurt_enrage_timer = 0.0
		return
	var sword_up := _player.has_method("get_selected_tool") and str(_player.get_selected_tool()) == "sword"
	if not sword_up or dist > hurt_enrage_melee_pressure_range:
		return
	var cap := maxf(hurt_enrage_duration_seconds * 1.35, hurt_enrage_duration_seconds + 1.0)
	_hurt_enrage_timer = minf(cap, _hurt_enrage_timer + hurt_enrage_melee_pressure_recharge_per_second * delta)


func receive_damage(amount: float, hit_direction_x: float = 0.0, knockback_strength: float = 230.0, melee_weapon: String = "") -> void:
	if _is_dead or amount <= 0.0:
		return
	if not _should_apply_player_melee_hp_loss(melee_weapon):
		return
	var dmg := amount * damage_received_multiplier
	health = clampf(health - dmg, 0.0, max_health)
	safety = maxf(0.0, safety - dmg * 0.6)
	hunger = maxf(0.0, hunger - dmg * 0.25)
	trust_to_player = maxf(0.0, trust_to_player - dmg * 0.9)
	affection = maxf(0.0, affection - dmg * 0.6)
	if _calm_aura_count <= 0:
		_hurt_enrage_timer = hurt_enrage_duration_seconds
		if _mode != BobMode.ATTACK:
			_play_attack_mode_sfx()
		_mode = BobMode.ATTACK
		_mode_timer = maxf(_mode_timer, hurt_enrage_mode_timer_floor_seconds)
	_action_text = "angry after being hit!"
	var kick := hit_direction_x
	if kick == 0.0 and _player:
		kick = signf(global_position.x - _player.global_position.x)
	if kick == 0.0:
		kick = 1.0 if _rng.randf() < 0.5 else -1.0
	_apply_hurt_knockback(kick, knockback_strength)
	global_position.x += kick * 14.0
	if health <= 0.0:
		_die()


func is_defeated() -> bool:
	return _is_dead


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	_action_text = "defeated"
	remove_from_group("bob_agent")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	set_process(false)
	set_physics_process(false)
	visible = false
	var wait := maxf(0.05, death_respawn_delay_seconds)
	get_tree().create_timer(wait).timeout.connect(_respawn_after_death, CONNECT_ONE_SHOT)


func _tile_size_px() -> float:
	if _world_tiles and _world_tiles.tile_set:
		return float(_world_tiles.tile_set.tile_size.x)
	return 64.0


func _respawn_after_death() -> void:
	if not is_inside_tree() or not _is_dead:
		return
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if not _world_tiles or not is_instance_valid(_world_tiles):
		_world_tiles = get_tree().current_scene.get_node_or_null("WorldTiles") as TileMapLayer
	var tile_px := _tile_size_px()
	var dist_px := maxf(1.0, respawn_offset_tiles) * tile_px
	# Horizontal separation only (surface spawn uses column X); omit pure vertical so we never stack on the player.
	var dirs: Array[Vector2] = [
		Vector2.RIGHT, Vector2.LEFT,
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1),
	]
	var dir: Vector2 = dirs[_rng.randi() % dirs.size()].normalized()
	var offset := dir * dist_px
	var target_x := global_position.x
	if _player:
		target_x = _player.global_position.x + offset.x
	if _world_tiles and _world_tiles.has_method("ensure_streaming_around_world"):
		_world_tiles.ensure_streaming_around_world(target_x - tile_px * 4.0, target_x + tile_px * 4.0)
	var surface := Vector2(target_x, global_position.y)
	if _world_tiles and _world_tiles.has_method("get_surface_world_position_at_x"):
		surface = _world_tiles.get_surface_world_position_at_x(target_x)
	global_position = surface + Vector2(0.0, -surface_foot_offset)
	_hurt_knockback_velocity = 0.0
	velocity = Vector2.ZERO
	_sync_max_health_from_sword_balance()
	health = max_health
	_hurt_enrage_timer = 0.0
	_is_dead = false
	add_to_group("bob_agent")
	collision_layer = _alive_collision_layer
	collision_mask = _alive_collision_mask
	visible = true
	_mode = BobMode.ATTACK
	_roll_mode_timer()
	_action_text = "angry after respawn!"
	set_process(true)
	set_physics_process(true)


func _apply_hurt_knockback(direction_x: float, strength: float) -> void:
	var dir := signf(direction_x)
	if dir == 0.0:
		return
	_hurt_knockback_velocity = clampf(
		_hurt_knockback_velocity + dir * strength,
		-hurt_knockback_max_speed,
		hurt_knockback_max_speed
	)

func get_life_debug_snapshot() -> Dictionary:
	return {
		"health": health,
		"max_health": max_health,
		"hunger": hunger,
		"safety": safety,
		"curiosity": curiosity,
		"energy": energy,
		"trust": trust_to_player,
		"affection": affection,
		"state": _mode_to_string(_mode),
		"action": _action_text,
		"defeated": _is_dead,
	}


func _play_attack_mode_sfx() -> void:
	GameSfx.play_at(self, GameSfx.BOB_MODE_ANGRY, global_position, -2.0)
