extends Node
class_name GameManager

@export var day_length_seconds: float = 45.0
@export var sabotage_cooldown_seconds: float = 6.0
@export var enable_night_cycle: bool = false
@export var debug_mode_enabled: bool = false
@export var player_max_health: float = 100.0
@export var player_max_hunger: float = 100.0
@export var full_hunger_heal_tick_seconds: float = 2.5
@export var full_hunger_heal_amount: float = 16.666667
@export var starvation_tick_seconds: float = 1.0
@export var starvation_damage_per_tick: float = 2.0

var player_resources: int = 0
var bob_resources: int = 0
var is_night: bool = false
var player_health: float = 100.0
var player_hunger: float = 100.0
var player_alive: bool = true
## Per-tool tier: 0 = wooden (wood-only craft), 1 = stone-tipped upgrade.
var tool_tiers: Dictionary = {
	"pickaxe": 0,
	"axe": 0,
	"sword": 0,
	"hoe": 0,
	"shovel": 0,
}

const TOOL_WOOD_ONLY_COST := {
	"pickaxe": 4,
	"axe": 5,
	"sword": 4,
	"hoe": 4,
	"shovel": 3,
}

## Upgrade cost after you already own the wooden tool (wood + stone).
const TOOL_UPGRADE_COST := {
	"pickaxe": {"wood": 1, "stone": 2},
	"axe": {"wood": 2, "stone": 1},
	"sword": {"wood": 1, "stone": 3},
	"hoe": {"wood": 2, "stone": 1},
	"shovel": {"wood": 1, "stone": 1},
}

var inventory := {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"seeds": 0,
	"dirt": 0,
	"reinforced": 0,
	"totems": 0,
	"pickaxe": 0,
	"axe": 0,
	"sword": 0,
	"hoe": 0,
	"shovel": 0,
	"bob_snacks": 0,
}

var _day_timer: float = 0.0
var _sabotage_timer: float = 0.0
var _bob_suppress_sabotage_timer: float = 0.0
var _player_is_moving: bool = false
var _full_hunger_heal_timer: float = 0.0
var _starvation_timer: float = 0.0
const _HUD_STATUS_SEGMENTS := 6.0

func _process(delta: float) -> void:
	_day_timer += delta
	_sabotage_timer = maxf(0.0, _sabotage_timer - delta)
	_bob_suppress_sabotage_timer = maxf(0.0, _bob_suppress_sabotage_timer - delta)

	if enable_night_cycle:
		if _day_timer >= day_length_seconds:
			_day_timer = 0.0
			is_night = !is_night
	else:
		is_night = false

	_update_player_survival(delta)
	_apply_debug_inventory()

func collect_for_player(amount: int = 1) -> void:
	collect_for_player_resource("wood", amount)

func collect_for_player_resource(resource_kind: String, amount: int = 1) -> void:
	if not inventory.has(resource_kind):
		inventory[resource_kind] = 0
	inventory[resource_kind] += amount
	if resource_kind == "food":
		player_hunger = minf(player_max_hunger, player_hunger + float(amount) * 6.0)
	else:
		player_hunger = minf(player_max_hunger, player_hunger + float(amount) * 1.5)
	player_resources = _resource_score()

func collect_for_bob(amount: int = 1) -> void:
	bob_resources += amount

func notify_inventory_changed() -> void:
	player_resources = _resource_score()

func is_bob_sabotage_suppressed() -> bool:
	return _bob_suppress_sabotage_timer > 0.0

func suppress_bob_sabotage_for(seconds: float) -> void:
	_bob_suppress_sabotage_timer = maxf(_bob_suppress_sabotage_timer, seconds)

func can_bob_sabotage() -> bool:
	return _sabotage_timer <= 0.0 and player_resources > 0 and not is_bob_sabotage_suppressed()

func bob_sabotage() -> int:
	if not can_bob_sabotage():
		return 0
	var stolen: int = min(2, player_resources)
	player_resources -= stolen
	bob_resources += stolen
	_remove_random_player_resources(stolen)
	_sabotage_timer = sabotage_cooldown_seconds
	return stolen

func get_tool_tier(tool: String) -> int:
	return int(tool_tiers.get(tool, 0))

func get_tool_mining_multiplier(tool: String) -> float:
	return 1.22 if get_tool_tier(tool) >= 1 else 1.0

