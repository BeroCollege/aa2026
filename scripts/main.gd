extends Node2D
## Pause UX: **Escape (ui_cancel)** closes the craft menu if it is open; otherwise it opens the pause menu.
## While paused, **Escape** or **Resume** closes the menu and unpauses (`get_tree().paused = false`).
## Craft is opened with **C / F (craft_tool)** only when the pause menu is closed.

@onready var _manager = $GameManager
@onready var _bob: CharacterBody2D = $Bob
@onready var _player: CharacterBody2D = $Player
@onready var _door: Area2D = $Door
@onready var _chest: Area2D = $Chest
@onready var _hazard: Area2D = $HazardZone
@onready var _starter_crop_a: Area2D = $StarterCropA
@onready var _starter_crop_b: Area2D = $StarterCropB
@onready var _world_tiles: TileMapLayer = $WorldTiles
@onready var _night_overlay: ColorRect = $CanvasLayer/NightOverlay
@onready var _resource_container: Node2D = $Resources
@onready var _crop_container: Node2D = $Crops
@onready var _tilled_container: Node2D = $TilledPatches
@onready var _deco_container: Node2D = $Decorations
@onready var _restart_button: Button = $CanvasLayer/RestartButton
@onready var _craft_menu: Panel = $CanvasLayer/CraftMenu
@onready var _craft_feedback: Label = $CanvasLayer/CraftMenu/CraftFeedback
@onready var _clock_label: Label = $CanvasLayer/ClockLabel
@onready var _pause_menu: Panel = $CanvasLayer/PauseMenu
@onready var _pause_best_label: Label = $CanvasLayer/PauseMenu/VBox/BestLabel
@onready var _pause_current_label: Label = $CanvasLayer/PauseMenu/VBox/CurrentLabel
@onready var _pause_keybinds_label: Label = $CanvasLayer/PauseMenu/VBox/Scroll/KeybindsLabel
@onready var _pause_resume_button: Button = $CanvasLayer/PauseMenu/VBox/ResumeButton
@onready var _status_panel: Panel = $CanvasLayer/StatusPanel
@onready var _slot_wood: Label = $CanvasLayer/MaterialCounter/WoodCount
@onready var _slot_stone: Label = $CanvasLayer/MaterialCounter/StoneCount
@onready var _slot_food: Label = $CanvasLayer/MaterialCounter/FoodCount
@onready var _slot_sword: Label = $CanvasLayer/Hotbar/SlotSword/Count
@onready var _slot_pickaxe: Label = $CanvasLayer/Hotbar/SlotPickaxe/Count
@onready var _slot_axe: Label = $CanvasLayer/Hotbar/SlotAxe/Count
@onready var _slot_shovel: Label = $CanvasLayer/Hotbar/SlotShovel/Count
@onready var _slot_hoe: Label = $CanvasLayer/Hotbar/SlotHoe/Count
@onready var _slot_seeds: Label = $CanvasLayer/MaterialCounter/SeedsCount
@onready var _panel_sword: Panel = $CanvasLayer/Hotbar/SlotSword
@onready var _panel_pickaxe: Panel = $CanvasLayer/Hotbar/SlotPickaxe
@onready var _panel_axe: Panel = $CanvasLayer/Hotbar/SlotAxe
@onready var _panel_shovel: Panel = $CanvasLayer/Hotbar/SlotShovel
@onready var _panel_hoe: Panel = $CanvasLayer/Hotbar/SlotHoe
@onready var _world_bounds: StaticBody2D = $WorldBounds

var _heart_full: Texture2D = preload("res://assets/ui/heart_full_ui16.png")
var _heart_empty: Texture2D = preload("res://assets/ui/heart_empty_ui16.png")
var _hunger_full: Texture2D = preload("res://assets/ui/hunger_full_ui16.png")
var _hunger_empty: Texture2D = preload("res://assets/ui/hunger_empty_ui16.png")
var _debug_label: Label
var _bob_debug_label: Label
var _overhead_hud: Dictionary = {}
var _background_root: Node2D
var _farlands_layer: Node2D
var _clouds_layer: Node2D
var _craft_shovel_key_latch: bool = false
## After death, best survival is written once per run (see RunRecords).
var _run_best_recorded: bool = false
## Elapsed survival time for the current run; frozen while player is dead.
var _survival_sec: float = 0.0
## Last displayed decisecond bucket so the label updates at most every 0.1s.
var _survival_last_display_bucket: int = -1
var _place_indicator: Label
var _slot_dirt_label: Label
var _slot_grass_label: Label
var _slot_reinforced_label: Label
var _slot_totems_label: Label
var _craft_shovel_button: Button
var _craft_totem_button: Button
var _craft_reinforced_button: Button
var _upgrade_pickaxe_button: Button
var _upgrade_axe_button: Button
var _upgrade_sword_button: Button
var _upgrade_hoe_button: Button
var _upgrade_shovel_button: Button
var _cloud_textures: Array[Texture2D] = [
	preload("res://assets/blockpack/clouds/cloud_1.png"),
	preload("res://assets/blockpack/clouds/cloud_2.png"),
	preload("res://assets/blockpack/clouds/cloud_3.png"),
	preload("res://assets/blockpack/clouds/cloud_4.png"),
]
## Throttles disk writes while the current run is beating the stored best.
var _best_autosave_timer: float = 0.0

func _configure_infinite_world_bounds() -> void:
	var left_shape := _world_bounds.get_node_or_null("CollisionShapeLeft") as CollisionShape2D
	var right_shape := _world_bounds.get_node_or_null("CollisionShapeRight") as CollisionShape2D
	if left_shape:
		left_shape.disabled = true
	if right_shape:
		right_shape.disabled = true
	var sky := get_node_or_null("Ground") as ColorRect
	if sky:
		sky.offset_left = -5_000_000.0
		sky.offset_right = 5_000_000.0

