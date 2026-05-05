# GE2 / AA lab test 2025 — NotebookLM context (Godot 4.4 drone)

This document describes the **2025 in-class lab test** as published by the module: goals, marking, project layout, and how the **reference implementation** wires Godot together. Source: public repos **GE2-Test-Starter-2025** (empty starter) and **GE2-Test-2025** (completed example).

---

## 1. What the test asks for (brief)

You build a **3D drone** in Godot:

- **P** — upward force on the drone body.
- **W / S** — forward and backward force.
- **A / D** — rotate the drone (yaw).
- **Propellers** — visually speed up while thrust is applied, spin down when thrust stops.
- **Camera** — smoothly moves to a position **behind** the drone and **looks at** the drone.

The README explicitly says you **do not need steering behaviors** for this year; it is a **RigidBody3D + input + camera lerp** exercise.

**Marking (100 marks):**

| Task | Marks |
|------|-------|
| Creating the prop | 20 |
| Creating the drone and adding the props | 20 |
| Driving the drone | 20 |
| Camera behaviour | 20 |
| “Any other cool thing” | 20 |

---

## 2. Project files you care about

| File | Role |
|------|------|
| `project.godot` | Godot 4.4 project; defines **InputMap** actions: `up` (P), `forward`/`reverse` (W/S), `left`/`right` (A/D). |
| `drone_scene.tscn` | **Main scene**: world (ground, light), **instance** of `drone.tscn`, `Camera3D` with chase script, optional `Marker3D` for camera anchor. |
| `drone.tscn` | **Drone subscene**: root is `RigidBody3D` with `drone.gd`; mesh + collision; **four instances** of `prop.tscn` as children. |
| `prop.tscn` | **Prop subscene**: `Node3D` root + `prop.gd`; visual is CSG primitives parented under an `axle` node that spins. |
| `drone.gd` | Physics and input on the **RigidBody3D**. |
| `prop.gd` | Reads whether the drone is “motors on” and **lerps** spin speed, rotates `axle`. |
| `tp_camera.gd` | Third-person camera: **lerp** position toward a target node, `look_at` drone. |

---

## 3. Input map (do not reinvent keys)

The starter already binds actions (names matter in code):

- `up` — physical key **P** (lift).
- `forward` / `reverse` — **W** / **S** (and arrow keys in the exported map).
- `left` / `right` — **A** / **D** (and arrow keys).

In GDScript use:

- `Input.is_action_pressed("up")`
- `Input.get_axis("reverse", "forward")` — note axis order matches “forward positive” convention used in the sample.
- `Input.get_axis("left", "right")` for turn.

---

## 4. Drone body script (`drone.gd`) — ideas explained

The reference script extends **RigidBody3D** and runs logic in **`_physics_process`** (same tick rate as physics — good for forces and camera follow).

**Motor flag:** A boolean `motor_on` is reset to `false` at the **start** of each physics frame, then set `true` whenever any thrust or turn input is active. Props read this flag so they spin whenever the craft is being driven.

**Forward / back thrust:** Uses `apply_central_force(global_basis.z * power * f)` where `f` comes from `Input.get_axis("forward", "reverse")`. So thrust is along the drone’s **global** Z axis of its transform (body-relative direction in world space). Wrong axis = drone slides sideways.

**Lift:** If `up` is pressed, `motor_on = true` and `apply_central_force(global_basis.y * power)` applies force along the drone’s **up** axis (world-aligned to the drone’s current orientation).

**Yaw:** Uses `rotate_y(-turn * deg_to_rad(rot_speed) * delta)` with `turn` from `Input.get_axis("left", "right")`. This directly rotates the rigid body each frame (simple exam-style approach; alternative is `apply_torque`).

**Exported tuning:** `@export var power` scales force; `rot_speed` is degrees per second for yaw.

---

## 5. Prop script (`prop.gd`) — ideas explained