func get_tool_effectiveness_multiplier(tool: String) -> float:
	return 1.15 if get_tool_tier(tool) >= 1 else 1.0

func get_wood_cost_for_tool(tool: String) -> int:
	return int(TOOL_WOOD_ONLY_COST.get(tool, 0))

func get_upgrade_cost_line(tool: String) -> String:
	if not TOOL_UPGRADE_COST.has(tool):
		return ""
	var c: Dictionary = TOOL_UPGRADE_COST[tool]
	return "%d Wood + %d Stone" % [int(c.get("wood", 0)), int(c.get("stone", 0))]

func can_craft_tool() -> bool:
	if debug_mode_enabled:
		return true
	return inventory["wood"] >= int(TOOL_WOOD_ONLY_COST["pickaxe"])

func craft_tool() -> bool:
	if debug_mode_enabled:
		inventory["pickaxe"] += 1
		player_resources = _resource_score()
		return true
	var cost: int = int(TOOL_WOOD_ONLY_COST["pickaxe"])
	if inventory["wood"] < cost:
		return false
	inventory["wood"] -= cost
	inventory["pickaxe"] += 1
	player_resources = _resource_score()
	return true

func craft_axe() -> bool:
	if debug_mode_enabled:
		inventory["axe"] += 1
		player_resources = _resource_score()
		return true
	var cost: int = int(TOOL_WOOD_ONLY_COST["axe"])
	if inventory["wood"] < cost:
		return false
	inventory["wood"] -= cost
	inventory["axe"] += 1
	player_resources = _resource_score()
	return true

func craft_sword() -> bool:
	if debug_mode_enabled:
		inventory["sword"] += 1
		player_resources = _resource_score()
		return true
	var cost: int = int(TOOL_WOOD_ONLY_COST["sword"])
	if inventory["wood"] < cost:
		return false
	inventory["wood"] -= cost
	inventory["sword"] += 1
	player_resources = _resource_score()
	return true

func craft_hoe() -> bool:
	if debug_mode_enabled:
		inventory["hoe"] += 1
		player_resources = _resource_score()
		return true
	var cost: int = int(TOOL_WOOD_ONLY_COST["hoe"])
	if inventory["wood"] < cost:
		return false
	inventory["wood"] -= cost
	inventory["hoe"] += 1
	player_resources = _resource_score()
	return true

func craft_shovel() -> bool:
	if debug_mode_enabled:
		inventory["shovel"] += 1
		player_resources = _resource_score()
		return true
	var cost: int = int(TOOL_WOOD_ONLY_COST["shovel"])
	if inventory["wood"] < cost:
		return false
	inventory["wood"] -= cost
	inventory["shovel"] += 1
	player_resources = _resource_score()
	return true

func upgrade_tool(tool: String) -> bool:
	if debug_mode_enabled:
		tool_tiers[tool] = 1
		player_resources = _resource_score()
		return true
	if not TOOL_UPGRADE_COST.has(tool):
		return false
	if int(inventory.get(tool, 0)) < 1:
		return false
	if get_tool_tier(tool) >= 1:
		return false
	var c: Dictionary = TOOL_UPGRADE_COST[tool]
	var need_w: int = int(c.get("wood", 0))
	var need_s: int = int(c.get("stone", 0))
	if inventory["wood"] < need_w or inventory["stone"] < need_s:
		return false
	inventory["wood"] -= need_w
	inventory["stone"] -= need_s
	tool_tiers[tool] = 1
	player_resources = _resource_score()
	return true

func craft_calm_totem() -> bool:
	if debug_mode_enabled:
		inventory["totems"] += 1
		player_resources = _resource_score()
		return true
	if inventory["wood"] < 5 or inventory["stone"] < 5:
		return false
	inventory["wood"] -= 5
	inventory["stone"] -= 5
	inventory["totems"] += 1
	player_resources = _resource_score()
	return true

func craft_reinforced_block(amount: int = 4) -> bool:
	if debug_mode_enabled:
		inventory["reinforced"] += amount
		player_resources = _resource_score()
		return true
	if inventory["wood"] < 2 or inventory["stone"] < 4:
		return false
	inventory["wood"] -= 2
	inventory["stone"] -= 4
	inventory["reinforced"] += amount
	player_resources = _resource_score()
	return true