func _process(delta: float) -> void:
	_night_overlay.visible = _manager.is_night
	var paused := get_tree().paused
	if _manager.player_alive and not paused:
		_survival_sec += delta
		_best_autosave_timer += delta
		if _best_autosave_timer >= 2.0:
			_best_autosave_timer = 0.0
			RunRecords.commit_best_if_greater(_survival_sec)
	var bucket := int(floor(_survival_sec * 10.0))
	if bucket != _survival_last_display_bucket:
		_survival_last_display_bucket = bucket
		_refresh_survival_clock_label()
	if Input.is_action_just_pressed("toggle_debug_mode"):
		_manager.debug_mode_enabled = not _manager.debug_mode_enabled
		if _manager.debug_mode_enabled and _player and _player.has_method("apply_debug_default_tool"):
			_player.apply_debug_default_tool()
	_update_debug_label()
	_update_bob_debug_label()
	_update_status_icons()
	_update_hotbar_counts()
	_update_hotbar_selection()

	# Escape / ui_cancel: craft open → close craft only; else → toggle pause (see pause_menu.gd when tree paused).
	if _craft_menu.visible:
		if Input.is_action_just_pressed("craft_tool") or Input.is_action_just_pressed("ui_cancel"):
			_close_craft_menu()
	elif not _pause_menu.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			_open_pause_menu()
		elif Input.is_action_just_pressed("craft_tool"):
			_toggle_craft_menu()
	if _craft_menu.visible:
		# 1–5 select tools; use 6 to craft shovel while this menu is open.
		var shovel_key_down := Input.is_physical_key_pressed(KEY_6)
		if shovel_key_down and not _craft_shovel_key_latch:
			_on_craft_shovel_pressed()
		_craft_shovel_key_latch = shovel_key_down
	else:
		_craft_shovel_key_latch = false

	if not _manager.player_alive:
		if not _run_best_recorded:
			_run_best_recorded = true
			RunRecords.commit_best_if_greater(_survival_sec)
		_restart_button.visible = true
	else:
		_run_best_recorded = false
		_restart_button.visible = false

func _physics_process(_delta: float) -> void:
	if _world_tiles:
		var ax := minf(_player.global_position.x, _bob.global_position.x)
		var bx := maxf(_player.global_position.x, _bob.global_position.x)
		_world_tiles.ensure_streaming_around_world(ax, bx)

func _ready() -> void:
	_configure_infinite_world_bounds()
	_create_background_layers()
	# Keep baseline world clean/flat for now: trees only, no extra surface clutter.
	_spawn_decorations()
	_snap_core_actors_to_surface()
	_snap_world_props_to_surface()
	# Back-to-basics world: flat terrain only, no extra world clutter.
	_door.visible = false
	_chest.visible = false
	_hazard.visible = false
	_starter_crop_a.visible = false
	_starter_crop_b.visible = false
	_restart_button.pressed.connect(_on_restart_pressed)
	_restart_button.visible = false
	_craft_menu.visible = false
	$CanvasLayer/CraftMenu/CraftToolButton.pressed.connect(_on_craft_tool_pressed)
	$CanvasLayer/CraftMenu/CraftAxeButton.pressed.connect(_on_craft_axe_pressed)
	$CanvasLayer/CraftMenu/CraftSwordButton.pressed.connect(_on_craft_sword_pressed)
	$CanvasLayer/CraftMenu/CraftHoeButton.pressed.connect(_on_craft_hoe_pressed)
	$CanvasLayer/CraftMenu/CraftSnackButton.pressed.connect(_on_craft_snack_pressed)
	$CanvasLayer/CraftMenu/CraftMealButton.pressed.connect(_on_craft_meal_pressed)
	$CanvasLayer/CraftMenu/CloseCraftButton.pressed.connect(_close_craft_menu)
	_status_panel.visible = false
	_create_overhead_status(_player)
	_create_overhead_status(_bob)
	_create_debug_label()
	_update_debug_label()
	_create_bob_debug_label()
	_update_bob_debug_label()
	_extend_material_counter_ui()
	_extend_craft_menu_ui()
	_apply_tool_strip_icons()
	_pause_menu.visible = false
	get_tree().paused = false
	_pause_keybinds_label.text = _build_keybinds_help()
	_pause_menu.resume_requested.connect(_close_pause_menu)
	_pause_resume_button.pressed.connect(_close_pause_menu)
	if _manager.debug_mode_enabled and _player.has_method("apply_debug_default_tool"):
		call_deferred("_deferred_debug_default_tool")
	_reset_survival_timer()

func _reset_survival_timer() -> void:
	_survival_sec = 0.0
	_survival_last_display_bucket = -1
	_refresh_survival_clock_label()

func _refresh_survival_clock_label() -> void:
	if not _clock_label:
		return
	_clock_label.text = "Survived: %s" % _format_run_time(_survival_sec)

func _deferred_debug_default_tool() -> void:
	if _manager.debug_mode_enabled and _player.has_method("apply_debug_default_tool"):
		_player.apply_debug_default_tool()

