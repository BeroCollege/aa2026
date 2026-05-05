extends CharacterBody2D

@export var move_speed: float = 280.0
@export var gather_cooldown_seconds: float = 0.4
@export var interact_radius: float = 220.0
@export var surface_foot_offset: float = 30.0
@export var tile_mine_reach: float = 220.0
@export var tile_mine_cell_range_x: int = 1
@export var tile_mine_cell_range_up: int = 2
@export var tile_mine_cell_range_down: int = 1
@export var gravity_force: float = 1550.0
@export var jump_velocity: float = -495.0
@export var max_fall_speed: float = 980.0
@export var collider_half_width: float = 14.0
@export var collider_head_offset: float = -80.0
@export var body_visual_scale: float = 6.0
@export var body_width_scale: float = 0.82
## Multiplied by body_visual_scale for held tool strip (columns are large PNGs).
@export var held_tool_scale_coefficient: float = 0.038

var _gather_timer: float = 0.0
var _manager
var _time_alive: float = 0.0
var _last_hint: String = "Collect resources with [E]."
var _action_timer: float = 0.0
var _action_state: String = "idle"
var _selected_tool: String = "pickaxe"
var _tool_number_latch: Array[bool] = [false, false, false, false, false]
var _tilled_scene := preload("res://scenes/TilledPatch.tscn")
var _crop_scene := preload("res://scenes/CropNode.tscn")
var _world_tiles: TileMapLayer
var _vertical_velocity: float = 0.0
var _is_grounded: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _last_move_x: float = 0.0
var _place_kind: String = "dirt"
var _place_kinds: Array[String] = ["dirt", "stone", "grass_block", "reinforced"]
var _place_cooldown: float = 0.0
var _totem_scene := preload("res://scenes/PlacedTotem.tscn")

@onready var _tool_sprite: Sprite2D = $HeldTool/ToolSprite
var _held_tool_atlas: AtlasTexture

func _ready() -> void:
	add_to_group("player")
	_manager = get_tree().get_first_node_in_group("game_manager")
	_world_tiles = get_tree().current_scene.get_node("WorldTiles") as TileMapLayer
	var strip: Texture2D = ToolStripIcons.strip_texture()
	if strip and _tool_sprite:
		_held_tool_atlas = AtlasTexture.new()
		_held_tool_atlas.atlas = strip
		_held_tool_atlas.region = ToolStripIcons.region_for_tool(_selected_tool)
		_tool_sprite.texture = _held_tool_atlas
		_apply_held_tool_sprite_scale()

func _apply_held_tool_sprite_scale() -> void:
	if not _tool_sprite:
		return
	# Strip art is ~205px wide per tool; body is ~16px * body_visual_scale — match that order of magnitude.
	var s := clampf(body_visual_scale * held_tool_scale_coefficient, 0.12, 0.42)
	_tool_sprite.scale = Vector2(s, s)

func _physics_process(delta: float) -> void:
	_time_alive += delta
	var move_x := Input.get_axis("move_left", "move_right")
	_last_move_x = move_x
	var input_vector := Vector2(move_x, 0.0)
	if _manager and not _manager.player_alive:
		input_vector = Vector2.ZERO
		move_x = 0.0
	if _manager and _manager.has_method("set_player_moving"):
		_manager.set_player_moving(absf(move_x) > 0.05)
	_move_character(move_x, delta)
	_update_tool_selection()
	_action_timer = maxf(0.0, _action_timer - delta)
	if input_vector.length() > 0.05 and _action_timer <= 0.0:
		_action_state = "walk"
	elif _action_timer <= 0.0:
		_action_state = "idle"
	_update_visuals(input_vector)

	_gather_timer = maxf(0.0, _gather_timer - delta)
	_place_cooldown = maxf(0.0, _place_cooldown - delta)
	if Input.is_action_just_pressed("mine_block") and _gather_timer <= 0.0:
		_gather_timer = gather_cooldown_seconds
		_handle_mine()
	elif Input.is_action_pressed("mine_block") and _gather_timer <= 0.0:
		_gather_timer = gather_cooldown_seconds
		_handle_mine()
	if Input.is_action_just_pressed("interact") and _gather_timer <= 0.0:
		_gather_timer = gather_cooldown_seconds
		_handle_interact()
	if Input.is_action_just_pressed("feed_bob"):
		_try_feed_bob()
	if Input.is_action_just_pressed("cycle_place_kind"):
		_cycle_place_kind()
	if Input.is_action_just_pressed("place_block"):
		_place_cooldown = 0.12
		_try_place_block_under_cursor()
	elif Input.is_action_pressed("place_block") and _place_cooldown <= 0.0:
		_place_cooldown = 0.16
		_try_place_block_under_cursor()
	if Input.is_action_just_pressed("place_totem"):
		_try_place_totem()

