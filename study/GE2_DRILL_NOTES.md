# GE2 lab test — timed drill debrief (friction points)

This document **stands in for** a full 45–60 minute blind build: the repo [`reference-ge2-2025/`](reference-ge2-2025/) was cloned from [GE2-Test-Starter-2025](https://github.com/skooter500/GE2-Test-Starter-2025), and the starter was inspected so you know **where time goes** before you sit the real test.

## 2025 brief (Godot 4.4) — drone

Source: `reference-ge2-2025/README.MD` and `drone_scene.tscn`.

### Deliverables (README)

1. **P** — upward force on drone.
2. **W / S** — forward and back force.
3. **A / D** — rotate drone.
4. **Props** — spin up to max while force applied, spin down when idle.
5. **Camera** — lerp behind drone, look at drone.

### Marking split (use as a time budget)

| Block | Marks | Suggested order |
|-------|-------|-----------------|
| Prop subscene | 20 | First — proves pivot and mesh. |
| Drone + props | 20 | Second — instancing and transforms. |
| Flying | 20 | Third — `apply_central_force`, torque, input. |
| Camera | 20 | Fourth — `global_transform` of drone, offset vector. |
| Cool extra | 20 | Only if core stable. |

### Friction points (likely stalls)

- **RigidBody3D vs CharacterBody3D** — README wants `RigidBody3D`. Forces are in **world space** unless you use `apply_force` with local offset; rotation uses **torque** around Y for A/D. Easy mistake: applying forward force in local space without rotating the vector by the body’s basis.
- **Input map already exists** — `project.godot` defines `up`, `forward`, `reverse`, `left`, `right`. Use `Input.is_action_pressed("up")` etc.; do not waste time reinventing keys.
- **Main scene** — `run/main_scene` points at `drone_scene.tscn`. Starter scene has **ground + camera only**; you add the drone instance. Wire camera script in main or on `Camera3D`.
- **Prop spin vs thrust** — decouple visually: prop `rotation.y` accelerates while *any* driving force is non-zero, decelerates when zero—don’t tie only to “P” if W/S also count as “force applied” per README wording.
- **Subscenes** — README asks prop arm as subscene, drone as subscene, instantiated in main. Getting pivot at motor mount wrong makes props orbit strangely—use a `Marker3D` for each motor origin.
- **Camera lerp** — use drone’s `-basis.z` (or `-transform.basis.z` depending on model forward) for “behind”; `lerp` camera position in `_physics_process` for stability; `look_at(drone.global_position)`.
- **Commit cadence** — README says commit often; 2024 README says every 20 minutes. **Timer on phone** helps.

## 2024 brief (different shape) — creature generator

Remote README only (Godot path: `GE2-Test-Godot/` inside that repo): procedural creature from **sin**-based segment sizes, **gizmo** in `_process`, instantiate **head** (Boid + `CSGBox3D`) and **body** (`CSGBox3D`), **Harmonic** + **NoiseWander**, pause until **P**.

### Friction points

- **Paper math first** — README tells you to diagram segment positions and cube sizes; skipping this costs the 30-mark gizmo section.
- **`remap(sin(...), ...)`** — tying `frequency`, `start_angle`, `base_size`, `multiplier` into a bounded size curve.
- **Packed scenes** — scaling each `CSGBox3D` after instancing; head vs body scenes.

## Practice protocol (tonight)

1. **45 min** — implement 2025 README from memory with starter only.
2. **15 min** — write three bullets: what was slow, what broke once, what you’d template next time.
3. Optional: **30 min** — skim 2024 Godot folder and trace `creature_generator.gd` if your lecturer hints procedural / sin this year.