func _apply_tool_strip_icons() -> void:
	var hotbar := {
		"sword": "CanvasLayer/Hotbar/SlotSword/Icon",
		"pickaxe": "CanvasLayer/Hotbar/SlotPickaxe/Icon",
		"axe": "CanvasLayer/Hotbar/SlotAxe/Icon",
		"shovel": "CanvasLayer/Hotbar/SlotShovel/Icon",
		"hoe": "CanvasLayer/Hotbar/SlotHoe/Icon",
	}
	for k in hotbar:
		var hot_icon := get_node_or_null(hotbar[k]) as TextureRect
		if hot_icon:
			hot_icon.texture = ToolStripIcons.atlas_texture_for_tool(k)
	var craft := {
		"pickaxe": "CanvasLayer/CraftMenu/CraftToolIcon",
		"axe": "CanvasLayer/CraftMenu/CraftAxeIcon",
		"sword": "CanvasLayer/CraftMenu/CraftSwordIcon",
		"hoe": "CanvasLayer/CraftMenu/CraftHoeIcon",
	}
	for c in craft:
		var craft_icon := get_node_or_null(craft[c]) as TextureRect
		if craft_icon:
			craft_icon.texture = ToolStripIcons.atlas_texture_for_tool(c)

func _create_background_layers() -> void:
	if _background_root:
		return
	_background_root = Node2D.new()
	_background_root.name = "BackgroundWorld"
	add_child(_background_root)
	# Ensure background is above sky fill, but behind terrain/entities.
	move_child(_background_root, 2)

	_farlands_layer = Node2D.new()
	_farlands_layer.name = "Farlands"
	_background_root.add_child(_farlands_layer)

	_clouds_layer = Node2D.new()
	_clouds_layer.name = "Clouds"
	_background_root.add_child(_clouds_layer)

	# Farlands paused by request; keep layer hidden for easy re-enable later.
	_farlands_layer.visible = false
	_spawn_clouds_background()

func _spawn_farlands_background() -> void:
	if not _world_tiles or not _farlands_layer:
		return
	var grass_tex: Texture2D = load("res://assets/blockpack/tile_grass.png")
	var dirt_tex: Texture2D = load("res://assets/blockpack/tile_dirt.png")
	if not grass_tex or not dirt_tex:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 987654
	var world_width: float = 8960.0
	var far_scale: float = 0.16
	var block_px: float = 64.0 * far_scale
	var cols_total: int = int(world_width / block_px)
	var world_surface_y: float = _world_tiles.get_surface_world_position_at_x(0.0).y
	var horizon_base: float = world_surface_y - 300.0
	# Keep farlands noticeably thinner than before so they feel distant.
	var far_floor_y: float = world_surface_y + 150.0
	var top_y: float = horizon_base
	var col: int = 0
	while col < cols_total:
		var segment_len: int = rng.randi_range(26, 72)
		var segment_step: int = rng.randi_range(-2, 2)
		if segment_step == 0 and rng.randf() < 0.45:
			segment_step = 1 if rng.randf() < 0.5 else -1
		# Gentle hilly band with modest peak/trough range.
		top_y = clampf(top_y + float(segment_step) * block_px, horizon_base - 70.0, horizon_base + 55.0)
		for local_i in range(segment_len):
			if col >= cols_total:
				break
			var x := float(col) * block_px
			var y := top_y
			_add_background_block(_farlands_layer, grass_tex, Vector2(x, y), Color(0.66, 0.86, 0.72, 0.60), far_scale)
			var depth_blocks: int = maxi(1, int((far_floor_y - y) / block_px))
			for d in range(depth_blocks):
				_add_background_block(
					_farlands_layer,
					dirt_tex,
					Vector2(x, y + float(d + 1) * block_px),
					Color(0.55, 0.42, 0.30, 0.46),
					far_scale
				)
			col += 1

func _spawn_clouds_background() -> void:
	if not _clouds_layer:
		return
	for child in _clouds_layer.get_children():
		child.queue_free()
	var span_world_x := 900_000.0
	var spacing := 4500.0
	var cloud_count := mini(220, int(ceil(span_world_x / spacing)))
	var world_surface_y: float = 980.0
	if _world_tiles:
		world_surface_y = _world_tiles.get_surface_world_position_at_x(0.0).y
	var min_cloud_y := world_surface_y - 560.0
	var max_cloud_y := world_surface_y - 260.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 13579
	for i in range(cloud_count):
		var base_x := -span_world_x * 0.5 + float(i) * spacing + rng.randf_range(-160.0, 160.0)
		var base_pos := Vector2(base_x, rng.randf_range(min_cloud_y, max_cloud_y))
		var s := rng.randf_range(0.28, 0.42)
		if _cloud_textures.is_empty():
			var fallback := ColorRect.new()
			fallback.color = Color(1.0, 1.0, 1.0, 0.92)
			fallback.size = Vector2(180.0, 64.0)
			fallback.position = base_pos
			_clouds_layer.add_child(fallback)
			continue
		var cloud := Sprite2D.new()
		var tex := _cloud_textures[rng.randi_range(0, _cloud_textures.size() - 1)]
		cloud.texture = tex
		cloud.centered = true
		cloud.position = base_pos
		cloud.scale = Vector2(s, s)
		cloud.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_clouds_layer.add_child(cloud)

func _add_background_block(parent: Node2D, tex: Texture2D, world_pos: Vector2, tint: Color, scale_value: float = 1.0) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.global_position = world_pos
	s.modulate = tint
	s.scale = Vector2(scale_value, scale_value)
	parent.add_child(s)

func _spawn_resources() -> void:
	var resource_scene := preload("res://scenes/ResourceNode.tscn")
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(180):
		var resource: Area2D = resource_scene.instantiate() as Area2D
		var surface: Vector2 = _world_tiles.get_random_surface_world_position(rng)
		resource.global_position = surface + Vector2(0, -20)

		var resource_script: Variant = resource.get_script()
		if resource_script:
			if i % 4 == 0:
				resource.set("resource_kind", "food")
				resource.set("gather_value", 2)
				resource.set("gather_hits_required", 2)
			else:
				resource.set("resource_kind", "wood")
				resource.set("gather_value", 2)
				resource.set("gather_hits_required", 3)
		_resource_container.add_child(resource)