func get_hint_text() -> String:
	return _last_hint

func _handle_interact() -> void:
	if not _manager:
		return

	if _selected_tool == "hoe":
		if _try_hoe_crop_actions():
			return

	var node := _find_nearest_group_node("resource_nodes")
	if node and node.has_method("gather"):
		var result: Dictionary = node.gather(_selected_tool, _tool_gather_power(_selected_tool))
		_set_action("mine", 0.35)
		if int(result.get("amount", 0)) > 0:
			_manager.collect_for_player_resource(str(result.get("kind", "wood")), int(result["amount"]))
			_last_hint = "Gathered %s x%d." % [str(result.get("kind", "resource")), int(result["amount"])]
		elif str(result.get("message", "")) != "":
			_last_hint = str(result["message"])
		else:
			var pct := int(float(result.get("progress", 0.0)) * 100.0)
			_last_hint = "Mining... %d%%" % pct
		return

	node = _find_nearest_group_node("crops")
	if node:
		_last_hint = "You need a hoe to harvest plants and get seeds."
		return

	node = _find_nearest_group_node("tilled_patches")
	if node and not node.get("has_crop"):
		_last_hint = "Use a hoe here to plant seeds."
		return

	node = _find_nearest_group_node("chests")
	if node and node.has_method("loot"):
		var loot: int = node.loot()
		_set_action("collect", 0.35)
		if loot > 0:
			_manager.collect_for_player_resource("food", loot)
			_last_hint = "Looted chest for %d supplies." % loot
		else:
			_last_hint = "Chest is empty."
		return

	node = _find_nearest_group_node("doors")
	if node and node.has_method("toggle"):
		node.toggle()
		_set_action("collect", 0.25)
		_last_hint = "You toggled the door."
		return

	if _attack_hostile_nearby():
		return

	_last_hint = "Nothing nearby to interact with."

func _handle_mine() -> void:
	# Left-click: mine what the cursor is pointing at (tile or tree).
	if _try_mine_tile_under_cursor():
		_set_action("mine", 0.22)
		return
	if _try_mine_resource_under_cursor():
		_set_action("mine", 0.28)
		return

func _try_mine_resource_under_cursor() -> bool:
	var cursor_world := get_global_mouse_position()
	var player_feet := global_position + Vector2(0, surface_foot_offset)
	if player_feet.distance_to(cursor_world) > tile_mine_reach + 22.0:
		return false
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = cursor_world
	query.collide_with_areas = true
	query.collide_with_bodies = false
	# 16 results is enough for our simple scenes.
	var hits: Array = space.intersect_point(query, 16)
	for h in hits:
		var col_obj: Object = h.get("collider")
		if col_obj and (col_obj is Node) and (col_obj as Node).is_in_group("resource_nodes") and (col_obj as Node).has_method("gather"):
			var node := col_obj as Node
			var result: Dictionary = node.gather(_selected_tool, _tool_gather_power(_selected_tool))
			if int(result.get("amount", 0)) > 0 and _manager:
				_manager.collect_for_player_resource(str(result.get("kind", "wood")), int(result["amount"]))
				_last_hint = "Gathered %s x%d." % [str(result.get("kind", "resource")), int(result["amount"])]
			elif str(result.get("message", "")) != "":
				_last_hint = str(result["message"])
			else:
				var pct := int(float(result.get("progress", 0.0)) * 100.0)
				_last_hint = "Mining... %d%%" % pct
			return true
	return false

