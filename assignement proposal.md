## Working Title

**Blockling: Life in a Pixel World**

## Elevator Pitch

**Blockling** is a 2D pixel-art autonomous creature that lives inside a small, Minecraft-inspired world. Starting from “day 0” with nothing, it explores, gathers basic resources, finds food and shelter, and reacts to day–night cycles and environmental dangers. The player can nudge and observe, but the goal is for the Blockling’s behaviour to feel self-directed and alive as it learns to survive and thrive in its world.

## Concept Overview

- **Style & Dimension**: 2D top-down or side-on pixel-art world, kept simple so I can focus on AI and behaviour. Movement uses smooth 2D physics and steering instead of tile-by-tile grid movement.
- **Inspiration**: The early life cycle of a new Minecraft world — spawn, gather wood and food, avoid monsters, build basic shelter — but applied to a single autonomous agent rather than a full survival game.
- **Autonomy Focus**: The Blockling chooses its own goals based on needs (hunger, safety, curiosity, resource goals) and the current state of the environment, rather than being directly controlled by the player.

The intention is to satisfy the assignment brief from `assignment.md` in the `aa-26` repo by creating an artificial lifeform that interacts with its surroundings, has a sense of needs/goals, and appears to evolve its behaviour over time.

## Target Platform & Tools

- **Engine**: Godot 4, 2D project
- **Language**: GDScript
- **Platform**: Desktop (Windows/macOS), developed and tested in the Godot editor with an exported build for the final demo
- **Art**: Simple pixel-art tiles and sprites created by me or adapted from permissive sources, kept minimal but readable

## Core Gameplay / Simulation Loop

1. The Blockling “spawns” into a small procedurally arranged 2D world with basic tiles:
   - Ground, trees, rocks, water/lava or danger tiles, bushes/animals as food sources, simple shelter tiles.
2. Internal **needs and goals** tick over time:
   - Hunger rises, safety concerns increase at night or near hazards, curiosity drives exploration, and a long-term “comfort” goal encourages building or improving shelter.
3. The AI **selects a goal** based on these needs and environment:
   - Gather wood or stone, search for food, retreat to shelter, explore unknown areas, or investigate new/rare tiles.
4. To achieve the current goal, the Blockling:
   - Uses steering/path-following to move through the world while avoiding obstacles and hazards.
   - Interacts with tiles: “chops” trees, harvests bushes, builds or reinforces simple shelter blocks.
5. The **player** can:
   - Control a separate player character in the same world, mining resources and moving through narrow paths and doorways.
   - Place hint markers, toggle danger levels, or drop rare resources to see how the Blockling reacts.
6. The **Blockling’s personality** is clingy and meddling rather than murderous:
   - It will sometimes shove the player slightly away from valuable resources as they try to mine them.
   - It may step between the player and chests or doors, or close doors the player has just opened.
   - It can pick up dropped items and walk off with them until the player “bribes” it with food or attention.
   - If ignored, it escalates its behaviour with more pushing, blocking and louder, cute but irritating sounds.
   - If petted or fed, it calms down and may even help by bringing an item or revealing a useful area.
7. Over multiple in-game days, the Blockling’s environment and behaviour change:
   - The shelter gradually improves, resource caches appear, and the creature behaves differently in response to past experiences (for example, becoming more cautious after taking damage).

The experience for the player is to watch a small, AI-driven lifeform try to survive and build a tiny life for itself in a world that feels familiar from survival-sandbox games.

## AI / Autonomy Design

### Needs & State

- Core continuous needs:
  - **Hunger**: Increases over time; satisfied by finding and consuming food tiles/entities.
  - **Safety**: Decreases near hazards (lava, night-time, enemies). Increases when inside shelter or in well-lit/“safe” areas.
  - **Energy**: Drains when active; restored by resting inside shelter during night.
  - **Curiosity / Exploration**: Encourages moving into unexplored regions when other needs are under control.
  - Optional: a simple **Experience or Caution** variable that increases after negative events (damage, near-death) and biases decisions to be more careful.

- Internal state machine flags:
  - `is_daytime`, `has_shelter`, `has_basic_tools/resources`, `is_in_danger`, etc.

### Decision Making

To keep the system understandable but non-trivial, I plan to use:

- A **utility-based decision layer**:
  - Each possible high-level behaviour (ForageFood, GatherWood, Explore, ReturnToShelter, BuildShelter, FleeDanger) computes a numeric **utility score** from current needs and world state.
  - Example: `ForageFood` gets a high score if Hunger is high and known food locations exist; `ReturnToShelter` scores highly at night or when Safety is low and shelter is nearby.
  - The behaviour with the highest utility becomes the current **goal**.