func _spawn_crops() -> void:
	var crop_scene := preload("res://scenes/CropNode.tscn")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in range(75):
		var crop: Area2D = crop_scene.instantiate() as Area2D
		var crop_surface: Vector2 = _world_tiles.get_random_surface_world_position(rng)
		crop.global_position = crop_surface + Vector2(0, -24)
		_crop_container.add_child(crop)

func _spawn_decorations() -> void:
	const TREE_MIN_HORIZONTAL_SPACING := 512.0
	const TREE_SPAWN_MAX_ATTEMPTS := 120
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var tree_scene := preload("res://scenes/TreeNode.tscn")
	var world_root_y: float = _world_tiles.get_surface_world_position_at_x(0.0).y
	var spawned_x: Array[float] = []
	for _i in range(TREE_SPAWN_MAX_ATTEMPTS):
		var base_pos: Vector2 = _world_tiles.get_random_surface_world_position(rng)
		# Keep decorations near the upper surface band so composition stays clean.
		if base_pos.y > world_root_y + 120.0:
			continue
		var too_close := false
		for x in spawned_x:
			if absf(base_pos.x - x) < TREE_MIN_HORIZONTAL_SPACING:
				too_close = true
				break
		if too_close:
			continue
		var tree := tree_scene.instantiate() as Area2D
		tree.global_position = base_pos
		_resource_container.add_child(tree)
		spawned_x.append(tree.global_position.x)
	_spawn_berry_bushes()

func _spawn_berry_bushes() -> void:
	const MIN_SPACING := 128.0
	const MAX_ATTEMPTS := 160
	const TARGET_COUNT := 18
	var rng := RandomNumberGenerator.new()
	rng.seed = 246801
	var bush_scene := preload("res://scenes/BerryBush.tscn")
	var world_root_y: float = _world_tiles.get_surface_world_position_at_x(0.0).y
	var spawned_x: Array[float] = []
	for _i in range(MAX_ATTEMPTS):
		if spawned_x.size() >= TARGET_COUNT:
			break
		var base_pos: Vector2 = _world_tiles.get_random_surface_world_position(rng)
		if base_pos.y > world_root_y + 140.0:
			continue
		var too_close := false
		for x in spawned_x:
			if absf(base_pos.x - x) < MIN_SPACING:
				too_close = true
				break
		if too_close:
			continue
		var bush: Area2D = bush_scene.instantiate() as Area2D
		bush.global_position = base_pos
		_resource_container.add_child(bush)
		spawned_x.append(bush.global_position.x)

func _snap_core_actors_to_surface() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var spawn_surface: Vector2 = _world_tiles.get_random_surface_world_position(rng)
	_player.global_position = spawn_surface + Vector2(0, -30)
	var bob_surface: Vector2 = _world_tiles.get_surface_world_position_at_x(spawn_surface.x + 70.0)
	_bob.global_position = bob_surface + Vector2(0, -30)

func _snap_world_props_to_surface() -> void:
	_snap_node_to_surface(_door, -26.0)
	_snap_node_to_surface(_chest, -16.0)
	_snap_node_to_surface(_hazard, -10.0)
	_snap_node_to_surface(_starter_crop_a, -24.0)
	_snap_node_to_surface(_starter_crop_b, -24.0)

func _snap_node_to_surface(node: Node2D, vertical_offset: float) -> void:
	if not node:
		return
	var surface: Vector2 = _world_tiles.get_surface_world_position_at_x(node.global_position.x)
	node.global_position = surface + Vector2(0, vertical_offset)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	_reset_survival_timer()
	get_tree().reload_current_scene()


func _format_run_time(seconds: float) -> String:
	var t := maxi(0, int(floor(seconds)))
	var h := t / 3600
	t %= 3600
	var m := t / 60
	var s := t % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s]
	return "%02d:%02d" % [m, s]


func _open_pause_menu() -> void:
	_close_craft_menu()
	RunRecords.commit_best_if_greater(_survival_sec)
	_refresh_pause_menu()
	_pause_menu.visible = true
	get_tree().paused = true


func _close_pause_menu() -> void:
	_pause_menu.visible = false
	get_tree().paused = false


func _refresh_pause_menu() -> void:
	_pause_best_label.text = "Best survival: %s" % _format_run_time(RunRecords.load_best_survival_seconds())
	_pause_current_label.text = "This run: %s" % _format_run_time(_survival_sec)


func _build_keybinds_help() -> String:
	var rows: PackedStringArray = PackedStringArray()
	rows.append("Pause / back: %s" % _events_as_text(&"ui_cancel"))
	rows.append("Move left: %s" % _events_as_text(&"move_left"))
	rows.append("Move right: %s" % _events_as_text(&"move_right"))
	rows.append("Move up: %s" % _events_as_text(&"move_up"))
	var specs: Array[Array] = [
		["Move down / mine", &"move_down"],
		["Jump", &"jump"],
		["Interact / gather", &"interact"],
		["Craft menu (also F)", &"craft_tool"],
		["Feed Bob", &"feed_bob"],
		["Toggle debug", &"toggle_debug_mode"],
		["Place block", &"place_block"],
		["Mine / dig", &"mine_block"],
		["Cycle place material", &"cycle_place_kind"],
		["Place Calm Totem", &"place_totem"],
	]
	for sp in specs:
		rows.append("%s: %s" % [str(sp[0]), _events_as_text(sp[1])])
	return "\n".join(rows)


func _events_as_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "—"
	var parts: PackedStringArray = PackedStringArray()
	for ev in InputMap.action_get_events(action):
		var bit := _event_as_text(ev)
		if not bit.is_empty() and not parts.has(bit):
			parts.append(bit)
	if parts.is_empty():
		return "—"
	return " / ".join(parts)


