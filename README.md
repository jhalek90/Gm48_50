# Petrichord

A rain-percussion sandbox. You arrange objects on a porch railing and the storm
plays them.

Made for **[GM48 #50](https://gm48.net)** · Theme: **Zen**

Source: **https://github.com/jhalek90/Gm48_50**

<!-- Drop a screenshot at docs/screenshot.png and uncomment:
![Porch at dusk](docs/screenshot.png)
-->

---

## The idea

You stand on a covered porch above a lake in a rainstorm. The railing in front
of you is a step sequencer. Put a bucket on a step and the playhead strikes it
once a bar, in key, in time with the music.

You cannot make it sound bad. Every pitch comes from the scale the current track
is in, so there is no wrong note to place.

## How it plays

The railing holds **8 steps**, one bar of music at 120 BPM. The playhead crosses
it every 2 seconds.

| Action | Control |
|---|---|
| Choose an instrument | `1` to `8`, or click the picker |
| Place it | Left click a step |
| Tune it up one scale degree | Left click it again |
| Remove it | Right click |
| Clear the board | `Backspace` |
| Deal a random board | Click **Roll** |
| Hide the interface | `T` |
| Hold the day still | `P` |

Clicking a placed object raises it one degree and wraps at the top of the scale.
You cannot ask for the instrument already standing there, so the only thing a
repeat click can mean is "that again, higher".

Each placed object stores 6 notes, one per phase of the day per half. When the
music changes key, the object already knows what to play, so a pattern you built
survives the handover instead of going sour.

The 8 instruments are a bucket, a bowl, a tin, a barrel, a tray, a pitcher, a
bell and a bottle.

## The day

The scene runs a 3 phase cycle: Morning, Afternoon, Night. Each phase is one
rhythm track, 32 seconds, so a full day takes **96 seconds**.

Morning and afternoon are in D major. Night is in A major. That is one note of
difference, G against G#, and it is the whole harmonic distance between noon and
midnight.

## Things that are not the board

| Thing | What it does |
|---|---|
| The sky | Drag it to scrub time. The sun follows your pointer. |
| Wind chime | Sweep the pointer through the tubes. They hold 5 notes of the chord the current bar is on. |
| Duck | Click it. It answers in the same scale as the instruments. |
| Lantern | Click it to switch. It lights itself at 18:00 and goes out at 05:00. |

## How it was made

Built in **GameMaker** over the 48 hours of GM48 #50.

**All art, audio and code was made during the jam**, with one exception, named
below.

**Audio.** Every instrument is one recorded sample, pitched by scale degree, so
a single take covers the whole range. The guitar was recorded for the jam, along
with the rest of the instrument samples and the three rhythm tracks. The rain is
a recorded bed with individually positioned drops over it.

**Art.** The scene is drawn in code rather than composed from sprites. The sky,
the water, the grass and the porch timber are each a shader handed a palette
tone, and the whole frame is posterised on one 4 pixel grid so it holds together
as a single picture. Rain and fireflies are particle systems.

**The one exception:** the pine trees are **Pixel Trees 2** by wubs,
https://wubs.itch.io/pixeltrees2

**Under it all** is one projection. Everything in the scene is placed by depth
through the same `1/z` formula, so the rain, the trees, the dock, the rocks and
the duck all agree about how far away they are and how large that makes them.
One palette, one wind and one key light are each worked out once per frame and
read by everything, which is what keeps the scene from looking like several
systems running next to each other.

Development notes are in [DEVNOTES.md](DEVNOTES.md).

## Credits

Justin Halek · Kyle
