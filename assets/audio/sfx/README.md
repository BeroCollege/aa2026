# Gameplay SFX

Short WAV files in this folder are **procedural placeholders** generated for this project (simple tones and noise bursts). They are wired through `scripts/game_sfx.gd` on the **SFX** audio bus.

| File | Used for |
|------|----------|
| `mine_hit.wav` | Player mines a tile |
| `place_block.wav` | Player places a block |
| `craft_open.wav` | Craft menu opens |
| `ui_click.wav` | Start screen buttons |
| `bob_bite.wav` | B.O.B. bite damage tick |
| `bob_mode_angry.wav` | B.O.B. switches to ATTACK |

Replace with Kenney UI/impact packs or your own recordings if you prefer; keep the same filenames or update `game_sfx.gd` preloads.
