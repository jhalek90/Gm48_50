# Petrichord

A rain-percussion sandbox. You arrange objects on a porch railing and the storm plays them.

**GM48 #50** · Theme: **Zen** · GameMaker

<!-- Drop a screenshot at docs/screenshot.png and uncomment:
![Porch at dusk](docs/screenshot.png)
-->

---

## The idea

You stand on a covered porch above a lake in a rainstorm. The railing in front of you
is a step sequencer. Put a bucket on a step and the playhead strikes it once a bar,
in key, in time with the music.

You cannot make it sound bad. Every pitch comes from the scale the current track is in,
so there is no wrong note to place.

## How it plays

The railing holds **8 steps**, one bar of music at 120 BPM. The playhead crosses it
every 2 seconds.

| Action | Control |
|---|---|
| Choose an instrument | `1` to `8`, or click the picker |
| Place it | Left click a step |
| Tune it up one scale degree | Left click it again |
| Remove it | Right click |
| Clear the board | `Backspace` |
| Deal a random board | Click **Roll** |

Clicking a placed object raises it one degree and wraps at the top of the scale. This is
the Minecraft note block rule. You cannot ask for the instrument already standing there,
so the only thing a repeat click can mean is "that again, higher".

Each placed object stores 6 notes, one per phase of the day per half. When the music
changes key, the object already knows what to play, so a pattern you built survives the
handover instead of going sour.

### The 8 instruments

Bucket, Bowl, Tin, Barrel, Tray, Pitcher, Bell, Bottle.

All 8 are sampled at D and pitched by scale degree, so one recording covers the whole
range: `power(2, semitones / 12)`.

## The day

The scene runs a 3 phase cycle: Morning, Afternoon, Night. Each phase is one rhythm
track, 32 seconds, so a full day takes **96 seconds**.

Morning and afternoon are in D major. Night is in A major. That is one note of
difference, G against G#, and it is the whole harmonic distance between noon and
midnight.

The day is built around the music, not the other way round. `music_init` reads the
track lengths and sets the phase to the median, rounded to a whole number of sequencer
loops. Every phase boundary then falls on a downbeat, so the incoming track never has
to wait for one.

## Things on the porch that are not the board

| Thing | What it does |
|---|---|
| The sky | Drag it to scrub time. The sun follows your pointer. |
| Wind chime | Sweep the pointer through the tubes. They hold 5 notes of the chord the current bar is on. |
| Duck | Click it. It answers in the same scale as the instruments. |
| Lantern | Click it to switch. It lights itself at 18:00 and goes out at 05:00. |

## Controls

| Key | Action |
|---|---|
| `1` to `8` | Choose instrument |
| `Backspace` | Clear the board |
| `T` | Hide the interface |
| `P` | Pause the day/night cycle |
| `Up` / `Down` | Nudge the rain bed level |

Three buttons sit in the top right: pause, volume, fullscreen. The volume panel holds
4 faders (master, music, rain, objects).

## How it is built

### Perspective

Everything in the scene is placed by one projection in `scr_perspective`, at depth `z`:

```
ground_y(z) = horizon + ground_k / z
cloud_y(z)  = horizon - cloud_k / z
persp_scale(z) = z_near / z
```

All three invert in closed form, so a screen position can be turned back into a depth.
The rain, the grass, the trees, the dock, the rocks and the duck all read these. Nothing
carries its own idea of how far away it is.

### One answer, shared

Four things in the scene are computed once per step and read everywhere:

- `global.pal`, the palette for this instant, blended between 3 phase keys.
- `global.light`, the key light position and strength, from `sky_light()`.
- `global.wind`, one travelling gust. The rain slants in it, the grass leans, the trees
  quicken.
- `global.seq_bar`, the bar count. The music waits for it, and so do the chimes.

A scene where each system has a private copy of the light is a scene lit from two
directions at once, and nobody can say which one is wrong.

### God rays

`shd_post` finds light sources by two tests, in `shaders/shd_post/shd_post.fsh`:

1. Below `u_ray_floor` (the horizon), a pixel never emits, at any brightness.
2. Above it, a pixel emits if its luminance is over `u_ray_thresh` (0.83).

The second test alone is not enough. `pal.rain` is 0.93 luminance, brighter than the sun
disc at 0.90, so no threshold can separate rain from sun. The first test is the real
rule: the sky is the part above the horizon, and an occluder cannot also be a light
source.

CAUTION: anything drawn above the horizon must stay under 0.83 luminance or it smears
toward the sun. Use `ray_safe()` to cap a colour, or `UI_INK` for interface. Below the
horizon, brightness is free.

### Audio

Every instrument, the duck, the chime and the lantern play through
`audio_play_sound_at`, positioned by screen x and depth. The porch pans in stereo on its
own.

NOTE: GameMaker silently refuses to position a stereo sound. Every positioned sample in
this project is mono.

The listener orientation is `audio_listener_orientation(0, 0, 1, 0, -1, 0)`. The default
puts left and right the wrong way round.

## Repo layout

```
GamemakerProject/Gm48_50/   GameMaker project (open Gm48_50.yyp)
Music/                      rhythm track sources, newTracks/ is current
chords/                     chord samples, imported but unused
mountains/  trees/          source art
notes_all_d/                instrument samples
README.md                   this file
```

## Working together

GameMaker's `.yy` and `.yyp` files merge badly. One working agreement keeps the jam
clean:

> **Only one person creates, renames, or deletes resources at a time.** Adding a room,
> object, sprite or sound rewrites `.yyp`, and two people doing it at once conflicts
> every time.

Editing code inside scripts that already exist is fine in parallel. Pull before you open
the project, and commit before you hand off.

WARNING: a room `.yy` lists every instance twice, in the layer's `instances` array and
in the top level `instanceCreationOrder`. Delete an instance from only one and the
project stops loading, with an error naming an id that no longer exists anywhere.

Pushes to this remote fail with HTTP 408 unless git's slow transfer abort is off:

```
git -c http.version=HTTP/1.1 -c http.postBuffer=524288000 \
    -c http.lowSpeedLimit=0 -c http.lowSpeedTime=999999 push origin main
```

## Credits

Justin Halek · Kyle
