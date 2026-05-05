# aa-26 topic checklist (handwritten-style)

Copy to paper or tick in the editor. **⭐** = high exam risk or easy to forget—spend extra time here.

Legend: `[ ]` not reviewed · `[x]` comfortable · **⭐** weak / priority review

## Assessment framing

- [ ] **⭐** In-class test is 20% — know Godot 4 scene workflow cold (main scene, subscenes, input map).
- [ ] Exam 30% — broader theory possible (steering names, when to use FSM vs BT, etc.).
- [ ] Assignment 50% — read rubric in `assignment.md` for “1 vs 2.1” language (Groovyness / Complexity / Documentation).

## Week-by-week (from aa-26 README)

### Week 1 — Intro to Godot; intro to steering for autonomous agents

- [ ] **⭐** Editor basics: scenes, nodes, signals, `_process` vs `_physics_process`.
- [ ] **⭐** First steering behaviors vocabulary (what “autonomous” means in code vs animation-only).

### Week 2 — Seek and Arrive; applications (Deep, Infinite Forms, Avatar)

- [ ] **⭐** Seek: desired velocity toward target, truncate to max speed.
- [ ] **⭐** Arrive: slow inside slowing radius; difference vs seek.
- [ ] Reynolds reading: https://www.red3d.com/cwr/steer/

### Week 3 — Banking; path following; controller input

- [ ] **⭐** Path following (closest point on polyline, look-ahead).
- [ ] Banking / orientation tied to velocity or path tangent.
- [ ] Input actions (`Input.get_axis`, project input map).

### Week 4 — LLMs (NobodyWho)

- [ ] High-level: when an LLM is a brain vs a gimmick; latency and safety (skim only if time-poor).

### Week 5 — SOLID; refactoring; WTPRS

- [ ] **⭐** S.O.L.I.D. one-line meaning each (especially S and D for Godot scripts).
- [ ] **⭐** Refactoring smells: long methods, god scripts, duplicate logic.
- [ ] WTPRS: know acronym expands to a prioritisation / steering-weight idea used in course—verify in your own notes if lecturer defined it explicitly.

### Week 6 — Pursue / offset pursue; Hands (XR)

- [ ] **⭐** Pursue: intercept moving target (predict future position).
- [ ] Offset pursue: maintain relative formation offset.
- [ ] XR “hands” repo as optional stretch awareness.

### Weeks 7–10

- [ ] **⭐** (Empty on public README — fill from lecture notes / labs you actually did.)

### Week 11 — Network sync; flocking

- [ ] **⭐** Read `NETWORK_SYNC.md` in aa-26: RPCs vs MultiplayerSpawner, authority, tick sync mental model.
- [ ] **⭐** Flocking: separation, alignment, cohesion; boids weights.

## Cross-cutting (lab test + assignment)

- [ ] **⭐** Godot 3D: `RigidBody3D` forces/torques vs `CharacterBody3D` move-and-slide.
- [ ] **⭐** `lerp` / `move_toward` for cameras and UI-feel systems.
- [ ] Subscenes: reusable prop arm, creature segments, drone body (matches GE2 test tips).
- [ ] **⭐** Git: commit every ~20 minutes under pressure (2024 README explicitly says so).

## Your project tie-in

- [ ] Walk `scripts/bob_agent.gd`: modes + timers = FSM-style; needs decay; group lookups — be able to explain in one minute each.