func _event_as_text(ev: InputEvent) -> String:
	if ev is InputEventKey:
		var e := ev as InputEventKey
		var kc := e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
		if kc == KEY_NONE:
			return ""
		return OS.get_keycode_string(kc)
	if ev is InputEventMouseButton:
		var m := ev as InputEventMouseButton
		match m.button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			_:
				return "Mouse btn %d" % m.button_index
	return ""


func _toggle_craft_menu() -> void:
	_craft_menu.visible = not _craft_menu.visible
	if _craft_menu.visible:
		_refresh_craft_menu()

func _close_craft_menu() -> void:
	_craft_menu.visible = false

func _refresh_craft_menu() -> void:
	var wx: GameManager = _manager as GameManager
	$CanvasLayer/CraftMenu/CraftToolButton.text = "Wooden Pickaxe (%d Wood)   Have:%d%s" % [
		wx.get_wood_cost_for_tool("pickaxe"), _manager.inventory["pickaxe"], _tier_suffix("pickaxe")
	]
	$CanvasLayer/CraftMenu/CraftAxeButton.text = "Wooden Axe (%d Wood)   Have:%d%s" % [
		wx.get_wood_cost_for_tool("axe"), _manager.inventory["axe"], _tier_suffix("axe")
	]
	$CanvasLayer/CraftMenu/CraftSwordButton.text = "Wooden Sword (%d Wood)   Have:%d%s" % [
		wx.get_wood_cost_for_tool("sword"), _manager.inventory["sword"], _tier_suffix("sword")
	]
	$CanvasLayer/CraftMenu/CraftHoeButton.text = "Wooden Hoe (%d Wood)   Have:%d%s" % [
		wx.get_wood_cost_for_tool("hoe"), _manager.inventory["hoe"], _tier_suffix("hoe")
	]
	$CanvasLayer/CraftMenu/CraftMealButton.text = "Cooked Meal (3 Food + 1 Wood)"
	$CanvasLayer/CraftMenu/CraftSnackButton.text = "Bob Snack (2 Food + 1 Wood)   Have:%d" % _manager.inventory["bob_snacks"]
	if _craft_shovel_button:
		_craft_shovel_button.text = "Wooden Shovel (%d Wood)   Have:%d%s" % [
			wx.get_wood_cost_for_tool("shovel"), _manager.inventory["shovel"], _tier_suffix("shovel")
		]
	if _craft_totem_button:
		_craft_totem_button.text = "Calm Totem (5 Wood + 5 Stone)   Have:%d" % _manager.inventory["totems"]
	if _craft_reinforced_button:
		_craft_reinforced_button.text = "Reinforced x4 (2 Wood + 4 Stone)   Have:%d" % _manager.inventory["reinforced"]
	if _upgrade_pickaxe_button:
		_upgrade_pickaxe_button.text = "Upgrade Pickaxe → Stone (%s)" % wx.get_upgrade_cost_line("pickaxe")
		_upgrade_pickaxe_button.disabled = _manager.inventory["pickaxe"] < 1 or wx.get_tool_tier("pickaxe") >= 1
	if _upgrade_axe_button:
		_upgrade_axe_button.text = "Upgrade Axe → Stone (%s)" % wx.get_upgrade_cost_line("axe")
		_upgrade_axe_button.disabled = _manager.inventory["axe"] < 1 or wx.get_tool_tier("axe") >= 1
	if _upgrade_sword_button:
		_upgrade_sword_button.text = "Upgrade Sword → Stone (%s)" % wx.get_upgrade_cost_line("sword")
		_upgrade_sword_button.disabled = _manager.inventory["sword"] < 1 or wx.get_tool_tier("sword") >= 1
	if _upgrade_hoe_button:
		_upgrade_hoe_button.text = "Upgrade Hoe → Stone (%s)" % wx.get_upgrade_cost_line("hoe")
		_upgrade_hoe_button.disabled = _manager.inventory["hoe"] < 1 or wx.get_tool_tier("hoe") >= 1
	if _upgrade_shovel_button:
		_upgrade_shovel_button.text = "Upgrade Shovel → Stone (%s)" % wx.get_upgrade_cost_line("shovel")
		_upgrade_shovel_button.disabled = _manager.inventory["shovel"] < 1 or wx.get_tool_tier("shovel") >= 1
	_craft_feedback.text = "[S/LMB] mine  [X] cycle place  [V] place  [T] place totem"

func _tier_suffix(tool: String) -> String:
	var wx: GameManager = _manager as GameManager
	if wx and wx.get_tool_tier(tool) >= 1:
		return " ★Stone"
	return " (Wood)"

func _update_status_icons() -> void:
	_update_actor_overhead(_player, _manager.player_health, _manager.player_hunger)
	var bob_health := 100.0
	var bob_hunger := 100.0
	var bob_health_max := 100.0
	if _bob and _bob.get("health") != null:
		bob_health = float(_bob.get("health"))
	if _bob and _bob.get("hunger") != null:
		bob_hunger = float(_bob.get("hunger"))
	if _bob and _bob.get("max_health") != null:
		bob_health_max = float(_bob.get("max_health"))
	_update_actor_overhead(_bob, bob_health, bob_hunger, bob_health_max)

func _create_overhead_status(actor: Node2D) -> void:
	if not actor:
		return
	var root := Node2D.new()
	root.name = "OverheadStatus"
	root.position = Vector2(-50, -118)
	actor.add_child(root)
	var hearts: Array[Sprite2D] = []
	var hunger: Array[Sprite2D] = []
	for i in range(6):
		var heart := Sprite2D.new()
		heart.texture = _heart_full
		heart.position = Vector2(float(i) * 18.0, 0.0)
		heart.scale = Vector2(1.35, 1.35)
		root.add_child(heart)
		hearts.append(heart)
	for i in range(6):
		var drum := Sprite2D.new()
		drum.texture = _hunger_full
		drum.position = Vector2(float(i) * 18.0, 20.0)
		drum.scale = Vector2(1.35, 1.35)
		root.add_child(drum)
		hunger.append(drum)
	_overhead_hud[actor] = {"root": root, "hearts": hearts, "hunger": hunger}

