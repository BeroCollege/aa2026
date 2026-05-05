# Additional files worth uploading to NotebookLM

You already have the two lab explainers. Add **any subset** of the below—more is not always better; pick what matches how tomorrow’s test is described (Godot-only vs theory-heavy).

---

## A. From your own project folder (`study/`)


| File                          | Why add it                                                      |
| ----------------------------- | --------------------------------------------------------------- |
| `NOTEBOOKLM_CONTEXT_BITES.md` | Short module + Godot + git context (this pack’s “bites” file).  |
| `GE2_DRILL_NOTES.md`          | Where students lose time; good for “what should I check first?” |
| `PRACTICE_QUESTIONS.md`       | Extra Q&A if you want flashcard-style drilling.                 |
| `BUS_LISTEN_NOTES.md`         | Spoken recap if NotebookLM generates audio summaries.           |


---

## B. From `csresources-main` (your zip)

Paths are relative to the unzipped folder `csresources-main/`.


| File                | Why add it                                                                                    |
| ------------------- | --------------------------------------------------------------------------------------------- |
| `README.md`         | Official link index to courses and past tests (thin, but shows how Bryan organises material). |
| `godot_ref.md`      | Text Godot cheat sheet—NotebookLM reads `.md` well.                                           |
| `git_ref.md`        | Text Git cheat sheet—if submission workflow is part of stress.                                |
| `unity_to_godot.md` | Only if you still map Unity concepts to Godot during the test.                                |
| `gen_ai.md`         | Tiny; only if your brief might touch LLMs.                                                    |


**Optional (often large):** `godot_ref.pdf`, `git_ref.pdf`—upload only if NotebookLM accepts PDFs well in your account; otherwise prefer the `.md` versions.

**Usually skip for a coding lab:** `gitlab.md` (long tutorial), `git_ref.html`, `godot_ref.html`, big `.png` / `.jpeg` cheat images (redundant with PDF/MD).

---

## C. Download from GitHub as ZIP or save raw `.md` / `.gd`


| Source                    | What to upload                                                                                                                                                                      |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **GE2-Test-Starter-2025** | `README.MD`, `project.godot`, `drone_scene.tscn` — shows **empty starting point** vs filled solution.                                                                               |
| **GE2-Test-2024-Starter** | Root `README.md` + everything under `GE2-Test-Godot/behaviors/*.gd` you are allowed to read (especially `Boid.gd`, `Harmonic.gd`, `NoiseWander.gd`) if the test is creature-shaped. |


Raw links (save as files if you prefer):

- [https://raw.githubusercontent.com/skooter500/GE2-Test-Starter-2025/main/README.MD](https://raw.githubusercontent.com/skooter500/GE2-Test-Starter-2025/main/README.MD)  
- [https://raw.githubusercontent.com/skooter500/GE2-Test-2024-Starter/main/README.md](https://raw.githubusercontent.com/skooter500/GE2-Test-2024-Starter/main/README.md)

---

## D. Autonomous Agents course (`aa-26`) — theory only

Skip `assignment.md` if you do not want assignment noise. For **possible** short theory alongside the lab:


| URL                                                                                                                                                | What it adds                                           |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| [https://raw.githubusercontent.com/skooter500/aa-26/main/README.md](https://raw.githubusercontent.com/skooter500/aa-26/main/README.md)             | Week headings (steering, path follow, flocking, etc.). |
| [https://raw.githubusercontent.com/skooter500/aa-26/main/NETWORK_SYNC.md](https://raw.githubusercontent.com/skooter500/aa-26/main/NETWORK_SYNC.md) | Only if you suspect network questions (long).          |


---

## E. Your Blockling / Godot game repo (optional)


| Example                                   | Why                                                                                                         |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `scripts/bob_agent.gd` (first ~120 lines) | Shows **modes**, timers, needs—good if NotebookLM should connect “lab FSM ideas” to code you already wrote. |


Export a **small slice** as `.md` or `.txt` (paste code into a markdown code block in one file) so file size stays small.

---

## Suggested “lean” NotebookLM bundle for **tomorrow’s lab only**

1. `NOTEBOOKLM_GE2_LAB_TEST_2025.md`
2. `NOTEBOOKLM_GE2_LAB_TEST_2024.md`
3. `NOTEBOOKLM_CONTEXT_BITES.md`
4. `csresources-main/godot_ref.md`
5. `GE2-Test-Starter-2025/README.MD` (exported from ZIP or raw download)

Add `Boid.gd` from 2024 Godot starter only if the brief looks creature-like.