func _attack_hostile_nearby() -> bool:
	if _selected_tool == "hoe":
		return false
	var monster := _find_nearest_group_node("monsters")
	if monster and monster.has_method("receive_damage") and global_position.distance_to((monster as Node2D).global_position) <= 72.0:
		monster.receive_damage(_tool_combat_damage(_selected_tool))
		_set_action("mine", 0.24)
		_last_hint = "Hit monster with %s." % _selected_tool
		return true
	var bob := _find_nearest_group_node("bob_agent")
	if bob and bob.has_method("receive_damage"):
		var bob_dist := global_position.distance_to((bob as Node2D).global_position)
		if bob_dist > 82.0:
			return false
		if _selected_tool == "sword":
			bob.receive_damage(_tool_combat_damage(_selected_tool) * 0.4)
			_set_action("mine", 0.2)
			_last_hint = "You hit B.O.B. with the sword — heavy discipline."
			if _manager:
				_manager.suppress_bob_sabotage_for(2.2)
			return true
		if _selected_tool == "pickaxe" or _selected_tool == "axe" or _selected_tool == "shovel":
			bob.receive_damage(_tool_combat_damage(_selected_tool) * 0.2)
			_set_action("mine", 0.22)
			_last_hint = "Bonked B.O.B. with the %s — he backs off your pack briefly." % _selected_tool
			if _manager:
				_manager.suppress_bob_sabotage_for(1.6)
			return true
	return false

func _try_hoe_crop_actions() -> bool:
	var crop := _find_nearest_group_node("crops")
	if crop and crop.has_method("harvest"):
		var harvest_result: Dictionary = crop.harvest(true)
		var food_gain := int(harvest_result.get("food", 0))
		var seed_gain := int(harvest_result.get("seeds", 0))
		if food_gain > 0:
			_manager.collect_for_player_resource("food", food_gain)
			_manager.collect_for_player_resource("seeds", seed_gain)
			_set_action("collect", 0.45)
			_last_hint = "Harvested with hoe (+%d food, +%d seeds)." % [food_gain, seed_gain]
		else:
			_last_hint = "Crop is regrowing..."
		return true

	var patch := _find_nearest_group_node("tilled_patches")
	if patch and not patch.get("has_crop"):
		if _manager.inventory["seeds"] <= 0:
			_last_hint = "No seeds available. Harvest crops first."
			return true
		_manager.inventory["seeds"] -= 1
		var planted := _crop_scene.instantiate() as Area2D
		planted.position = (patch as Node2D).global_position + Vector2(0, -26)
		get_tree().current_scene.get_node("Crops").add_child(planted)
		patch.set_has_crop(true)
		_set_action("collect", 0.35)
		_last_hint = "Planted crop seed."
		return true

	_create_tilled_patch()
	_set_action("collect", 0.28)
	_last_hint = "Tilled soil patch created."
	return true

func _create_tilled_patch() -> void:
	var forward := -44.0 if ($Body as Sprite2D).scale.x < 0.0 else 44.0
	var target := global_position + Vector2(forward, 30)
	var snapped := Vector2(round(target.x / 48.0) * 48.0, round(target.y / 32.0) * 32.0)
	for n in get_tree().get_nodes_in_group("tilled_patches"):
		if (n as Node2D).global_position.distance_to(snapped) < 28.0:
			return
	var patch := _tilled_scene.instantiate() as Area2D
	patch.global_position = snapped
	get_tree().current_scene.get_node("TilledPatches").add_child(patch)

func _find_nearest_group_node(group_name: String) -> Node2D:
	var nearest: Node2D
	var best_distance := interact_radius
	for item in get_tree().get_nodes_in_group(group_name):
		if not (item is Node2D):
			continue
		var node := item as Node2D
		var distance := global_position.distance_to(node.global_position)
		if distance <= best_distance:
			best_distance = distance
			nearest = node
	return nearest