func _update_actor_overhead(actor: Node2D, health_value: float, hunger_value: float, health_max: float = 100.0) -> void:
	if not actor:
		return
	if not _overhead_hud.has(actor):
		return
	var ui: Dictionary = _overhead_hud[actor]
	var hm := maxf(health_max, 1.0)
	var health_units := int(round(clampf(health_value / hm, 0.0, 1.0) * 6.0))
	var hunger_units := int(round((clampf(hunger_value, 0.0, 100.0) / 100.0) * 6.0))
	var hearts: Array = ui.get("hearts", [])
	var hunger: Array = ui.get("hunger", [])
	for i in range(hearts.size()):
		var heart := hearts[i] as Sprite2D
		if heart:
			heart.texture = _heart_full if i < health_units else _heart_empty
	for i in range(hunger.size()):
		var drum := hunger[i] as Sprite2D
		if drum:
			drum.texture = _hunger_full if i < hunger_units else _hunger_empty

func _update_hotbar_counts() -> void:
	_slot_wood.text = str(_manager.inventory["wood"])
	_slot_stone.text = str(_manager.inventory["stone"])
	_slot_food.text = str(_manager.inventory["food"])
	_slot_seeds.text = str(_manager.inventory["seeds"])
	_slot_sword.text = _hotbar_tool_label("sword")
	_slot_pickaxe.text = _hotbar_tool_label("pickaxe")
	_slot_axe.text = _hotbar_tool_label("axe")
	_slot_shovel.text = _hotbar_tool_label("shovel")
	_slot_hoe.text = _hotbar_tool_label("hoe")
	if _slot_dirt_label:
		_slot_dirt_label.text = str(_manager.inventory.get("dirt", 0))
	if _slot_grass_label:
		_slot_grass_label.text = str(_manager.inventory.get("grass_block", 0))
	if _slot_reinforced_label:
		_slot_reinforced_label.text = str(_manager.inventory.get("reinforced", 0))
	if _slot_totems_label:
		_slot_totems_label.text = str(_manager.inventory.get("totems", 0))
	if _place_indicator and _player and _player.has_method("get_place_kind"):
		var pk: String = _player.get_place_kind()
		var count: int = int(_manager.inventory.get(pk, 0))
		_place_indicator.text = "Place: %s x%d" % [pk, count]

func _update_hotbar_selection() -> void:
	if not _player or not _player.has_method("get_selected_tool"):
		return
	var selected_tool: String = _player.get_selected_tool()
	_panel_sword.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected_tool == "sword" else Color(0.75, 0.75, 0.75, 1.0)
	_panel_pickaxe.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected_tool == "pickaxe" else Color(0.75, 0.75, 0.75, 1.0)
	_panel_axe.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected_tool == "axe" else Color(0.75, 0.75, 0.75, 1.0)
	_panel_shovel.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected_tool == "shovel" else Color(0.75, 0.75, 0.75, 1.0)
	_panel_hoe.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected_tool == "hoe" else Color(0.75, 0.75, 0.75, 1.0)

func _hotbar_tool_label(tool: String) -> String:
	var wx: GameManager = _manager as GameManager
	var n := str(_manager.inventory.get(tool, 0))
	if wx and wx.get_tool_tier(tool) >= 1:
		return "%s★" % n
	return n

func _on_craft_tool_pressed() -> void:
	var wx: GameManager = _manager as GameManager
	var cost := wx.get_wood_cost_for_tool("pickaxe") if wx else 4
	if _manager.craft_tool():
		_craft_feedback.text = "Crafted wooden pickaxe (%d wood)." % cost
	else:
		_craft_feedback.text = "Need %d wood for wooden pickaxe." % cost
	_refresh_craft_menu()

func _on_craft_axe_pressed() -> void:
	var wx: GameManager = _manager as GameManager
	var cost := wx.get_wood_cost_for_tool("axe") if wx else 5
	if _manager.craft_axe():
		_craft_feedback.text = "Crafted wooden axe (%d wood)." % cost
	else:
		_craft_feedback.text = "Need %d wood for wooden axe." % cost
	_refresh_craft_menu()

func _on_craft_sword_pressed() -> void:
	var wx: GameManager = _manager as GameManager
	var cost := wx.get_wood_cost_for_tool("sword") if wx else 4
	if _manager.craft_sword():
		_craft_feedback.text = "Crafted wooden sword (%d wood)." % cost
	else:
		_craft_feedback.text = "Need %d wood for wooden sword." % cost
	_refresh_craft_menu()

func _on_craft_hoe_pressed() -> void:
	var wx: GameManager = _manager as GameManager
	var cost := wx.get_wood_cost_for_tool("hoe") if wx else 4
	if _manager.craft_hoe():
		_craft_feedback.text = "Crafted wooden hoe (%d wood)." % cost
	else:
		_craft_feedback.text = "Need %d wood for wooden hoe." % cost
	_refresh_craft_menu()

func _on_craft_snack_pressed() -> void:
	if _manager.craft_bob_snack():
		_craft_feedback.text = "Crafted Bob Snack. (Cost: 2 food, 1 wood)"
	else:
		_craft_feedback.text = "Need: 2 food + 1 wood"
	_refresh_craft_menu()

