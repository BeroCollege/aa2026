# AI study blocks (quiz → implement-in-words → trap → cold redo)

Do each block in **30–45 minutes**: answer closed-book, then check answers, then redo **Cold redo** after a short break without peeking.

---

## Block A — Steering (weeks 1–3, aa-26)

**Artifact:** Seek, arrive, path following, controller input.

### Quiz (answer before scrolling)

1. In one sentence, what is the difference between **seek** and **arrive**?
2. Why is desired velocity usually **clamped** to `max_speed`?
3. Path following: do you steer toward the **closest point** on the path, a **look-ahead** point, or both—explain briefly.
4. Should steering integration use `_process` or `_physics_process` for a `CharacterBody2D` in Godot—why?
5. Name one failure mode of pure seek toward a moving target.

### Implement in words (pseudo-GDScript OK)

6. Write `func seek(target: Vector2) -> Vector2` returning **linear** acceleration suggestion (force direction) for a 2D agent with `max_force` and `max_speed`.
7. Write `func arrive(target: Vector2, slowing_radius: float) -> Vector2` using desired speed proportional to distance inside the radius.

### Trap question

8. You `look_at(target)` every frame while seek-moving in 2D. Why might the sprite appear to “snap” rotation, and what do you do instead?

### Answers — Block A

1. **Seek** uses full speed toward the target; **arrive** reduces desired speed as it enters a slowing radius so it can stop cleanly.
2. Otherwise displacement per frame grows without bound and the agent ignores the speed limit.
3. Typically **both**: snap/steer toward a point ahead on the path for smooth motion, often after finding closest segment for projection.
4. **`_physics_process`** — movement integrates with physics ticks; `_process` is frame-rate dependent and can jitter with physics bodies.
5. **Overshoot / orbit** — seek never “predicts” intercept; pursue fixes this.

6. Example: `var desired = (target - position).normalized() * max_speed` then `var steer = (desired - velocity).limit_length(max_force)` (adjust if using acceleration vs velocity directly).

7. Example: compute `dist = position.distance_to(target)`; if `dist < slowing_radius` then `desired_speed = max_speed * (dist/slowing_radius)` else `max_speed`; desired velocity = `to_target.normalized() * desired_speed`; steering as in seek.

8. `look_at` snaps; use `lerp` angle, `rotate_toward`, or set `rotation` from `velocity.angle()` with smoothing.

### Cold redo — Block A

Repeat items **1–5** and **8** from memory after a 10-minute break (no notes).

---

## Block B — Lab test mechanics (GE2 2025 drone README)

**Artifact:** `RigidBody3D`, forces, props, camera lerp, subscenes.

### Quiz

1. Name two ways to move a `RigidBody3D` forward in its **own** facing direction.
2. What is the difference between `apply_central_force` and `apply_force` with an offset?
3. Why lerp the camera in `_physics_process` rather than `_process` for this drone?
4. What does “props speed up when force is applied” imply about your **state** variable for thrust?
5. Subscene for prop arm: one reason to put the pivot at a `Marker3D` on the motor mount.

### Implement in words

6. Describe the camera update: given `drone: Node3D` and `cam: Camera3D`, how you compute **behind** position each physics frame (vectors only, no full code required).
7. Describe how you spin a prop mesh: which variable accumulates, how it accelerates/decelerates when input thrust changes.

### Trap question

8. You apply forward force as `Vector3.FORWARD * strength`. Why does the drone not move “forward” relative to its nose in world space?

### Answers — Block B

1. e.g. `apply_central_force(-global_transform.basis.z * thrust)` or set `linear_velocity` (less physical but sometimes used); canonical is force along `-basis.z` if forward is -Z.
2. Central applies at center of mass (no torque); offset force induces **torque** (realistic for thrusters off-center).
3. Matches physics step; reduces jitter when following a physics body.
4. You need a thrust/intensity scalar (or bool) derived from input; prop spin **follows** that scalar with its own accel toward max RPM.
5. Mesh origin may not be the hinge; Marker gives repeatable mount point for child prop.

6. e.g. `var behind = drone.global_transform.basis.z * distance` (sign depends on convention); `cam.global_position = cam.global_position.lerp(drone.global_position + behind + height_offset, k)`; `cam.look_at(drone.global_position)`.

7. e.g. `spin_speed` moves toward `max_spin` or `0` with accel/decel; `prop.rotation.y += spin_speed * delta`.

8. `Vector3.FORWARD` is **world** +Z; you need **body-local** forward, e.g. `-global_transform.basis.z`.

### Cold redo — Block B

Repeat **1–4** and **8** after a break.

---

## Block C — Architecture + flocking (weeks 5 & 11)

**Artifact:** SOLID/refactor; separation/alignment/cohesion; network sync awareness.

### Quiz

1. What does the **D** in SOLID stand for, in plain language for game scripts?
2. One “smell” that suggests a class should be split.
3. Flocking: list the **three** classic Reynolds rules.
4. Why multiply flock weights (e.g. high separation) when agents get crowded?
5. In one line: why is RPC ordering tricky over a network for “beat sync” (high level)?

### Implement in words

6. Pseudocode for **separation** only: given `neighbors: Array`, return `Vector2` steering.
7. You have a 400-line `bob_agent.gd`. Name two **concrete** splits you’d make without changing behaviour.

### Trap question

8. “We used `MultiplayerSynchronizer` so we don’t need to think about authority.” What is wrong with that statement?

### Answers — Block C

1. **Dependency inversion:** depend on abstractions (interfaces / small scripts), not concrete heavy types, so you can swap/test parts.
2. e.g. **long methods**, duplicate code, class name no longer matches what file does, many unrelated public methods.
3. **Separation, alignment, cohesion.**
4. Stronger separation prevents interpenetration and jitter in tight groups.
5. Latency and clock skew mean events arrive **out of order** or offset unless you compensate.

6. Sum `position - neighbor.position` for neighbors within radius, normalize or weight by inverse distance, cap magnitude.

7. e.g. “Needs/hunger system” in one script, “Mining/foraging actions” in another, “Mode FSM” in a small state helper (any two sensible splits).

8. You still need to decide **who owns** state, which RPCs are allowed from clients, and what is server-authoritative; synchronizers don’t remove game-design authority rules.

### Cold redo — Block C

Repeat **1–5** after a break.

---

## Suggested schedule (one evening)

| Time | Activity |
|------|----------|
| 0:00 | Block A quiz + answers |
| 0:35 | Block B quiz + answers |
| 1:10 | Block C quiz + answers |
| 1:45 | Cold redo A |
| 2:00 | Cold redo B |
| 2:15 | Cold redo C |
