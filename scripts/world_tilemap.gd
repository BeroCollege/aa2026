extends TileMapLayer

const TILE_SIZE := 64
## Initial horizontal slice generated at startup (~8960 px); extended dynamically.
const INITIAL_WORLD_WIDTH_TILES := 140
const MAP_HEIGHT := 40
const SURFACE_MIN_Y := 18
const SURFACE_MAX_Y := 24
## Keep this many tiles beyond min/max actor X so terrain exists before you reach it.
const STREAM_MARGIN_TILES := 64
const TERRAIN_STEP_UP_PROB := 0.15
const TERRAIN_STEP_DOWN_PROB := 0.15
const GRASS_MIDDLE_SOURCE_ID := 0
const DIRT_SOURCE_ID := 1
const STONE_SOURCE_ID := 2
const WATER_SOURCE_ID := 3
const LAVA_SOURCE_ID := 4
const REINFORCED_SOURCE_ID := 5
const GRASS_LEFT_SOURCE_ID := 6
const GRASS_RIGHT_SOURCE_ID := 7
const GRASS_FULL_SOURCE_ID := 8

var _surface_cells: Array[Vector2i] = []
var _surface_y_by_x: Dictionary = {}
## Cumulative mining damage per cell (float so bare-hand fractional hits work).
var _tile_damage: Dictionary = {}
var _generated_min_x: int = 0
var _generated_max_x: int = -1
var _terrain_rng: RandomNumberGenerator
var _mining_darken_sprite: Sprite2D
var _mining_darken_atlas: AtlasTexture

func _ready() -> void:
	y_sort_enabled = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tile_set = _build_tileset()
	_terrain_rng = RandomNumberGenerator.new()
	_terrain_rng.seed = 1337
	paint_world()

func paint_world() -> void:
	clear()
	clear_mining_cell_darken()
	_surface_cells.clear()
	_surface_y_by_x.clear()
	_tile_damage.clear()
	_generated_min_x = 0
	_generated_max_x = INITIAL_WORLD_WIDTH_TILES - 1
	for x in range(_generated_min_x, _generated_max_x + 1):
		_paint_column_at_x(x)
	_refresh_surface_grass_visuals_range(_generated_min_x, _generated_max_x)

func _surface_y_for_column(x: int) -> int:
	if _surface_y_by_x.has(x):
		return int(_surface_y_by_x[x])
	if _surface_y_by_x.has(x - 1):
		return int(_surface_y_by_x[x - 1])
	if _surface_y_by_x.has(x + 1):
		return int(_surface_y_by_x[x + 1])
	return int((SURFACE_MIN_Y + SURFACE_MAX_Y) / 2)

func _next_surface_y_for_column(x: int) -> int:
	var base := _surface_y_for_column(x)
	if not _terrain_rng:
		return base
	var roll := _terrain_rng.randf()
	var step := 0
	if roll < TERRAIN_STEP_UP_PROB:
		step = -1
	elif roll < TERRAIN_STEP_UP_PROB + TERRAIN_STEP_DOWN_PROB:
		step = 1
	return clampi(base + step, SURFACE_MIN_Y, SURFACE_MAX_Y)

func _paint_column_at_x(x: int) -> void:
	if _surface_y_by_x.has(x):
		return
	var ids := _source_ids()
	var grass: int = ids["grass"]
	var dirt: int = ids["dirt"]
	var stone: int = ids["stone"]
	var current_surface_y := _next_surface_y_for_column(x)
	_surface_y_by_x[x] = current_surface_y
	_surface_cells.append(Vector2i(x, current_surface_y))
	for y in range(current_surface_y, MAP_HEIGHT):
		var source := grass if y == current_surface_y else dirt
		if y >= current_surface_y + 4:
			source = stone
		set_cell(Vector2i(x, y), source, Vector2i.ZERO)
	_refresh_surface_grass_visuals_range(x - 1, x + 1)

