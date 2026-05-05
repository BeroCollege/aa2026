# Bus listen notes — AA and GE2

Read this aloud in your head, or paste into text-to-speech. Short pauses are the blank lines between paragraphs.

---

Autonomous Agents is really about one idea: a character that decides what to do each moment, instead of only playing a fixed animation. That decision loop is what makes something feel alive.

Steering behaviors are a toolkit for movement. You have a position and a velocity. Each frame you ask: where do I want to go, and what nudge gets me there without teleporting? You almost always clamp how fast you can go, and how hard you can turn or accelerate.

Seek is the simple one. Full speed toward a point. It works until you need to stop. Then you use arrive. Arrive is seek with a conscience: when you get close, you shrink your desired speed so you ease in and actually settle instead of orbiting forever.

Pursue is what you use when the target moves. You do not aim at where they are; you aim where they will be soon, even if that prediction is crude. Offset pursue keeps a slot next to a leader, like flying in formation.

Path following is steering glued to a polyline. You find where you are relative to the path, then steer toward a point a little ahead on that path so you do not wiggle on every tiny corner.

Flocking is three words you should know cold: separation, alignment, cohesion. Separation pushes you away from neighbors who are too close. Alignment rotates you toward the average heading of the group. Cohesion gently pulls you toward the center of the neighbors you see. Together they look like birds or fish with no central conductor.

In Godot, if your agent is physics-heavy, think in physics steps. That is why steering and cameras following rigid bodies often live in physics process: same rhythm as the engine, less jitter.

Rigid bodies move from forces and torques. If you push along world forward but your drone rotated, you will slide sideways wrong. You want force along the nose, which means using the body’s basis vectors, not the global Z axis by habit.

Central force goes through the center of mass and does not spin you. A force at a motor mount can spin you. That is useful for drones and anything with offset thrusters.

For a chase camera, do not snap every frame. Lerp toward a point behind the craft, then look at the craft. Behind means opposite the forward direction of the vehicle in world space.

Finite states are your friend when behavior has modes: idle, chase, flee, eat. One mode at a time, clear transitions. Behavior trees help when you want priorities and sequences without drawing spaghetti between twenty states.

Solid is not religion; it is hygiene. One script should not secretly do everything. Small pieces that talk through clear interfaces are easier to debug under exam stress and easier to extend for the assignment.

The assignment rubric cares about three big buckets. Does it look and sound convincing? Is the code and algorithm work real and yours? Did you manage the project like an adult: commits, readme, reflection, video from a build?

For the lab test, treat the README like a contract. Read the marking table and budget time: props first if that is twenty marks, then assembly, then movement, then camera, then polish. Commit on a timer so you never lose everything to one crash.

If you hear “boids,” think local rules and global pattern. If you hear “Reynolds,” think the same lineage: simple steering, big emergent results.

Multiplayer is harder than it looks because light is fast but networks are slow. Someone has to own the truth, usually the server, and everyone else approximates until the next update.

You already built things with modes and needs. That is the same DNA as game AI: numbers go down, priorities shift, the agent picks a new action. Trust that intuition on the exam.

Breathe. Name three behaviors before you walk into the room. Seek, arrive, pursue. Or separation, alignment, cohesion. You only need to sound like you understand the shape of the systems, not recite history.

Good luck today.