func _update_visuals(input_vector: Vector2) -> void:
	var body := $Body as Sprite2D
	var held_tool := $HeldTool as Node2D
	var gather_fx := $GatherFx as Polygon2D
	var base_scale := body_visual_scale
	if not body:
		return
	if held_tool and _manager:
		held_tool.visible = _manager.inventory["pickaxe"] > 0 or _manager.inventory["axe"] > 0 or _manager.inventory["sword"] > 0 or _manager.inventory["hoe"] > 0 or _manager.inventory["shovel"] > 0
		if _selected_tool == "pickaxe" and _manager.inventory["pickaxe"] <= 0:
			_selected_tool = "axe" if _manager.inventory["axe"] > 0 else ("sword" if _manager.inventory["sword"] > 0 else ("shovel" if _manager.inventory["shovel"] > 0 else ("hoe" if _manager.inventory["hoe"] > 0 else "shovel")))
		if _selected_tool == "axe" and _manager.inventory["axe"] <= 0:
			_selected_tool = "pickaxe" if _manager.inventory["pickaxe"] > 0 else ("sword" if _manager.inventory["sword"] > 0 else ("shovel" if _manager.inventory["shovel"] > 0 else ("hoe" if _manager.inventory["hoe"] > 0 else "shovel")))
		if _selected_tool == "sword" and _manager.inventory["sword"] <= 0:
			_selected_tool = "pickaxe" if _manager.inventory["pickaxe"] > 0 else ("axe" if _manager.inventory["axe"] > 0 else ("shovel" if _manager.inventory["shovel"] > 0 else ("hoe" if _manager.inventory["hoe"] > 0 else "shovel")))
		if _selected_tool == "hoe" and _manager.inventory["hoe"] <= 0:
			_selected_tool = "pickaxe" if _manager.inventory["pickaxe"] > 0 else ("axe" if _manager.inventory["axe"] > 0 else ("sword" if _manager.inventory["sword"] > 0 else ("shovel" if _manager.inventory["shovel"] > 0 else "hoe")))
		if _selected_tool == "shovel" and _manager.inventory["shovel"] <= 0:
			_selected_tool = "pickaxe" if _manager.inventory["pickaxe"] > 0 else ("axe" if _manager.inventory["axe"] > 0 else ("sword" if _manager.inventory["sword"] > 0 else ("hoe" if _manager.inventory["hoe"] > 0 else "shovel")))
	if input_vector.length() > 0.05:
		body.scale.x = -(base_scale * body_width_scale) if input_vector.x < 0.0 else (base_scale * body_width_scale)
		body.position.y = sin(_time_alive * 14.0) * 2.0
		body.rotation = sin(_time_alive * 18.0) * 0.04
		body.scale.y = base_scale + sin(_time_alive * 18.0) * 0.03
	else:
		body.position.y = sin(_time_alive * 4.0) * 1.0
		body.rotation = sin(_time_alive * 6.0) * 0.01
		body.scale.y = base_scale

	if held_tool:
		held_tool.position.x = -18.0 if body.scale.x < 0.0 else 18.0
		held_tool.position.y = body.position.y + 5.0
		held_tool.scale.x = -1.0 if body.scale.x < 0.0 else 1.0
		held_tool.rotation = 0.0
		if _action_state == "mine":
			held_tool.rotation = sin(_time_alive * 28.0) * 0.9
		elif _action_state == "collect":
			held_tool.rotation = sin(_time_alive * 16.0) * 0.25
		elif _action_state == "feed":
			held_tool.rotation = -0.35 + sin(_time_alive * 22.0) * 0.12
		elif _action_state == "craft":
			held_tool.rotation = sin(_time_alive * 24.0) * 0.5
	if gather_fx:
		gather_fx.position.x = -24.0 if body.scale.x < 0.0 else 24.0
		# Mine swing uses the strip tool sprite; keep sparkle only for "collect" to avoid a smeared shape near the head.
		gather_fx.visible = _action_state == "collect"
		if gather_fx.visible:
			gather_fx.rotation = sin(_time_alive * 36.0) * 0.5
			gather_fx.scale = Vector2(0.8 + absf(sin(_time_alive * 20.0)) * 0.5, 0.8)
	if _held_tool_atlas and _tool_sprite:
		_held_tool_atlas.region = ToolStripIcons.region_for_tool(_selected_tool)
		if _action_state == "craft":
			_tool_sprite.modulate = Color(0.87, 0.76, 0.42, 1.0)
		else:
			_tool_sprite.modulate = Color.WHITE

