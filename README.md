# Petrichord

*A cozy rain-percussion sandbox. You don't play the music — you build the instrument and let the storm play it.*

**GM48 #50** · Theme: **Zen** · Made in GameMaker

<!-- Drop a screenshot at docs/screenshot.png and uncomment:
![Porch at dusk](docs/screenshot.png)
-->

---

## The idea

You're on a covered porch above a lake, watching a storm roll through. Rain falls past the eaves in steady streams. Scattered across the railing are buckets, bowls, tins, a barrel, a pitcher, a brass bell — junk, until you move it out into the rain.

Every object you place under a drip becomes a voice in a loop. Move it, and you change the pattern. Sit back, and it keeps playing without you.

**The core promise: you cannot make it sound bad.** The player arranges; the rain performs.

## How it plays

| Placement | Controls the |
|---|---|
| **Which drip** it sits under | **Rhythm** — each drip runs its own tempo lane |
| **What the object is** | **Timbre** — tin rings, ceramic knocks, wood thuds, brass sustains |
| **Horizontal position** | **Pitch** — snapped to scale |
| **Depth** (under the roof → out in the rain) | **Volume & density** — the eaves line is the mixer |

Dragging one bucket three feet forward is a volume fade. Sliding it left is a transposition. No sliders, no note grid — the scene *is* the interface.

## The two rules that make it work

1. **Every drip ticks at an integer ratio of one global pulse** (1/1, 1/2, 1/3, 1/4, dotted 3/8). Polyrhythms fall out for free and nothing ever drifts out of time.
2. **All pitches quantize to a pentatonic scale** (leaning toward *hirajoshi* / *in-sen* for the theme). There is no dissonant interval available to the player.

Constrain the space hard enough and every arrangement is listenable. That's the Zen.

## Systems

- **Vessels fill with water.** A jar under a drip slowly detunes downward as it collects, then overflows, tips, and resets. Your arrangement evolves and undoes itself while you watch. Impermanence, wired into the audio engine.
- **The storm breathes.** A slow multi-minute swell from drizzle to downpour. Light rain wakes only the fastest drips; heavy rain activates everything and brings in a low roar bed. Same arrangement, a completely different piece.
- **Wind gusts** push the drip lines sideways for a few seconds — edge objects get struck or fall silent.
- **A cat.** Wanders out, knocks something over, sits on a bowl and mutes it. Gentle chaos, one sprite.
- **Objects arrive over time.** Something washes down the gutter, a wind chime blows in, the cat drags in a tin. Discovery instead of unlocks.
- **The scene listens back.** Sustain a full arrangement and the lantern warms, fireflies come out, steam rises off the mug, the sky shifts. The reward is atmosphere, not points.

No score. No timer. No fail state.

## Controls

| Key | Action |
|---|---|
| `E` | Pick up / place |
| *TBD* | Rotate |
| `R` | Remove |

Bottom-left is the object palette. Bottom-right shows the **current pattern** as a step readout, and the active **instrument** — water to start, with room for others as the weather changes.

## Tech notes

Two things that matter more than anything else in this build:

- **Audio is scheduled with lookahead, not fired from Step events.** Keep one global song clock and each frame queue every hit landing in the next ~100ms. Triggering notes directly off the frame loop produces audible jitter at 60fps.
- **Droplets spawn early so impact lands on the beat.** The visual is authored backward from the scheduled audio time — sprite spawn = hit time minus fall duration. That audio/visual lock is the whole illusion; if it slips, the scene stops feeling alive.

One sample per material is enough. `audio_sound_pitch(inst, power(2, semitones / 12))` covers the full scale from a single recorded hit. Position each object's voice on an audio emitter so the porch pans in stereo on its own.

## Repo layout

```
GamemakerProject/Gm48_50/    GameMaker project (open Gm48_50.yyp)
README.md                    this file
```

## Working together

GameMaker's `.yy` and `.yyp` files merge badly. One working agreement keeps the jam clean:

> **Only one person creates, renames, or deletes resources at a time.** Rooms, objects, sprites, sounds — adding any of these rewrites `.yyp`, and two people doing it at once conflicts every time.

Editing code inside scripts that already exist is fine in parallel. Pull before you open the project, and commit before you hand off.

`*.resource_order` is gitignored (GameMaker's own recommendation) — it's local editor state and conflicts constantly.

## Credits

Justin Halek · Kyle