func ensure_streaming_around_world(min_world_x: float, max_world_x: float) -> void:
	var min_cx := world_to_cell(Vector2(min_world_x, global_position.y)).x
	var max_cx := world_to_cell(Vector2(max_world_x, global_position.y)).x
	var need_min := min_cx - STREAM_MARGIN_TILES
	var need_max := max_cx + STREAM_MARGIN_TILES
	while need_min < _generated_min_x:
		_generated_min_x -= 1
		_paint_column_at_x(_generated_min_x)
	while need_max > _generated_max_x:
		_generated_max_x += 1
		_paint_column_at_x(_generated_max_x)

func _build_tileset() -> TileSet:
	var set := TileSet.new()
	# Surface grass uses multiple sources so we can swap variants based on horizontal neighbors.
	_add_single_tile_source(set, GRASS_MIDDLE_SOURCE_ID, "res://assets/tiles/grass_top.png")
	_add_single_tile_source(set, DIRT_SOURCE_ID, "res://assets/tiles/dirt.png")
	_add_single_tile_source(set, STONE_SOURCE_ID, "res://assets/tiles/stone.png")
	_add_single_tile_source(set, WATER_SOURCE_ID, "res://assets/blockpack/tile_water.png")
	_add_single_tile_source(set, LAVA_SOURCE_ID, "res://assets/blockpack/tile_lava.png")
	_add_solid_color_tile_source(set, REINFORCED_SOURCE_ID, Color(0.32, 0.38, 0.55, 1.0))
	_add_single_tile_source(set, GRASS_LEFT_SOURCE_ID, "res://assets/tiles/grass_left.png")
	_add_single_tile_source(set, GRASS_RIGHT_SOURCE_ID, "res://assets/tiles/grass_right.png")
	_add_single_tile_source(set, GRASS_FULL_SOURCE_ID, "res://assets/tiles/grass_full.png")
	set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	return set

func _add_single_tile_source(set: TileSet, source_id: int, texture_path: String) -> void:
	var src := TileSetAtlasSource.new()
	var tex: Texture2D = _normalized_tile_texture(texture_path)
	if tex == null:
		push_error("world_tilemap: failed to load tile texture %s" % texture_path)
		return
	src.texture = tex
	# One atlas tile per source; art is resized to match logical TILE_SIZE so neighbors align.
	src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	src.create_tile(Vector2i.ZERO)
	set.add_source(src, source_id)


## Runtime tile art is often larger than TILE_SIZE; stretching mixed sizes causes seams between cells.
func _normalized_tile_texture(texture_path: String) -> Texture2D:
	var loaded: Resource = load(texture_path)
	if loaded == null or not (loaded is Texture2D):
		return null
	var src_tex: Texture2D = loaded
	var img: Image = src_tex.get_image()
	if img == null:
		return src_tex
	if img.get_width() == TILE_SIZE and img.get_height() == TILE_SIZE:
		return src_tex
	var dup: Image = img.duplicate()
	dup.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(dup)

func _add_solid_color_tile_source(set: TileSet, source_id: int, color: Color) -> void:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var border_color := color.darkened(0.45)
	for x in range(TILE_SIZE):
		img.set_pixel(x, 0, border_color)
		img.set_pixel(x, 1, border_color)
		img.set_pixel(x, TILE_SIZE - 1, border_color)
		img.set_pixel(x, TILE_SIZE - 2, border_color)
	for y in range(TILE_SIZE):
		img.set_pixel(0, y, border_color)
		img.set_pixel(1, y, border_color)
		img.set_pixel(TILE_SIZE - 1, y, border_color)
		img.set_pixel(TILE_SIZE - 2, y, border_color)
	# Subtle rivet diamonds for visual texture.
	var rivet_color := color.lightened(0.25)
	var rivets := [Vector2i(16, 16), Vector2i(48, 16), Vector2i(16, 48), Vector2i(48, 48), Vector2i(32, 32)]
	for r in rivets:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				if absi(dx) + absi(dy) <= 2:
					img.set_pixel(r.x + dx, r.y + dy, rivet_color)
	var tex := ImageTexture.create_from_image(img)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	src.create_tile(Vector2i.ZERO)
	set.add_source(src, source_id)

func _source_ids() -> Dictionary:
	return {
		"grass": GRASS_MIDDLE_SOURCE_ID,
		"dirt": DIRT_SOURCE_ID,
		"stone": STONE_SOURCE_ID,
		"water": WATER_SOURCE_ID,
		"lava": LAVA_SOURCE_ID,
	}