func _set_action(new_action: String, duration: float) -> void:
	_action_state = new_action
	_action_timer = duration

func _try_feed_bob() -> void:
	if not _manager:
		return
	var bob := _find_nearest_group_node("bob_agent")
	if not bob:
		_last_hint = "B.O.B. is not nearby."
		return
	var fed_amount: int = _manager.take_player_food(1)
	var snack_amount: int = _manager.take_bob_snack(1)
	if snack_amount > 0:
		fed_amount = snack_amount + 1
	if fed_amount <= 0:
		_last_hint = "No food/snacks to feed B.O.B."
		return
	if bob.has_method("receive_food"):
		bob.receive_food(fed_amount)
	if _manager:
		_manager.suppress_bob_sabotage_for(3.2)
	_set_action("feed", 0.4)
	_last_hint = "Fed B.O.B. — calmer, and he won't rifle your pack for a few seconds."

func get_selected_tool() -> String:
	return _selected_tool

func apply_debug_default_tool() -> void:
	if _manager and int(_manager.inventory.get("pickaxe", 0)) > 0:
		_selected_tool = "pickaxe"

func get_last_move_x() -> float:
	return _last_move_x

func apply_bob_shove(direction_x: float, strength: float = 300.0) -> void:
	var d := signf(direction_x)
	if d == 0.0:
		d = 1.0
	_knockback_velocity.x = clampf(_knockback_velocity.x + d * strength, -540.0, 540.0)

func _update_tool_selection() -> void:
	var keys: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
	var names: Array[String] = ["sword", "pickaxe", "axe", "shovel", "hoe"]
	for i in range(5):
		var down := Input.is_physical_key_pressed(keys[i])
		if down and not _tool_number_latch[i]:
			_selected_tool = names[i]
		_tool_number_latch[i] = down

func _move_character(move_x: float, delta: float) -> void:
	if not _world_tiles:
		global_position.x += move_x * move_speed * delta + _knockback_velocity.x * delta
		_knockback_velocity.x = move_toward(_knockback_velocity.x, 0.0, 880.0 * delta)
		return
	if absf(_knockback_velocity.x) > 0.4:
		var kdx := _knockback_velocity.x * delta
		if absf(kdx) > 0.001 and not _would_hit_side(kdx):
			global_position.x += kdx
		_knockback_velocity.x = move_toward(_knockback_velocity.x, 0.0, 920.0 * delta)
	var dx := move_x * move_speed * delta
	if absf(dx) > 0.001 and not _would_hit_side(dx):
		global_position.x += dx

	_is_grounded = _has_floor_beneath()
	if _is_grounded and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up")):
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