- A **Finite State Machine (FSM)** for execution:
  - States like `Idle`, `MovingToTarget`, `Harvesting`, `Building`, `Resting`, `Fleeing`.
  - The active high-level behaviour configures targets and transitions; the FSM handles concrete actions and animations.

If there is time later in the semester, I may express the high-level logic as a small **behaviour tree**, but the minimum implementation will be utility + FSM as this is achievable in the timeframe and clearly demonstrates Autonomous Agents concepts.

### Movement & Interaction

- The Blockling uses **steering behaviours** for movement:
  - **Seek/Arrive** to move to resource tiles, shelter or safety spots.
  - **Wander** when exploring new regions without a specific known target.
  - **Obstacle avoidance** or simple separation from walls, water and lava tiles.
- Pathfinding:
  - For more complex maps, I may layer steering on top of a simple grid-based A* path, but the emphasis remains on steering behaviours and continuous-looking motion.
- Interactions:
  - Harvesting: “mining” actions on resource tiles that change the tile and add to an inventory.
  - Building: placing simple wall/roof tiles to form or improve shelter.
  - Consuming food: animating and updating hunger and energy values.

### Perception & Environment

- Perception via:
  - Overlaps and radius checks to detect nearby resources, food, hazards and shelter.
  - A lightweight memory of known resource and shelter locations.
- Environment:
  - A handcrafted or lightly procedurally generated map made of tiles with tags (resource, food, hazard, shelter-capable).
  - Basic day–night cycle that influences Safety and behaviour (more cautious at night).

## Visuals & Audio (Groovyness)

- **Visuals**:
  - Pixel-art tiles for ground, trees, rocks, water/lava and basic shelter blocks.
  - A simple but expressive Blockling sprite with a few animation frames for walking, harvesting, building, resting and shoving the player.
  - Big round eyes, exaggerated squash-and-stretch, and colour/eye changes or small particle effects to communicate mood (e.g. shaking when scared, sparkle when discovering something new, little “angry” puffs when it is nagging the player).
- **Audio**:
  - Short, retro-style sound effects for walking, harvesting, building, eating and taking damage.
  - Cute but slightly irritating vocalisations when it pushes the player, blocks a doorway or steals an item.
  - Ambient loop(s) for day and night.
  - Optional subtle “chime” sounds when needs are met or goals achieved.

## Planned Milestones

### Milestone 1 – Core World & Basic Survival (Week 1–2)

- Set up Godot 4 2D project and Git repository.
- Implement a small tile-based world with trees, ground and a single safe shelter area.
- Implement the Blockling character with:
  - Basic steering-based movement.
  - Hunger and Safety needs.
  - Behaviours: wander, go to food, eat food, go to shelter when in danger.

### Milestone 2 – Resource Cycle & Day–Night Behaviour (Week 3–4)

- Add more resource and hazard types (wood, stone, water/lava or enemy tiles).
- Extend needs to include Energy and Curiosity.
- Implement the utility-based decision layer and FSM, with behaviours:
  - ForageFood, GatherWood, ReturnToShelter, Rest, Explore, FleeDanger.
- Introduce a simple day–night cycle affecting Safety and AI decisions.
- Add basic building behaviour so the Blockling can place simple shelter blocks.

### Milestone 3 – Polish, Evolution & Presentation (Week 5–6)

- Refine art and sound so the world and Blockling feel coherent and alive.
- Add small “evolutionary” touches:
  - Caution/Experience variable that changes decision weights after bad events.
  - Visual cues that the shelter and environment have improved over time.
- Add UI elements or simple overlays to visualise needs and current goal.
- Export a desktop build and record a short YouTube demo video showing several in-game days and the Blockling’s changing behaviour.
- Complete the README and final documentation, reflecting on what was learned about autonomous agents and survival behaviour.

## Complexity, Learning Outcomes & Assessment Fit

- Multiple self-written GDScript scripts for the Blockling, needs system, brain/decision logic, steering controller, world tiles and day–night manager.
- Demonstrates module techniques:
  - Steering behaviours, FSMs, goal/utility-based decision making, simple procedural animation and environment interaction.
- Several hundred lines of code expected, with a focus on clean separation of responsibilities and readability.
- Strong alignment with the Autonomous Agents assignment brief: a named lifeform with its own needs and goals, interacting with a dynamic environment, giving the impression of life and evolution over time.

## Risks & Scope Management

- **Risks**:
  - Over-scoping the world (too many tile types, complex crafting).
  - Spending too long on procedural generation instead of autonomous behaviour.
  - Time constraints from other modules.
- **Mitigation**:
  - Keep the world small and handcrafted at first.
  - Prioritise: needs model → decision system → steering/movement → basic resource loop → presentation.
  - If needed, simplify to a single resource type (food) and focus on survival and shelter rather than full crafting.

