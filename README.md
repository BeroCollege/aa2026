# BOB Survival Prototype

A **2D survival sandbox** in Godot where you gather resources, craft tools and defenses, manage hunger, and live alongside **B.O.B.**—an autonomous companion who helps himself to the world (and sometimes to you).

---

## Requirements

- **Godot Engine 4.6** (project `config/features` targets 4.6).
- A **desktop** OS supported by Godot 4.x (e.g. macOS, Windows, Linux). This build is a keyboard/mouse prototype (no gamepad mapping in `project.godot`).

---

## How to run

1. Install [Godot 4.6](https://godotengine.org/download) (version must match the project feature pin).
2. **Import** this folder as a project, or open `project.godot` from the Project Manager.
3. Press **F5** (or **Run Project**). The configured main scene is:

   `res://scenes/StartScreen.tscn`

4. From the start screen, choose **Start** to load the gameplay scene `res://scenes/Main.tscn`.

Settings (volume, fullscreen, vsync) persist via the autoload `RunRecords` config path used by `scripts/start_screen.gd`.

---

## How to play

### Movement and camera

| Action | Default binding |
|--------|-----------------|
| Move left / right | **A** / **D** |
| Move down | **S** |
| Move up (climb intent) | **W** |
| Jump | **Space**; grounded jump also accepts **W** (`move_up`) |

**Note:** **S** is bound to both **`move_down`** and **`mine_block`** in `project.godot`. For predictable mining, prefer **left mouse button** for mine/break, or rebind in the Godot **Input Map**.

### Interaction, combat, and building

| Action | Default binding |
|--------|-----------------|
| Interact / gather (nearest valid target) | **E** |
| Mine / break (cursor tile or resource; tool-dependent) | **S**, **left mouse** |
| Place block (material cycles separately) | **V** (hold repeats placement while valid) |
| Cycle place material (`dirt` → `stone` → `reinforced`) | **X** |
| Place **Calm Totem** (consumes crafted totems) | **T** |
| Feed B.O.B. | **Q** |

Point mining and placement use the **mouse cursor** within reach (see exports on `scripts/player.gd` such as `tile_mine_reach`).

### Tools and crafting UI

| Action | Default binding |
|--------|-----------------|
| Select tool | **1** sword, **2** pickaxe, **3** axe, **4** shovel, **5** hoe (only if you own that tool) |
| Open / close craft menu | **C** or **F** (`craft_tool`) |
| Craft shovel from craft menu | **6** (only while craft menu is open) |
| Toggle debug overlay | **I** |

**Pause:** **Escape** (`ui_cancel`) opens the pause menu when the craft menu is closed; with craft open, **Escape** or **C**/**F** closes craft first (`scripts/main.gd`).

Melee vs actors: **non-hoe** tools can hit **monsters** in range; **B.O.B.** only loses **HP** from the **sword** (other tools “bonk” without HP damage). Sword hits require line of sight past solid tiles.

### Farming (hoe)

With the **hoe** selected: **E** or cursor mining can till, plant **seeds**, and **harvest** crops for food and seeds (see `scripts/player.gd`).

---

## Core loop

- **Gather:** Chop trees, mine tiles, loot chests, harvest crops—resources go into `GameManager` inventory (`wood`, `stone`, `food`, `seeds`, `dirt`, etc.).
- **Craft:** Use the craft menu to spend wood/stone on **tools**, **Calm Totems** (5 wood + 5 stone each), **reinforced** placeables (2 wood + 4 stone → 4 reinforced), **Bob snacks**, **cooked meals**, and **stone-tipped tool upgrades** (`scripts/game_manager.gd`).
- **Survive:** **Hunger** drains over time (faster while moving). **Starvation** damages health at 0 hunger. High hunger can trigger passive healing. Hazards and **B.O.B.** in aggressive states also damage the player.
- **Build:** Place **dirt**, **stone**, or **reinforced** blocks to shape terrain. **Reinforced** cells need a **pickaxe** to mine (player); B.O.B. skips reinforced tiles for his AI mines.
- **Stabilize B.O.B.:** **Feed** him, deploy **Calm Totems** (aura forces friendly mode while inside), or manage distance and combat—see below.

Night/day: `GameManager.enable_night_cycle` defaults to **false**; when enabled, day length is `day_length_seconds` and night affects Bob’s **safety** need (`scripts/bob_agent.gd`).

---

## About B.O.B.

### Role

**B.O.B.** is the game’s **autonomous NPC companion**: not a player character, but a persistent **CharacterBody2D** agent (`scripts/bob_agent.gd`) that shares the world, inventory economy, and tilemap with you. He is framed as a chaotic partner—useful for spectacle and pressure—while the design grounds his actions in explicit state machines and numeric needs.

### What he does

- **Friendly mode:** Wanders to **forage targets**, mines adjacent exposed tiles for drops (fed into `collect_for_bob`), gains **hunger** / **energy**, and drifts near you with a side offset when close.
- **Attack mode:** **Chases** you (with lead-ahead on your horizontal velocity), may **sabotage** (inventory theft when `GameManager.can_bob_sabotage()`), **force-closes doors**, **breaks chests**, **places climb steps** from his dirt/stone stock when you are high above him and no walk/jump path exists, and applies **bite**, **annoy**, and **shove** pressure (see exports).
- **World denial:** When you are **low on health**, he can steer to **bury ripe berry bushes** near you by placing blocks (`_try_deny_player_food`).
- **Sword discipline:** Only the **sword** reduces his **HP** (`PLAYER_HP_DAMAGE_WEAPON_ID`). He **respawns** off-screen after death, **always in ATTACK** with fresh HP (`_respawn_after_death`).

### Needs and modes (technical)

Exported fields on `BobAgent` drive **hunger**, **safety**, **curiosity**, **energy**, **trust_to_player**, **affection**, and **health** (max HP is synced from sword damage × `target_sword_hits_to_kill` and tier bonus—see `_sync_max_health_from_sword_balance`). Internal enum **`BobMode.FRIENDLY`** vs **`BobMode.ATTACK`** gates high-level behavior each physics tick.

**Mode timer:** After `_roll_mode_timer`, he stays in the current mode for a random duration in `[friendly_mode_min_seconds, friendly_mode_max_seconds]` or `[attack_mode_min_seconds, attack_mode_max_seconds]` until the timer expires—**unless** overridden (totem / enrage floor).

**Calm Totem:** While `_calm_aura_count > 0`, he is **forced FRIENDLY**, enrage is cleared, and mode selection returns early (`set_calm_aura_active` / `_select_mode`).

**Hunger and biting:** Continuous **`bite_damage_per_second`** applies in bite range when hunger is below mode-specific ceilings (`bite_attack_hunger_max` / `bite_friendly_hunger_max`), raised while **hurt enrage** is active.

**Feeding:** `receive_food` spikes hunger, health, safety, energy, trust, affection, and lowers curiosity—player feed also calls `suppress_bob_sabotage_for` on the manager (`scripts/player.gd`).

### What causes behavior changes (mechanics, not lore)

Behavior changes come from **code-visible triggers** in `scripts/bob_agent.gd` and hooks elsewhere:

1. **Random mode roll** when `_mode_timer` hits zero: a **`bias_to_attack`** is computed, then compared to `randf()`.
2. **Bias inputs** (all exported tunables): base `attack_mode_base_bias`; **early-game grace** reduces attack bias for the first ~16s and again until ~38s (`attack_bias_early_grace_*`); **high hunger** (`attack_bias_hunger_threshold`) pushes toward attack; **low trust** pushes toward attack; **low energy** reduces attack bias; **close range + sword equipped** applies a **penalty** to attack bias **unless** hurt-enrage ignores it; **hurt enrage** adds `hurt_enrage_attack_bias_add`. Noise: `attack_bias_randomness`. Result is clamped to `[attack_bias_min, attack_bias_max]`.
3. **Calm Totem aura** overrides selection to **FRIENDLY** whenever active (see above).
4. **Sword HP damage** via `receive_damage` (only when `melee_weapon == "sword"`): sets **ATTACK**, starts **`hurt_enrage_timer`**, applies knockback, reduces trust/affection/safety/hunger, and floors `_mode_timer` at `hurt_enrage_mode_timer_floor_seconds` if not in a totem aura. Enrage speeds annoy/shove/bite pacing and chase (`hurt_enrage_*` exports). Timer can **recharge** while you stay in sword melee range (`_update_enrage_melee_pressure`) or **clear** if you move beyond `hurt_enrage_player_back_off_clear_range`.
5. **Respawn after defeat:** `_respawn_after_death` resets HP, clears enrage, sets mode to **ATTACK**, and rolls a new attack timer—documented in-game as angry return.
6. **Player “bonk” without sword:** Pickaxe/axe/shovel/bare-hand hits on Bob do not cut HP but still call `suppress_bob_sabotage_for` on the manager for a shorter window (`scripts/player.gd`).

For any balance or personality tuning not described here, rely on the **Inspector exports** on the `Bob` node / `bob_agent.gd` (search `@export` in that file).

---

## Repository layout (high level)

| Path | Role |
|------|------|
| `project.godot` | App name, main scene, input map |
| `scenes/` | `StartScreen.tscn`, `Main.tscn`, entities |
| `scripts/` | `player.gd`, `bob_agent.gd`, `game_manager.gd`, `main.gd`, world/tile logic |
| `assets/` | Art, audio, UI textures |

This README reflects the prototype as of the current scripts; gameplay is subject to scene export overrides in the editor.
