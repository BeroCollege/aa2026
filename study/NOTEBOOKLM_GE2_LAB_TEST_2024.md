# GE2 / AA lab test 2024 — NotebookLM context (Godot creature generator)

This document describes the **2024 in-class lab test** (different style from 2025): procedural creature, **gizmos**, **sin-based sizing**, and **Boid** steering stack. Source: **GE2-Test-2024-Starter** on GitHub (`README.md` at repo root; Godot project under **`GE2-Test-Godot/`**). The starter’s `creature_generator.gd` is intentionally empty—you implement it under exam conditions.

---

## 1. What the test asks for (brief)

Open **`exam_scene`** in the Godot project. Modify **`creature_generator.gd`** (note README spelling variant `creature_genereator` in places—actual file is `behaviors/creature_generator.gd`).

**You must:**

1. **Add exported fields** on the generator for: `length`, `frequency`, `start_angle`, `base_size`, `multiplier` (and use them in math).
2. **In `_process`**, draw **editor / runtime gizmos** showing where creature segments will appear (cubes along a path), matching the reference video behaviour.
3. **Compute each segment’s size** using a **sin wave**: `frequency` controls repetitions along the length; `start_angle` is a phase offset; `base_size` is minimum segment size; **`multiplier * base_size`** is the maximum—README suggests **`remap`** to map sin output into that size range.
4. **In `_ready`**, **instantiate** the creature from a **head** packed scene and a **body** packed scene: build segments along the path, each from packed scenes, set **size** on `CSGBox3D` nodes.
5. **Head scene** should include **Harmonic** and **NoiseWander** behaviours (already part of course’s Boid stack). Head is a **Boid** with a `CSGBox3D` child; body scene is just a `CSGBox3D`.
6. **Boid starts paused**; pressing **P** unpauses (toggle implemented in `Boid.gd`).

**Marking (100 marks):**

| Description | Marks |
|-------------|-------|
| Adding fields | 10 |
| Gizmo drawing | 30 |
| Head and body scenes / prefabs | 10 |
| Instantiating the segments | 30 |
| Any other cool thing | 20 |

**Process hint from README:** commit every **20 minutes**; work out segment positions **on paper** before coding.

---

## 2. Project layout (Godot folder)

| Path | Role |
|------|------|
| `GE2-Test-Godot/project.godot` | Godot **4.2** project; `run/main_scene` = `res://exam/exam_scene.tscn`. |
| `GE2-Test-Godot/exam/exam_scene.tscn` | Exam level: `creature_generator` node (empty script to fill), first-person `Player`, lights, etc. |
| `GE2-Test-Godot/behaviors/creature_generator.gd` | **`@tool` extends Node3D`** — your main implementation file (starter has `pass` in `_process` and `_ready`). |
| `GE2-Test-Godot/behaviors/creature.tscn` | Example creature assembly with **Boid** head, body segments, **Harmonic**, **NoiseWander**, spine animator, etc. Study for **node types** you must produce in code. |
| `GE2-Test-Godot/behaviors/exam_creature.tscn` | Another creature layout used with exam; includes **Controller**, **Boid**, body chain, tail **Pod** with signals. |
| `GE2-Test-Godot/behaviors/Boid.gd` | Core **CharacterBody3D** steering host: accumulates child behaviours, **pause** toggle on **P**, `move_and_slide()`, banking via `look_at`. |

---

## 3. What `creature_generator.gd` must do (conceptual)

Even though the starter is empty, the README defines the algorithm:

### Exported parameters

- **`length`** — total extent along which segments are placed (world units along your chosen axis, typically Z or X depending on your setup).
- **`frequency`** — how many full sin cycles fit across that length (higher = more bumps).
- **`start_angle`** — phase added inside `sin(...)` so the wave does not always start at zero.
- **`base_size`** — smallest cube size.
- **`multiplier`** — scales maximum; largest size is **`base_size * multiplier`** (per README wording).

### Sin → size

Typical pattern:

- Sample parameter `t` along the creature from `0` to `1` (or along distance `0` to `length`).
- Angle `theta = start_angle + t * frequency * TAU` (or `* 2 * PI`).
- `raw = sin(theta)` in `[-1, 1]`.
- `size = remap(raw, -1.0, 1.0, base_size, base_size * multiplier)` so cubes **breathe** along the body.

### Gizmo drawing (`_process`)

- Use **`DebugDraw3D`** (project already uses it in `Boid`) or Godot 4 **custom gizmos** / `draw_*` in editor if configured—README wants visible placement **before** spawning meshes.
- For each segment index, compute **center position** along a line or curve in **world space** and **box size** from sin; draw wireframe boxes or debug boxes matching those values so markers line up with final cubes.

### Instantiation (`_ready`)

- `preload` or `load` **head** and **body** `PackedScene`s.
- Loop segments: `inst = scene.instantiate()`, `add_child(inst)`, set `global_position` / `transform`, find `CSGBox3D`, set **`size`** property from computed dimensions.
- Ensure first segment uses **head** scene (with Boid + behaviours), others use **body** scene (CSG only), unless README specifies otherwise.

### Pause until P

- `Boid` already toggles `pause` on **KEY_P** in `_input`. Start with **`pause = true`** on the head boid in the head scene if the brief requires “starts paused”.

---

## 4. How `Boid.gd` fits the exam (excerpt ideas)

The course `Boid` is a **CharacterBody3D** that:

- Collects child nodes implementing steering (`calculate()` pattern with **weights**).
- Each `_physics_process`, if not paused: integrates **acceleration → velocity → `move_and_slide()`**.
- **Banking:** `look_at` using velocity direction blended with world up (see script comments referencing classic banking notes).
- **P key:** flips `pause` boolean so the creature freezes until the student resumes.

You mostly **compose scenes** to match this; the exam coding burden is **`creature_generator.gd`**, not rewriting `Boid`.

**Relevant excerpt (pause toggle):**

```gdscript
func _input(event):
	if event is InputEventKey and event.keycode == KEY_P and event.pressed:
		pause = ! pause