func _on_craft_meal_pressed() -> void:
	if _manager.craft_cooked_meal():
		_craft_feedback.text = "Cooked Meal used. Hunger restored."
	else:
		_craft_feedback.text = "Need: 3 food + 1 wood"
	_refresh_craft_menu()

func _on_craft_shovel_pressed() -> void:
	var wx: GameManager = _manager as GameManager
	var cost := wx.get_wood_cost_for_tool("shovel") if wx else 3
	if _manager.craft_shovel():
		_craft_feedback.text = "Crafted wooden shovel (%d wood)." % cost
	else:
		_craft_feedback.text = "Need %d wood for wooden shovel." % cost
	_refresh_craft_menu()

func _on_upgrade_pickaxe_pressed() -> void:
	if _manager.upgrade_tool("pickaxe"):
		_craft_feedback.text = "Pickaxe upgraded to stone (faster mining / gathering)."
	else:
		_craft_feedback.text = "Need a wooden pickaxe + upgrade materials."
	_refresh_craft_menu()

func _on_upgrade_axe_pressed() -> void:
	if _manager.upgrade_tool("axe"):
		_craft_feedback.text = "Axe upgraded to stone."
	else:
		_craft_feedback.text = "Need a wooden axe + upgrade materials."
	_refresh_craft_menu()

func _on_upgrade_sword_pressed() -> void:
	if _manager.upgrade_tool("sword"):
		_craft_feedback.text = "Sword upgraded to stone."
	else:
		_craft_feedback.text = "Need a wooden sword + upgrade materials."
	_refresh_craft_menu()

func _on_upgrade_hoe_pressed() -> void:
	if _manager.upgrade_tool("hoe"):
		_craft_feedback.text = "Hoe upgraded to stone."
	else:
		_craft_feedback.text = "Need a wooden hoe + upgrade materials."
	_refresh_craft_menu()

func _on_upgrade_shovel_pressed() -> void:
	if _manager.upgrade_tool("shovel"):
		_craft_feedback.text = "Shovel upgraded to stone."
	else:
		_craft_feedback.text = "Need a wooden shovel + upgrade materials."
	_refresh_craft_menu()

func _on_craft_totem_pressed() -> void:
	if _manager.craft_calm_totem():
		_craft_feedback.text = "Crafted Calm Totem. (Cost: 5 wood, 5 stone) Press T to place."
	else:
		_craft_feedback.text = "Need: 5 wood + 5 stone"
	_refresh_craft_menu()

func _on_craft_reinforced_pressed() -> void:
	if _manager.craft_reinforced_block():
		_craft_feedback.text = "Crafted 4x Reinforced Block. (Cost: 2 wood, 4 stone)"
	else:
		_craft_feedback.text = "Need: 2 wood + 4 stone"
	_refresh_craft_menu()

func _extend_material_counter_ui() -> void:
	var mc := get_node_or_null("CanvasLayer/MaterialCounter") as Panel
	if not mc:
		return
	# Roomier panel so we can host place indicator + new material rows.
	mc.offset_left = 16.0
	mc.offset_top = 540.0
	mc.offset_right = 320.0
	mc.offset_bottom = 712.0

	_place_indicator = Label.new()
	_place_indicator.name = "PlaceIndicator"
	_place_indicator.position = Vector2(10.0, 6.0)
	_place_indicator.size = Vector2(290.0, 20.0)
	_place_indicator.add_theme_color_override("font_color", Color(0.95, 0.92, 0.55, 1.0))
	_place_indicator.add_theme_font_size_override("font_size", 13)
	mc.add_child(_place_indicator)

	var hint := Label.new()
	hint.name = "PlaceHint"
	hint.position = Vector2(10.0, 26.0)
	hint.size = Vector2(290.0, 18.0)
	hint.add_theme_color_override("font_color", Color(0.78, 0.84, 0.95, 1.0))
	hint.add_theme_font_size_override("font_size", 11)
	hint.text = "[S/LMB] mine  [X] cycle place  [V] place  [T] place totem"
	mc.add_child(hint)

	# Reposition existing wood/stone/food labels into the new layout.
	_relabel_existing_material(mc, "WoodLabel", "WoodCount", "Wood:", Vector2(10.0, 50.0))
	_relabel_existing_material(mc, "StoneLabel", "StoneCount", "Stone:", Vector2(10.0, 70.0))
	_relabel_existing_material(mc, "FoodLabel", "FoodCount", "Food:", Vector2(10.0, 90.0))
	_relabel_existing_material(mc, "SeedsLabel", "SeedsCount", "Seeds:", Vector2(10.0, 110.0))

	_slot_dirt_label = _add_material_row(mc, "Dirt:", Vector2(160.0, 50.0))
	_slot_grass_label = _add_material_row(mc, "Grass:", Vector2(160.0, 70.0))
	_slot_reinforced_label = _add_material_row(mc, "Wall:", Vector2(160.0, 90.0))
	_slot_totems_label = _add_material_row(mc, "Totems:", Vector2(160.0, 110.0))

func _relabel_existing_material(mc: Panel, label_name: String, count_name: String, text: String, label_pos: Vector2) -> void:
	var lbl := mc.get_node_or_null(label_name) as Label
	if lbl:
		lbl.position = label_pos
		lbl.size = Vector2(70.0, 18.0)
		lbl.text = text
		lbl.offset_left = label_pos.x
		lbl.offset_top = label_pos.y
		lbl.offset_right = label_pos.x + 70.0
		lbl.offset_bottom = label_pos.y + 18.0
	var cnt := mc.get_node_or_null(count_name) as Label
	if cnt:
		var count_pos := label_pos + Vector2(70.0, 0.0)
		cnt.position = count_pos
		cnt.size = Vector2(60.0, 18.0)
		cnt.offset_left = count_pos.x
		cnt.offset_top = count_pos.y
		cnt.offset_right = count_pos.x + 60.0
		cnt.offset_bottom = count_pos.y + 18.0