func _is_grass_source_id(source_id: int) -> bool:
	return source_id in [GRASS_MIDDLE_SOURCE_ID, GRASS_LEFT_SOURCE_ID, GRASS_RIGHT_SOURCE_ID, GRASS_FULL_SOURCE_ID]

func _refresh_surface_grass_visuals_range(min_x: int, max_x: int) -> void:
	var ax := mini(min_x, max_x)
	var bx := maxi(min_x, max_x)
	for x in range(ax, bx + 1):
		_refresh_surface_grass_visuals_for_column(x)

func _refresh_surface_grass_visuals_for_column(x: int) -> void:
	if not _surface_y_by_x.has(x):
		return
	var y := int(_surface_y_by_x[x])
	if y < 0 or y >= MAP_HEIGHT:
		return
	var cell := Vector2i(x, y)
	var current_source := get_cell_source_id(cell)
	if not _is_grass_source_id(current_source):
		return

	# "Surface grass" variant rules (based on solidity at the same surface row):
	# - if both left and right are air → grass_full (isolated / floating top strip)
	# - else if left is air → grass_left (left cliff edge)
	# - else if right is air → grass_right (right cliff edge)
	# - else → grass_top (standard middle strip)
	var left_solid := is_solid_cell(Vector2i(x - 1, y))
	var right_solid := is_solid_cell(Vector2i(x + 1, y))
	var desired := GRASS_MIDDLE_SOURCE_ID
	if not left_solid and not right_solid:
		desired = GRASS_FULL_SOURCE_ID
	elif not left_solid:
		desired = GRASS_LEFT_SOURCE_ID
	elif not right_solid:
		desired = GRASS_RIGHT_SOURCE_ID

	if current_source == desired:
		return
	set_cell(cell, desired, Vector2i.ZERO)

func _paint_lava_pool(start_x: int, width: int, lava_source_id: int) -> void:
	for x in range(start_x, start_x + width):
		if not _surface_y_by_x.has(x):
			continue
		var surface_y: int = int(_surface_y_by_x[x])
		var lava_y := clampi(surface_y + 1, 0, MAP_HEIGHT - 1)
		set_cell(Vector2i(x, lava_y), lava_source_id, Vector2i.ZERO)

func get_random_surface_world_position(rng: RandomNumberGenerator) -> Vector2:
	if _surface_cells.is_empty():
		return global_position
	var idx := rng.randi_range(0, _surface_cells.size() - 1)
	var cell := _surface_cells[idx]
	return get_surface_world_position_at_cell(cell)

func get_surface_world_y_at_x(world_x: float) -> float:
	if _surface_y_by_x.is_empty():
		return global_position.y
	var cell_x := world_to_cell(Vector2(world_x, global_position.y)).x
	var surface_y := int(_surface_y_by_x.get(cell_x, SURFACE_MAX_Y))
	return get_cell_world_top_y(Vector2i(cell_x, surface_y))

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return local_to_map(to_local(world_pos))

func get_cell_world_center(cell: Vector2i) -> Vector2:
	return to_global(map_to_local(cell))

func get_cell_world_top_y(cell: Vector2i) -> float:
	return get_cell_world_center(cell).y - float(TILE_SIZE) * 0.5

func get_surface_world_position_at_x(world_x: float) -> Vector2:
	var cell_x := world_to_cell(Vector2(world_x, global_position.y)).x
	var surface_y := int(_surface_y_by_x.get(cell_x, SURFACE_MAX_Y))
	return get_surface_world_position_at_cell(Vector2i(cell_x, surface_y))

func get_surface_cell_at_x(world_x: float) -> Vector2i:
	var cell_x := world_to_cell(Vector2(world_x, global_position.y)).x
	var surface_y := int(_surface_y_by_x.get(cell_x, SURFACE_MAX_Y))
	return Vector2i(cell_x, surface_y)

