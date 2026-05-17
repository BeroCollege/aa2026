# Gameplay SFX

Short WAV files in this folder are wired through `scripts/game_sfx.gd` on the **SFX** audio bus.

| File | Used for |
|------|----------|
| `pew.wav` | Player punches, hits, mines, or breaks something |
| `nomnom.wav` | Player consumes berries/food or a cooked meal |
| `mine_hit.wav` | Legacy placeholder, no longer used by the current SFX helper |
| `place_block.wav` | Player places a block |
| `craft_open.wav` | Craft menu opens |
| `ui_click.wav` | Start screen buttons |
| `bob_bite.wav` | B.O.B. bite damage tick |
| `bob_mode_angry.wav` | B.O.B. switches to ATTACK |

If these are replaced later, keep the same filenames or update `game_sfx.gd` preloads.