func _add_material_row(mc: Panel, prefix: String, label_pos: Vector2) -> Label:
	var lbl := Label.new()
	lbl.text = prefix
	lbl.position = label_pos
	lbl.size = Vector2(70.0, 18.0)
	lbl.add_theme_font_size_override("font_size", 12)
	mc.add_child(lbl)
	var cnt := Label.new()
	cnt.text = "0"
	cnt.position = label_pos + Vector2(70.0, 0.0)
	cnt.size = Vector2(60.0, 18.0)
	cnt.add_theme_font_size_override("font_size", 12)
	mc.add_child(cnt)
	return cnt

func _extend_craft_menu_ui() -> void:
	# Tall panel: base crafts + upgrades + feedback.
	_craft_menu.offset_bottom = 620.0
	_craft_shovel_button = _add_craft_button("CraftShovelButton", "Wooden Shovel (Wood)", 256.0)
	_craft_shovel_button.pressed.connect(_on_craft_shovel_pressed)
	_craft_totem_button = _add_craft_button("CraftTotemButton", "Calm Totem (5 Wood + 5 Stone)", 290.0)
	_craft_totem_button.pressed.connect(_on_craft_totem_pressed)
	_craft_reinforced_button = _add_craft_button("CraftReinforcedButton", "Reinforced x4 (2 Wood + 4 Stone)", 324.0)
	_craft_reinforced_button.pressed.connect(_on_craft_reinforced_pressed)
	_upgrade_pickaxe_button = _add_craft_button("UpgradePickaxeButton", "Upgrade Pickaxe → Stone", 356.0)
	_upgrade_pickaxe_button.pressed.connect(_on_upgrade_pickaxe_pressed)
	_upgrade_axe_button = _add_craft_button("UpgradeAxeButton", "Upgrade Axe → Stone", 386.0)
	_upgrade_axe_button.pressed.connect(_on_upgrade_axe_pressed)
	_upgrade_sword_button = _add_craft_button("UpgradeSwordButton", "Upgrade Sword → Stone", 416.0)
	_upgrade_sword_button.pressed.connect(_on_upgrade_sword_pressed)
	_upgrade_hoe_button = _add_craft_button("UpgradeHoeButton", "Upgrade Hoe → Stone", 446.0)
	_upgrade_hoe_button.pressed.connect(_on_upgrade_hoe_pressed)
	_upgrade_shovel_button = _add_craft_button("UpgradeShovelButton", "Upgrade Shovel → Stone", 476.0)
	_upgrade_shovel_button.pressed.connect(_on_upgrade_shovel_pressed)
	_craft_feedback.offset_top = 506.0
	_craft_feedback.offset_bottom = 536.0

func _add_craft_button(node_name: String, label: String, top: float) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = label
	btn.offset_left = 52.0
	btn.offset_top = top
	btn.offset_right = 426.0
	btn.offset_bottom = top + 26.0
	_craft_menu.add_child(btn)
	return btn

func _create_debug_label() -> void:
	_debug_label = Label.new()
	_debug_label.position = Vector2(960, 16)
	_debug_label.size = Vector2(300, 28)
	_debug_label.add_theme_font_size_override("font_size", 16)
	_debug_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.65, 1.0))
	$CanvasLayer.add_child(_debug_label)

func _create_bob_debug_label() -> void:
	_bob_debug_label = Label.new()
	_bob_debug_label.position = Vector2(16, 16)
	_bob_debug_label.size = Vector2(560, 72)
	_bob_debug_label.add_theme_font_size_override("font_size", 15)
	_bob_debug_label.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0, 1.0))
	_bob_debug_label.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.14, 0.92))
	_bob_debug_label.add_theme_constant_override("outline_size", 4)
	$CanvasLayer.add_child(_bob_debug_label)

func _update_debug_label() -> void:
	if not _debug_label:
		return
	var state := "ON" if _manager.debug_mode_enabled else "OFF"
	_debug_label.text = "Debug %s (Toggle: I)" % state

func _update_bob_debug_label() -> void:
	if not _bob_debug_label or not _manager:
		return
	var debug_on: bool = bool(_manager.debug_mode_enabled)
	_bob_debug_label.visible = debug_on
	if not debug_on or not _bob:
		return
	if _bob.has_method("get_life_debug_snapshot"):
		var snap: Dictionary = _bob.get_life_debug_snapshot()
		_bob_debug_label.text = "B.O.B.  HP: %.0f  Hunger: %.0f  Safety: %.0f  Curiosity: %.0f  Energy: %.0f  Trust: %.0f  Love: %.0f  State: %s" % [
			float(snap.get("health", 100.0)),
			float(snap.get("hunger", 0.0)),
			float(snap.get("safety", 0.0)),
			float(snap.get("curiosity", 0.0)),
			float(snap.get("energy", 0.0)),
			float(snap.get("trust", 0.0)),
			float(snap.get("affection", 0.0)),
			str(snap.get("state", "UNKNOWN")),
		]
		return
	var bob_health := float(_bob.get("health")) if _bob.get("health") != null else 100.0
	var bob_hunger := float(_bob.get("hunger")) if _bob.get("hunger") != null else 0.0
	var bob_safety := float(_bob.get("safety")) if _bob.get("safety") != null else 0.0
	var bob_curiosity := float(_bob.get("curiosity")) if _bob.get("curiosity") != null else 0.0
	_bob_debug_label.text = "B.O.B.  HP: %.0f  Hunger: %.0f  Safety: %.0f  Curiosity: %.0f" % [bob_health, bob_hunger, bob_safety, bob_curiosity]