func get_walkable_surface_world_y_at_x(world_x: float, preferred_world_y: float) -> float:
	var cell_x := world_to_cell(Vector2(world_x, preferred_world_y)).x
	var best_y := get_surface_world_y_at_x(world_x)
	var best_dist := absf(best_y - preferred_world_y)
	for y in range(1, MAP_HEIGHT):
		var cell := Vector2i(cell_x, y)
		if not is_solid_cell(cell):
			continue
		if is_solid_cell(Vector2i(cell_x, y - 1)):
			continue
		var candidate_y := get_cell_world_top_y(cell)
		var d := absf(candidate_y - preferred_world_y)
		if d < best_dist:
			best_dist = d
			best_y = candidate_y
	return best_y

func get_surface_world_position_at_cell(cell: Vector2i) -> Vector2:
	var center := get_cell_world_center(cell)
	return Vector2(center.x, get_cell_world_top_y(cell))


func has_surface_column(column_x: int) -> bool:
	return _surface_y_by_x.has(column_x)


## World position at walkable surface center for a terrain column (correct even when the TileMapLayer is moved/scaled).
## Caller must ensure `has_surface_column(column_x)` first.
func get_surface_world_position_at_column_x(column_x: int) -> Vector2:
	var surface_y := int(_surface_y_by_x[column_x])
	return get_surface_world_position_at_cell(Vector2i(column_x, surface_y))

