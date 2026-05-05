# Small context bites for NotebookLM (GE2 / AA lab)

Use these as **extra** sources alongside `NOTEBOOKLM_GE2_LAB_TEST_2025.md` and `NOTEBOOKLM_GE2_LAB_TEST_2024.md`.

---

## What “the lab test” usually is in this module

- A **timed practical** in Godot: you extend a **starter repo**, implement behaviour from a **short README**, submit a **git repo** (often a Microsoft Forms link in the README).
- It is **separate from the big semester assignment**. The assignment is “lifeform / AI over weeks”; the lab is “make this run today.”
- Past years are not a promise of tomorrow’s exact task, but they show **skills that repeat**: 3D scenes, input, physics or procedural spawning, and following a marking table.

---

## 2025 vs 2024 in one breath

- **2025:** `RigidBody3D` drone, **forces**, props that **react to thrust**, **chase camera** with lerp. No course steering library required.
- **2024:** `**@tool` generator**, **sin + remap** for segment sizes, **DebugDraw / gizmos** in `_process`, **instantiate** head (Boid + Harmonic + NoiseWander) and body (`CSGBox3D`) in `_ready`, **P** toggles pause on the Boid.

If tomorrow’s brief mentions **drone / props / camera**, study the 2025 doc. If it mentions **creature / sin / gizmo / segments**, study the 2024 doc.

---

## Godot patterns that show up in labs (not full tutorials)

**RigidBody3D thrust in the nose direction (world correct):**

- Use the body’s axes in world space, e.g. `global_transform.basis` (or `global_basis` in GDScript 4) times a local direction vector, **not** raw `Vector3.FORWARD` unless you mean world +Z on purpose.

**Lerp smoothing:**

- `a = lerp(a, target, k * delta)` with small `k` gives frame-rate-stable easing; clamp huge deltas if needed.

**PackedScene workflow:**

- `var scene = preload("res://prop.tscn")` then `var node = scene.instantiate()` then `add_child(node)` then set transform / exported refs.

**Input map:**

- Prefer `Input.is_action_pressed("name")` and `Input.get_axis("neg", "pos")` so keys match the project’s `project.godot`—saves time in exam.

`**@tool` scripts:**

- Run in the editor as well as in game; use `Engine.is_editor_hint()` when behaviour must differ (e.g. do not spawn physics bodies only in editor, or opposite depending on brief).

---

## Git behaviour lecturers often expect

- **Commit often** (2024 README says every ~20 minutes).
- Meaningful commit messages help if something breaks and you need to roll back.
- Submit **your fork’s URL** or zip per the form in the README—read that line the night before so you are not guessing the portal under stress.

---

## If a written or viva fragment appears (less common than coding)

- **Seek / arrive / pursue** in one sentence each (movement toward a point, stopping at a point, intercepting a moving point).
- **Flocking:** separation, alignment, cohesion.
- **FSM:** states + transitions; **BT:** tasks / selectors / sequences (high level only).

Your NotebookLM sources for **coding** are still the lab READMEs + the two big markdown explainers; add `aa-26` README **week list** only if you want theory quizzing mixed in.

---

## Integrity reminder

Use reference repos and AI to learn **patterns** and **debugging**. On the day, implement **your own** solution from the brief you are given unless open-book rules say otherwise.