```

**Relevant excerpt (physics integration sketch):**

```gdscript
func _physics_process(delta):
	if not Engine.is_editor_hint():
		if should_calculate:
			new_force = calculate()
			should_calculate = false
		force = lerp(force, new_force, delta)
		if ! pause:
			acceleration = force / mass
			vel += acceleration * delta
			# ... clamp speed, damping ...
			set_velocity(vel)
			move_and_slide()
```

---

## 5. Scene structure hints from `creature.tscn` / `exam_creature.tscn`

- **Head** is a `CharacterBody3D` with script `Boid.gd`, mesh, collision, and child nodes: **Harmonic**, **NoiseWander**, **Constrain**, **Avoidance**, optional disabled behaviours (**Seek**, **Arrive**, etc.).
- **Body segments** are additional `CharacterBody3D` (or `Node3D` + CSG only per README) positioned along Z at intervals (example transforms use `z = 3, 6, 9, 12` spacing pattern—your generator should reproduce spacing from **your** math, not copy constants blindly).
- **SpineAnimator** node lists `bonePaths` to chain visual segments—exam may or may not require animation; README emphasises **cube sizes** and **positions**.

---

## 6. Common mistakes under time pressure

1. Skipping **paper math** → gizmo section loses 30 marks because boxes do not line up with sin logic.
2. `sin` used without **`remap`** → sizes go negative or out of `[base_size, base_size * multiplier]`.
3. Instancing scenes but not setting **`size`** on nested `CSGBox3D` → invisible or default cubes.
4. Gizmo only in editor or only in game—misusing `@tool` / `Engine.is_editor_hint()` guard in `_ready` starter pattern; know when to draw.
5. Forgetting **`@tool`** on `creature_generator.gd` if gizmos must show in editor (starter already has `@tool` at top).

---

## 7. Starter `creature_generator.gd` (empty template)

```gdscript
@tool
extends Node3D

func _process(delta):
	pass

func _ready():
	if not Engine.is_editor_hint():
		pass
```

Replace `pass` with: field declarations, gizmo drawing, and `_ready` build logic per README.

---

## 8. How NotebookLM should help you study this

- Drill the **parameter meanings** (`frequency` vs `start_angle`) until you can explain without notes.
- Generate **pseudo-code** for: “given `n` segments, place segment `i` at position … with size …”
- Ask for **gizmo debugging**: “gizmos show but instances do not match—what checks?” (axis mix-up, local vs global transform, off-by-one segment count).
- Contrast with **2025 drone test**: 2024 is **procedural geometry + sin + Boid stack**; 2025 is **RigidBody3D flight + camera lerp**.

This file is **study context only**; follow the README and scene names you receive on the day of the test.