- Root type **Node3D** (not RigidBody): props follow the drone transform as children.
- `@export var copter: RigidBody3D` — assigned in the editor per instance so each prop can read **`copter.motor_on`** from the drone script.
- `@onready var axle: Node3D = $axle` — the mesh that visually spins.
- **Spin model:** Variable `speed` lerps toward `rot_speed` when `motor_on`, else lerps toward `0` (faster decay with `delta * 2` in the reference). Each frame `axle.rotate_y(speed * delta * 2.0)` applies the visual rotation.

**Exam trap:** Forgetting to assign **`copter`** on each prop instance → null / wrong reference → props never spin.

---

## 6. Camera script (`tp_camera.gd`) — ideas explained

- Extends **Camera3D**.
- Resolves `drone` and **`cam_target`** (a **Marker3D** child of the drone placed **behind and above** the craft in the reference scene).
- Each `_physics_process`:  
  `global_position = lerp(global_position, cam_target.global_position, delta * 5)`  
  then `look_at(drone.global_position)`.

So the camera eases toward a **pre-authored offset** in the drone scene rather than computing “behind” purely in code. Both patterns are valid in an exam if the README only says “behind and look at”.

---

## 7. Scene tree mental model

```
drone_scene (Node3D)
├── StaticBody3D (ground)
├── drone (instance of drone.tscn) [RigidBody3D + drone.gd]
│   ├── prop instances…
│   └── cam_target (Marker3D)  ← camera aim point behind drone
└── Camera3D [tp_camera.gd] → references ../drone and ../drone/cam_target
```

**Subscene rule from README:** prop as its own scene; drone as its own scene; **instantiate drone** into the main scene.

---

## 8. Common mistakes under time pressure

1. Applying force using **world** `Vector3.FORWARD` instead of **`global_basis`** direction of the drone.
2. Putting flight logic in `_process` while using RigidBody3D → jitter or inconsistent physics.
3. Props tied only to **P** when README says props react whenever **force** is applied (usually W/S and P and sometimes turn should all set `motor_on`).
4. Camera parented wrong so `NodePath` to `drone` breaks after reparenting — use groups or `@export` NodePaths if needed.
5. Forgetting **collision** on drone or ground → infinite fall.

---

## 9. Embedded reference code (GE2-Test-2025)

### `drone.gd`

```gdscript
extends RigidBody3D

@export var power:float = 10

var motor_on = false
var rot_speed = 360

func _ready() -> void:
	pass

func _physics_process(delta: float):
	motor_on = false

	var f = Input.get_axis("forward", "reverse")
	if f != 0:
		motor_on = true
		apply_central_force(global_basis.z * power * f)

	if Input.is_action_pressed("up"):
		motor_on = true
		apply_central_force(global_basis.y * power)

	var turn = Input.get_axis("left", "right")
	if turn != 0.0:
		motor_on = true
		rotate_y(- turn * deg_to_rad(rot_speed) * delta)
```

### `prop.gd`

```gdscript
extends Node3D

@export var copter: RigidBody3D

@onready var axle: Node3D = $axle

@export var rot_speed:float = 20

func _ready() -> void:
	pass

var speed:float = 0

func _physics_process(delta: float) -> void:
	if copter.motor_on:
		speed = lerp(speed, rot_speed, delta)
	else:
		speed = lerp(speed, 0.0, delta * 2.0)
	axle.rotate_y(speed * delta * 2.0)
```

### `tp_camera.gd`

```gdscript
extends Camera3D

@onready var drone = $"../drone"
@onready var cam_target = $"../drone/cam_target"

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	global_position = lerp(global_position, cam_target.global_position, delta * 5)
	look_at(drone.global_position)
```

---

## 10. How NotebookLM should help you study this

- Quiz: “What does `global_basis.z` mean for thrust?” “Why `_physics_process`?” “What breaks if `copter` is unset on props?”
- Ask for a **minimal scene checklist** in exam order: prop scene → drone scene → main scene → camera → test inputs.
- Ask for **debugging questions**: drone falls through floor, props do not spin, camera does not follow — each with likely causes.

This file is **study context only**; your real exam may use a variant starter—always follow the README you receive on the day.