func craft_bob_snack() -> bool:
	if debug_mode_enabled:
		inventory["bob_snacks"] += 1
		player_resources = _resource_score()
		return true
	if inventory["food"] < 2 or inventory["wood"] < 1:
		return false
	inventory["food"] -= 2
	inventory["wood"] -= 1
	inventory["bob_snacks"] += 1
	player_resources = _resource_score()
	return true

func craft_cooked_meal() -> bool:
	if debug_mode_enabled:
		player_hunger = minf(player_max_hunger, player_hunger + 26.0)
		return true
	if inventory["food"] < 3 or inventory["wood"] < 1:
		return false
	inventory["food"] -= 3
	inventory["wood"] -= 1
	player_hunger = minf(player_max_hunger, player_hunger + 26.0)
	player_resources = _resource_score()
	return true

func take_player_food(amount: int = 1) -> int:
	if debug_mode_enabled:
		return amount
	var available: int = inventory["food"]
	if available <= 0:
		return 0
	var taken: int = min(amount, available)
	inventory["food"] -= taken
	player_resources = _resource_score()
	return taken

func take_bob_snack(amount: int = 1) -> int:
	if debug_mode_enabled:
		return amount
	var available: int = inventory["bob_snacks"]
	if available <= 0:
		return 0
	var taken: int = min(amount, available)
	inventory["bob_snacks"] -= taken
	return taken

func heal_player(amount: float) -> void:
	if not player_alive:
		return
	player_health = minf(player_max_health, player_health + amount)

func damage_player(amount: float) -> void:
	if not player_alive:
		return
	player_health = maxf(0.0, player_health - amount)
	if player_health <= 0.0:
		player_alive = false

func _update_player_survival(delta: float) -> void:
	if not player_alive:
		return
	var drain_rate := 1.6 if _player_is_moving else 0.18
	player_hunger = maxf(0.0, player_hunger - drain_rate * delta)
	if player_hunger <= 0.0:
		_starvation_timer += delta
		var starvation_tick := maxf(0.05, starvation_tick_seconds)
		while _starvation_timer >= starvation_tick and player_alive:
			_starvation_timer -= starvation_tick
			damage_player(starvation_damage_per_tick)
	else:
		_starvation_timer = 0.0

	# Match main HUD rounding (6 segments): "full" HUD hunger should be heal-eligible.
	var full_hunger_threshold := (5.5 / _HUD_STATUS_SEGMENTS) * player_max_hunger
	if player_hunger >= full_hunger_threshold and player_health < player_max_health:
		_full_hunger_heal_timer += delta
		var heal_tick := maxf(0.05, full_hunger_heal_tick_seconds)
		while _full_hunger_heal_timer >= heal_tick and player_alive:
			_full_hunger_heal_timer -= heal_tick
			heal_player(full_hunger_heal_amount)
	else:
		_full_hunger_heal_timer = 0.0

func set_player_moving(is_moving: bool) -> void:
	_player_is_moving = is_moving

func _remove_random_player_resources(count: int) -> void:
	var types := ["wood", "stone", "food"]
	var remaining := count
	for t in types:
		if remaining <= 0:
			break
		var available: int = inventory[t]
		if available <= 0:
			continue
		var removed: int = min(available, remaining)
		inventory[t] -= removed
		remaining -= removed
	player_resources = _resource_score()

func _resource_score() -> int:
	return (
		inventory["wood"] + inventory["stone"] + inventory["food"] + inventory["seeds"]
		+ inventory["dirt"] + inventory["reinforced"] * 2 + inventory["totems"] * 5
		+ inventory["pickaxe"] * 2 + inventory["axe"] * 2 + inventory["sword"] * 2
		+ inventory["hoe"] * 2 + inventory["shovel"] * 2
	)

func _apply_debug_inventory() -> void:
	if not debug_mode_enabled:
		return
	var baseline := {
		"wood": 999,
		"stone": 999,
		"food": 999,
		"seeds": 999,
		"dirt": 999,
		"reinforced": 999,
		"totems": 9,
		"pickaxe": 1,
		"axe": 1,
		"sword": 1,
		"hoe": 1,
		"shovel": 1,
		"bob_snacks": 999,
	}
	for key in baseline.keys():
		inventory[key] = maxi(int(inventory.get(key, 0)), int(baseline[key]))
	player_resources = _resource_score()