func is_solid_cell(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= MAP_HEIGHT:
		return true
	return get_cell_source_id(cell) != -1

func is_solid_world_point(world_pos: Vector2) -> bool:
	return is_solid_cell(world_to_cell(world_pos))

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


func _ensure_mining_darken_sprite() -> void:
	if _mining_darken_sprite:
		return
	_mining_darken_sprite = Sprite2D.new()
	_mining_darken_sprite.z_index = 2
	_mining_darken_sprite.centered = false
	_mining_darken_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mining_darken_atlas = AtlasTexture.new()
	_mining_darken_sprite.texture = _mining_darken_atlas
	_mining_darken_sprite.visible = false
	add_child(_mining_darken_sprite)


## Darken the cell currently being mined (player feedback). Cleared when mining stops or block breaks.
## Uses the same atlas region as the tile (Sprite2D + modulate); map_to_local is cell **center**, so top-left is center − half tile (+ TileData.texture_origin).
func set_mining_cell_darken(cell: Vector2i, progress_01: float) -> void:
	_ensure_mining_darken_sprite()
	var sid := get_cell_source_id(cell)
	if sid < 0:
		clear_mining_cell_darken()
		return
	var src: TileSetSource = tile_set.get_source(sid)
	if src == null or not (src is TileSetAtlasSource):
		clear_mining_cell_darken()
		return
	var atlas_src := src as TileSetAtlasSource
	var atlas_coords := get_cell_atlas_coords(cell)
	var region := atlas_src.get_tile_texture_region(atlas_coords)
	_mining_darken_atlas.atlas = atlas_src.texture
	_mining_darken_atlas.region = Rect2(region)
	var td := get_cell_tile_data(cell)
	var half := Vector2(tile_set.tile_size) * 0.5
	var top_left := map_to_local(cell) - half
	if td:
		top_left += Vector2(td.texture_origin)
		_mining_darken_sprite.flip_h = td.flip_h
		_mining_darken_sprite.flip_v = td.flip_v
	else:
		_mining_darken_sprite.flip_h = false
		_mining_darken_sprite.flip_v = false
	_mining_darken_sprite.position = top_left
	var p := clampf(progress_01, 0.0, 1.0)
	var dim := lerpf(0.92, 0.62, p)
	_mining_darken_sprite.modulate = Color(dim, dim, dim, 1.0)
	_mining_darken_sprite.visible = true


func clear_mining_cell_darken() -> void:
	if _mining_darken_sprite:
		_mining_darken_sprite.visible = false

func _required_hits_for_source(source_id: int) -> int:
	match source_id:
		GRASS_MIDDLE_SOURCE_ID, GRASS_LEFT_SOURCE_ID, GRASS_RIGHT_SOURCE_ID, GRASS_FULL_SOURCE_ID:
			return 1
		DIRT_SOURCE_ID:
			return 2
		STONE_SOURCE_ID:
			return 4
		REINFORCED_SOURCE_ID:
			return 8
		_:
			return 1

func _primary_drop_kind_for_source(source_id: int) -> String:
	match source_id:
		GRASS_MIDDLE_SOURCE_ID, GRASS_LEFT_SOURCE_ID, GRASS_RIGHT_SOURCE_ID, GRASS_FULL_SOURCE_ID:
			return "dirt"
		DIRT_SOURCE_ID:
			return "dirt"
		STONE_SOURCE_ID:
			return "stone"
		REINFORCED_SOURCE_ID:
			return "reinforced"
		_:
			return ""

func _build_drops_for_source(source_id: int) -> Array:
	match source_id:
		DIRT_SOURCE_ID:
			return [{"kind": "dirt", "amount": 1}]
		STONE_SOURCE_ID:
			return [{"kind": "stone", "amount": 1}]
		REINFORCED_SOURCE_ID:
			return [{"kind": "reinforced", "amount": 1}]
		_:
			return []

## Mined surface grass: dirt (+ optional seeds). Tile becomes air (not a dirt block); inventory gets dirt only.
func _build_drops_for_grass_stripped_to_dirt() -> Array:
	var drops: Array = [{"kind": "dirt", "amount": 1}]
	if _terrain_rng and _terrain_rng.randf() < 0.18:
		drops.append({"kind": "seeds", "amount": 1})
	return drops


# Backwards-compat shim for callers that still reference the old helper.
func _drop_kind_for_source(source_id: int) -> String:
	return _primary_drop_kind_for_source(source_id)

func try_mine_cell(
	cell: Vector2i,
	tool: String,
	tier_damage_mult: float = 1.0,
	bare_hand_slowdown: float = 5.0,
	caller_damage_mult: float = 1.0,
) -> Dictionary:
	var source_id := get_cell_source_id(cell)
	if source_id == -1:
		return {"ok": false, "reason": "empty"}
	if source_id == LAVA_SOURCE_ID:
		return {"ok": false, "reason": "hazard"}
	# Reinforced blocks: only a pickaxe touches them.
	if source_id == REINFORCED_SOURCE_ID and tool != "pickaxe":
		return {"ok": false, "reason": "needs_pickaxe"}
	var key := _cell_key(cell)
	var damage := 1
	var matched_tool := false
	# Pickaxe: stone & reinforced only. Shovel: dirt & surface grass only. No other tool gets tile bonuses.
	if tool == "pickaxe" and source_id == STONE_SOURCE_ID:
		damage = 2
		matched_tool = true
	elif tool == "pickaxe" and source_id == REINFORCED_SOURCE_ID:
		damage = 2
		matched_tool = true
	elif tool == "shovel" and source_id == DIRT_SOURCE_ID:
		damage = 3
		matched_tool = true
	elif tool == "shovel" and _is_grass_source_id(source_id):
		damage = 2
		matched_tool = true
	var mult := clampf(tier_damage_mult, 1.0, 2.5)
	var damage_f := float(damage) * mult
	if tool == "none" or not matched_tool:
		var slow := maxf(1.0, bare_hand_slowdown)
		damage_f /= slow
	var caller_mult := maxf(0.05, caller_damage_mult)
	damage_f *= caller_mult
	_tile_damage[key] = float(_tile_damage.get(key, 0.0)) + damage_f
	var hits := float(_tile_damage[key])
	var required_hits := float(_required_hits_for_source(source_id))
	if hits + 1e-4 < required_hits:
		return {
			"ok": true,
			"mined": false,
			"progress": hits / required_hits,
			"drops": [],
			"drop_kind": _primary_drop_kind_for_source(source_id),
			"drop_amount": 0,
		}
	_tile_damage.erase(key)
	var drops: Array
	var mine_feedback := ""
	if _is_grass_source_id(source_id):
		set_cell(cell, -1, Vector2i.ZERO)
		drops = _build_drops_for_grass_stripped_to_dirt()
		mine_feedback = "Stripped topsoil — dirt added."
	else:
		set_cell(cell, -1, Vector2i.ZERO)
		drops = _build_drops_for_source(source_id)
	_rebuild_surface_for_column(cell.x)
	_refresh_surface_grass_visuals_range(cell.x - 1, cell.x + 1)
	var primary_kind := ""
	var primary_amount := 0
	if not drops.is_empty():
		primary_kind = str(drops[0].get("kind", ""))
		primary_amount = int(drops[0].get("amount", 0))
	var out := {
		"ok": true,
		"mined": true,
		"progress": 1.0,
		"drops": drops,
		"drop_kind": primary_kind,
		"drop_amount": primary_amount,
	}
	if mine_feedback != "":
		out["mine_feedback"] = mine_feedback
	return out

func try_place_cell(cell: Vector2i, kind: String) -> Dictionary:
	if cell.y < 0 or cell.y >= MAP_HEIGHT:
		return {"ok": false, "reason": "out_of_bounds"}
	if get_cell_source_id(cell) != -1:
		return {"ok": false, "reason": "occupied"}
	var has_neighbor := (
		is_solid_cell(Vector2i(cell.x - 1, cell.y))
		or is_solid_cell(Vector2i(cell.x + 1, cell.y))
		or is_solid_cell(Vector2i(cell.x, cell.y - 1))
		or is_solid_cell(Vector2i(cell.x, cell.y + 1))
	)
	if not has_neighbor:
		return {"ok": false, "reason": "no_support"}
	if _cell_overlaps_actors(cell):
		return {"ok": false, "reason": "actor_overlap"}
	var source_id := _source_id_for_kind(kind)
	if source_id < 0:
		return {"ok": false, "reason": "unknown_kind"}
	var removed_plants := _clear_plants_at_cell(cell)
	set_cell(cell, source_id, Vector2i.ZERO)
	_rebuild_surface_for_column(cell.x)
	_refresh_surface_grass_visuals_range(cell.x - 1, cell.x + 1)
	return {"ok": true, "kind": kind, "removed_plants": removed_plants}

func is_reinforced_cell(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) == REINFORCED_SOURCE_ID

func _source_id_for_kind(kind: String) -> int:
	match kind:
		"dirt":
			return DIRT_SOURCE_ID
		"stone":
			return STONE_SOURCE_ID
		"reinforced":
			return REINFORCED_SOURCE_ID
		_:
			return -1

func _cell_overlaps_actors(cell: Vector2i) -> bool:
	for group_name in ["player", "bob_agent"]:
		var actor := get_tree().get_first_node_in_group(group_name)
		if not actor or not (actor is Node2D):
			continue
		var a := actor as Node2D
		# Keep overlap prevention precise: only block placement where actor core
		# currently stands (feet + torso), not broad nearby cells.
		var foot_offset := 30.0
		if a.has_method("get"):
			var candidate: Variant = a.get("surface_foot_offset")
			if candidate != null:
				foot_offset = float(candidate)
		var feet_cell := world_to_cell(a.global_position + Vector2(0.0, foot_offset))
		var torso_cell := Vector2i(feet_cell.x, feet_cell.y - 1)
		var head_cell := Vector2i(feet_cell.x, feet_cell.y - 2)
		if cell == feet_cell or cell == torso_cell or cell == head_cell:
			return true
	return false

func _clear_plants_at_cell(cell: Vector2i) -> int:
	var removed := 0
	for group_name in ["berry_bushes", "crops", "resource_nodes"]:
		for item in get_tree().get_nodes_in_group(group_name):
			if not (item is Node2D):
				continue
			var node := item as Node2D
			if not is_instance_valid(node):
				continue
			var plant_cell := world_to_cell(node.global_position)
			var overlaps := (
				plant_cell == cell
				or Vector2i(plant_cell.x, plant_cell.y - 1) == cell
				or Vector2i(plant_cell.x, plant_cell.y + 1) == cell
			)
			if overlaps:
				node.queue_free()
				removed += 1
	return removed

func _rebuild_surface_for_column(column_x: int) -> void:
	var found := false
	var first_solid_y := SURFACE_MAX_Y
	for y in range(MAP_HEIGHT):
		var cell := Vector2i(column_x, y)
		if is_solid_cell(cell):
			first_solid_y = y
			found = true
			break
	if found:
		_surface_y_by_x[column_x] = first_solid_y
	else:
		_surface_y_by_x.erase(column_x)
	_surface_cells = []
	for x in _surface_y_by_x.keys():
		_surface_cells.append(Vector2i(int(x), int(_surface_y_by_x[x])))
	_refresh_surface_grass_visuals_range(column_x - 1, column_x + 1)
