# Practice questions and answers (AA / GE2)

Try each **Q** closed-book, then read **A**.

---

## Steering basics

**Q1.** In one sentence, what is steering trying to compute each frame?

**A1.** A steering acceleration or force that adjusts the agent’s velocity toward some goal while respecting limits like max speed and max force.

**Q2.** Why clamp desired velocity to max speed?

**A2.** So the agent cannot move faster than the design allows; otherwise displacement grows without bound.

**Q3.** Seek vs arrive: when do you use which?

**A3.** Use **seek** when you only need to reach a point at full speed. Use **arrive** when the agent must **settle** and stop near a target; arrive reduces desired speed inside a slowing radius.

**Q4.** What is a common visual bug if you snap `look_at` every frame toward the target?

**A4.** Jerky rotation. Prefer smoothing: lerp angle, `rotate_toward`, or derive rotation from smoothed velocity.

**Q5.** Should steering for a physics-based character usually live in `_process` or `_physics_process`?

**A5.** **`_physics_process`** so movement matches the physics tick rate and stays stable.

---

## Pursue and path following

**Q6.** Why does pure seek fail badly on a fast-moving target?

**A6.** It aims at the target’s **current** position, not where it will be; the agent chases behind in a curve or orbit. **Pursue** predicts a future position (simple linear extrapolation is common).

**Q7.** In words, how does offset pursue differ from pursue?

**A7.** Offset pursue maintains a **formation offset** relative to the leader or target, not zero distance; the desired point is the target’s position plus a rotated offset.

**Q8.** Path following: why use a look-ahead point on the path instead of only the closest point?

**A8.** Look-ahead reduces oscillation on tight corners and produces smoother tangents; closest point alone can zigzag on the polyline.

---

## Flocking

**Q9.** Name the three classic Reynolds flock rules.

**A9.** **Separation** (avoid crowding), **alignment** (match average heading of neighbors), **cohesion** (steer toward average position of neighbors).

**Q10.** Why turn separation weight up when agents are packed tightly?

**A10.** Stronger separation prevents overlap and jitter from competing cohesion forces.

**Q11.** What is a neighbor query in 2D games often implemented with?

**A11.** Radius checks against a list, spatial hash, quadtree, or Godot groups/areas—anything that avoids comparing every agent to every agent blindly at huge scale.

---

## Godot lab mechanics (RigidBody3D / drone style)

**Q12.** You want thrust along the drone’s nose. Which mistake uses world-space forward only?

**A12.** Using `Vector3.FORWARD` or `(0,0,1)` without rotating by the body’s basis; correct form uses the body’s forward axis, e.g. **`-global_transform.basis.z`** if forward is negative Z in your model.

**Q13.** `apply_central_force` vs `apply_force` at a point not at the center of mass?

**A13.** Central applies no torque. Off-center force creates **torque** (realistic for motors mounted away from COM).

**Q14.** Why lerp a chase camera in `_physics_process`?

**A14.** The target is a physics body; matching the physics step reduces jitter compared to frame-rate `_process`.

**Q15.** Props “spin up when thrust applied”: what state do you need besides input?

**A15.** A scalar representing thrust intensity or “engines on,” and a separate prop spin velocity that accelerates toward max or decelerates toward zero when thrust drops.

---

## Architecture (SOLID and scripts)

**Q16.** What does the **S** in SOLID mean practically?

**A16.** **Single responsibility:** one class or script should have one main reason to change; split unrelated systems.

**Q17.** What does the **D** in SOLID mean practically?

**A17.** **Dependency inversion:** depend on small interfaces or abstractions so you can swap implementations and test pieces in isolation.

**Q18.** Name two “code smells” that suggest refactoring.

**A18.** Any two of: very long methods, duplicate logic, huge “god” script, unclear naming, mixed UI and AI in one file, deep nesting.

**Q19.** Finite state machine in one line: what is it?

**A19.** A fixed set of states with transitions driven by conditions or events; only one state active at a time (in basic FSMs).

**Q20.** When might a behavior tree beat a giant FSM?

**A20.** When you have hierarchical goals, retries, and parallel concerns (e.g. “fight while retreat if low health”) that become unwieldy as a flat transition web.

---

## Assignment and rubric (aa-26)

**Q21.** Name the three marking categories in the aa-26 assignment rubric.

**A21.** **Groovyness** (visuals and sound), **Complexity** (code, algorithms, system design), **Project management and documentation**.

**Q22.** What does a “1” in Complexity roughly imply about class count and code scale in the rubric text?

**A22.** On the order of **five or six** well-designed interacting classes, several hundred lines of your own code, and techniques like procedural animation, boids, IK, FSM, BT, or LLM integration—plus solid Godot feature use.

**Q23.** Why does the brief mention steering behaviors, FSM, BT, or LLM as possible “brains”?

**A23.** They want a believable autonomous **decision layer**, not only scripted animation; multiple valid architectures satisfy the brief.

---

## Network and flocking (week 11 awareness)

**Q24.** In one sentence, why is multiplayer harder than single-player for synchronized actions?

**A24.** Latency and packet ordering mean different machines see events at different times; you need authority rules and often prediction or reconciliation.

**Q25.** What does “server authority” mean casually?

**A25.** The server’s simulation of critical state wins; clients request actions or send inputs, and the server validates and broadcasts truth.

---

## Mixed quick-fire

**Q26.** `lerp(a, b, t)` with constant `t` each frame: what happens as `t` approaches 1?

**A26.** Convergence becomes instant or unstable; small `t` (or delta-based `1 - exp(-k * delta)`) gives smooth exponential approach.

**Q27.** `CharacterBody2D` vs `RigidBody2D` in one line each.

**A27.** **CharacterBody** uses `move_and_slide` with explicit motion control. **RigidBody** is driven by forces, torques, and the physics engine’s integration.

**Q28.** What is a boid?

**A28.** A simple autonomous agent following local flocking rules; many boids together produce emergent flock motion.

**Q29.** Why might an LLM be a weak real-time game brain?

**A29.** Latency, nondeterminism, cost, and difficulty guaranteeing safe actions every frame without guardrails.

**Q30.** Before a lab test, name three practical Godot editor habits that save time.

**A30.** Any three of: set main scene early, use subscenes for reusable parts, test input map first, commit every twenty minutes, keep camera in separate script, use `print` or remote scene tree to verify node paths.

---

## Optional: explain to a friend (no “answer”)

**Q31.** Explain seek and arrive aloud in under thirty seconds each.

**Q32.** Walk through how you would build the 2025 drone marking scheme in order (props → drone → flight → camera).

**Q33.** Describe how separation steering is computed from neighbor positions.