func _try_mine_tile_under_cursor() -> bool:
	if not _world_tiles or not _world_tiles.has_method("world_to_cell"):
		return false
	var cursor_world := get_global_mouse_position()
	var player_feet := global_position + Vector2(0, surface_foot_offset)
	if player_feet.distance_to(cursor_world) > tile_mine_reach:
		_last_hint = "Block is out of mining reach."
		return false
	var target_cell: Vector2i = _world_tiles.world_to_cell(cursor_world)
	if not _world_tiles.is_solid_cell(target_cell):
		_last_hint = "Point at a solid block."
		return false
	var player_cell: Vector2i = _world_tiles.world_to_cell(player_feet)
	if not _is_target_within_local_mine_range(player_cell, target_cell):
		_last_hint = "Block is out of mining reach."
		return false
	var aim_origin := global_position + Vector2(0.0, (collider_head_offset + surface_foot_offset) * 0.5)
	if _is_blocked_line_to_target_world(aim_origin, target_cell):
		_last_hint = "That block is blocked from here."
		return false
	var tier_mult := 1.0
	if _manager and _manager.has_method("get_tool_mining_multiplier"):
		tier_mult = float(_manager.get_tool_mining_multiplier(_selected_tool))
	var result: Dictionary = _world_tiles.try_mine_cell(target_cell, _selected_tool, tier_mult)
	if not bool(result.get("ok", false)):
		var reason := str(result.get("reason", ""))
		if reason == "needs_pickaxe":
			_last_hint = "Reinforced wall needs a pickaxe."
		elif reason == "empty":
			_last_hint = "No block there."
		elif reason == "hazard":
			_last_hint = "Cannot mine that block."
		return false
	if bool(result.get("mined", false)):
		var drops: Array = result.get("drops", [])
		var primary_kind := ""
		for drop in drops:
			var kind := str(drop.get("kind", ""))
			var amount := int(drop.get("amount", 0))
			if amount > 0 and kind != "":
				_manager.collect_for_player_resource(kind, amount)
				if primary_kind == "":
					primary_kind = kind
		if primary_kind == "":
			primary_kind = str(result.get("drop_kind", ""))
		_last_hint = "Mined %s block." % (primary_kind if primary_kind != "" else "terrain")
	else:
		var pct := int(float(result.get("progress", 0.0)) * 100.0)
		_last_hint = "Mining block... %d%%" % pct
	return true

func get_place_kind() -> String:
	return _place_kind

func _cycle_place_kind() -> void:
	if _place_kinds.is_empty():
		return
	var idx := _place_kinds.find(_place_kind)
	idx = (idx + 1) % _place_kinds.size()
	_place_kind = _place_kinds[idx]
	_last_hint = "Place material: %s" % _place_kind

func _try_place_block_under_cursor() -> bool:
	if not _world_tiles or not _manager:
		return false
	_select_available_place_kind_if_needed()
	if not _manager.inventory.has(_place_kind):
		_manager.inventory[_place_kind] = 0
	if int(_manager.inventory[_place_kind]) <= 0:
		_last_hint = "Out of placeable blocks. Mine dirt/grass/stone first."
		return false
	var cursor_world := get_global_mouse_position()
	var player_feet := global_position + Vector2(0, surface_foot_offset)
	if player_feet.distance_to(cursor_world) > tile_mine_reach + 16.0:
		_last_hint = "Too far to place."
		return false
	var hovered_cell: Vector2i = _world_tiles.world_to_cell(cursor_world)
	var target_cell: Vector2i = _resolve_place_target_cell(hovered_cell)
	if target_cell == Vector2i(-9999, -9999):
		_last_hint = "No valid nearby slot to place."
		return false
	var player_cell: Vector2i = _world_tiles.world_to_cell(player_feet)
	if not _is_target_within_local_mine_range(player_cell, target_cell):
		_last_hint = "Place target out of range."
		return false
	var result: Dictionary = _world_tiles.try_place_cell(target_cell, _place_kind)
	if not bool(result.get("ok", false)):
		var reason := str(result.get("reason", ""))
		match reason:
			"no_support":
				_last_hint = "Need a solid block next to your placement."
			"actor_overlap":
				_last_hint = "Cannot place inside a creature."
			"out_of_bounds":
				_last_hint = "Out of bounds."
			_:
				_last_hint = "Placement blocked."
		return false
	_manager.inventory[_place_kind] = int(_manager.inventory[_place_kind]) - 1
	if _manager.has_method("notify_inventory_changed"):
		_manager.call("notify_inventory_changed")
	_last_hint = "Placed %s." % _place_kind
	return true

