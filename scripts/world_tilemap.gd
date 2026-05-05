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
const REINFORCED_SOURCE_ID := 5

var _surface_cells: Array[Vector2i] = []
var _surface_y_by_x: Dictionary = {}
var _tile_damage: Dictionary = {}
var _generated_min_x: int = 0
var _generated_max_x: int = -1
var _terrain_rng: RandomNumberGenerator

func _ready() -> void:
	y_sort_enabled = false
	tile_set = _build_tileset()
	_terrain_rng = RandomNumberGenerator.new()
	_terrain_rng.seed = 1337
	paint_world()

func paint_world() -> void:
	clear()
	_surface_cells.clear()
	_surface_y_by_x.clear()
	_tile_damage.clear()
	_generated_min_x = 0
	_generated_max_x = INITIAL_WORLD_WIDTH_TILES - 1
	for x in range(_generated_min_x, _generated_max_x + 1):
		_paint_column_at_x(x)

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
	_add_single_tile_source(set, 0, "res://assets/blockpack/tile_grass.png")
	_add_single_tile_source(set, 1, "res://assets/blockpack/tile_dirt.png")
	_add_single_tile_source(set, 2, "res://assets/blockpack/tile_stone.png")
	_add_single_tile_source(set, 3, "res://assets/blockpack/tile_water.png")
	_add_single_tile_source(set, 4, "res://assets/blockpack/tile_lava.png")
	_add_solid_color_tile_source(set, REINFORCED_SOURCE_ID, Color(0.32, 0.38, 0.55, 1.0))
	set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	return set

func _add_single_tile_source(set: TileSet, source_id: int, texture_path: String) -> void:
	var src := TileSetAtlasSource.new()
	src.texture = load(texture_path)
	var tex_size := src.texture.get_size()
	src.texture_region_size = Vector2i(int(tex_size.x), int(tex_size.y))
	src.create_tile(Vector2i.ZERO)
	set.add_source(src, source_id)

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
		"grass": 0,
		"dirt": 1,
		"stone": 2,
		"water": 3,
		"lava": 4,
	}

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

func is_solid_cell(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= MAP_HEIGHT:
		return true
	return get_cell_source_id(cell) != -1

func is_solid_world_point(world_pos: Vector2) -> bool:
	return is_solid_cell(world_to_cell(world_pos))

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]

func _required_hits_for_source(source_id: int) -> int:
	match source_id:
		0: # grass
			return 1
		1: # dirt
			return 2
		2: # stone
			return 4
		REINFORCED_SOURCE_ID:
			return 8
		_:
			return 1

func _primary_drop_kind_for_source(source_id: int) -> String:
	match source_id:
		0:
			return "grass_block"
		1:
			return "dirt"
		2:
			return "stone"
		REINFORCED_SOURCE_ID:
			return "reinforced"
		_:
			return ""

func _build_drops_for_source(source_id: int) -> Array:
	match source_id:
		0:
			var drops: Array = [{"kind": "grass_block", "amount": 1}, {"kind": "food", "amount": 1}]
			if _terrain_rng and _terrain_rng.randf() < 0.18:
				drops.append({"kind": "seeds", "amount": 1})
			return drops
		1:
			return [{"kind": "dirt", "amount": 1}]
		2:
			return [{"kind": "stone", "amount": 1}]
		REINFORCED_SOURCE_ID:
			return [{"kind": "reinforced", "amount": 1}]
		_:
			return []

# Backwards-compat shim for callers that still reference the old helper.
func _drop_kind_for_source(source_id: int) -> String:
	return _primary_drop_kind_for_source(source_id)

func try_mine_cell(cell: Vector2i, tool: String, tier_damage_mult: float = 1.0) -> Dictionary:
	var source_id := get_cell_source_id(cell)
	if source_id == -1:
		return {"ok": false, "reason": "empty"}
	if source_id == 4:
		return {"ok": false, "reason": "hazard"}
	# Reinforced blocks: only a pickaxe touches them.
	if source_id == REINFORCED_SOURCE_ID and tool != "pickaxe":
		return {"ok": false, "reason": "needs_pickaxe"}
	var key := _cell_key(cell)
	var damage := 1
	if tool == "pickaxe" and source_id == 2:
		damage = 2
	elif tool == "axe" and source_id == 1:
		damage = 2
	elif tool == "shovel" and source_id == 1:
		damage = 3
	elif tool == "shovel" and source_id == 0:
		damage = 2
	var mult := clampf(tier_damage_mult, 1.0, 2.5)
	damage = maxi(1, int(round(float(damage) * mult)))
	_tile_damage[key] = int(_tile_damage.get(key, 0)) + damage
	var hits := int(_tile_damage[key])
	var required_hits := _required_hits_for_source(source_id)
	if hits < required_hits:
		return {
			"ok": true,
			"mined": false,
			"progress": float(hits) / float(required_hits),
			"drops": [],
			"drop_kind": _primary_drop_kind_for_source(source_id),
			"drop_amount": 0,
		}
	_tile_damage.erase(key)
	set_cell(cell, -1, Vector2i.ZERO)
	_rebuild_surface_for_column(cell.x)
	var drops := _build_drops_for_source(source_id)
	var primary_kind := ""
	var primary_amount := 0
	if not drops.is_empty():
		primary_kind = str(drops[0].get("kind", ""))
		primary_amount = int(drops[0].get("amount", 0))
	return {
		"ok": true,
		"mined": true,
		"progress": 1.0,
		"drops": drops,
		"drop_kind": primary_kind,
		"drop_amount": primary_amount,
	}

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
	set_cell(cell, source_id, Vector2i.ZERO)
	_rebuild_surface_for_column(cell.x)
	return {"ok": true, "kind": kind}

func is_reinforced_cell(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) == REINFORCED_SOURCE_ID

func _source_id_for_kind(kind: String) -> int:
	match kind:
		"dirt":
			return 1
		"stone":
			return 2
		"grass_block":
			return 0
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