func _select_available_place_kind_if_needed() -> void:
	if not _manager:
		return
	var current_count := int(_manager.inventory.get(_place_kind, 0))
	if current_count > 0:
		return
	for k in _place_kinds:
		if int(_manager.inventory.get(k, 0)) > 0:
			_place_kind = k
			return

func _resolve_place_target_cell(hovered_cell: Vector2i) -> Vector2i:
	# Placement behavior:
	# - If cursor points at an empty cell, place there directly.
	# - If cursor points at a solid cell, place only on the top face.
	# This keeps behavior predictable (no side/below snap surprises).
	if not _world_tiles.is_solid_cell(hovered_cell):
		return hovered_cell
	var above := Vector2i(hovered_cell.x, hovered_cell.y - 1)
	if not _world_tiles.is_solid_cell(above):
		return above
	return Vector2i(-9999, -9999)

func _try_place_totem() -> bool:
	if not _manager:
		return false
	if int(_manager.inventory.get("totems", 0)) <= 0:
		_last_hint = "No Calm Totems crafted."
		return false
	var totem := _totem_scene.instantiate() as Node2D
	if not totem:
		return false
	var face := signf(_last_move_x)
	if face == 0.0:
		face = 1.0
	var spawn := global_position + Vector2(40.0 * face, surface_foot_offset - 12.0)
	get_parent().add_child(totem)
	totem.global_position = spawn
	_manager.inventory["totems"] = int(_manager.inventory["totems"]) - 1
	_last_hint = "Calm Totem placed. B.O.B. inside its aura turns friendly."
	return true

func _is_target_within_local_mine_range(player_cell: Vector2i, target_cell: Vector2i) -> bool:
	var dx := absi(target_cell.x - player_cell.x)
	var dy := target_cell.y - player_cell.y
	if dx > tile_mine_cell_range_x:
		return false
	if dy < -tile_mine_cell_range_up:
		return false
	if dy > tile_mine_cell_range_down:
		return false
	return true

func _mine_los_body_cells() -> Array[Vector2i]:
	var feet: Vector2i = _world_tiles.world_to_cell(global_position + Vector2(0.0, surface_foot_offset))
	return [feet, Vector2i(feet.x, feet.y - 1), Vector2i(feet.x, feet.y - 2)]


func _is_blocked_line_to_target_world(start_world: Vector2, target_cell: Vector2i) -> bool:
	var target_world: Vector2 = _world_tiles.get_cell_world_center(target_cell)
	var travel: Vector2 = target_world - start_world
	var distance: float = travel.length()
	if distance <= 0.01:
		return false
	var direction: Vector2 = travel / distance
	var skip_body := _mine_los_body_cells()
	var step: float = 5.0
	var sample: float = step
	while sample < distance - step * 0.35:
		var probe: Vector2 = start_world + direction * sample
		var probe_cell: Vector2i = _world_tiles.world_to_cell(probe)
		if probe_cell == target_cell:
			sample += step
			continue
		if skip_body.has(probe_cell):
			sample += step
			continue
		if _world_tiles.is_solid_cell(probe_cell):
			return true
		sample += step
	return false

func _tool_gather_power(tool: String) -> float:
	var base: float
	match tool:
		"pickaxe":
			base = 1.3
		"axe":
			base = 1.3
		"sword":
			base = 0.7
		"hoe":
			base = 1.0
		"shovel":
			base = 1.7
		_:
			base = 1.0
	var eff := 1.0
	if _manager and _manager.has_method("get_tool_effectiveness_multiplier"):
		eff = float(_manager.get_tool_effectiveness_multiplier(tool))
	return base * eff

func _tool_combat_damage(tool: String) -> float:
	var base: float
	match tool:
		"pickaxe":
			base = 12.0
		"axe":
			base = 10.0
		"sword":
			base = 16.0
		"hoe":
			base = 7.0
		"shovel":
			base = 8.0
		_:
			base = 6.0
	var eff := 1.0
	if _manager and _manager.has_method("get_tool_effectiveness_multiplier"):
		eff = float(_manager.get_tool_effectiveness_multiplier(tool))
	return base * eff
