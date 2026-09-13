# Dev notes

Working notes for the two of us. The README is the public description.

## Working together

GameMaker's `.yy` and `.yyp` files merge badly. One agreement keeps the jam
clean:

> **Only one person creates, renames, or deletes resources at a time.** Adding a
> room, object, sprite or sound rewrites `.yyp`, and two people doing it at once
> conflicts every time.

Editing code inside scripts that already exist is fine in parallel. Pull before
you open the project, and commit before you hand off.

WARNING: a room `.yy` lists every instance twice, in the layer's `instances`
array and in the top level `instanceCreationOrder`. Delete an instance from only
one and the project stops loading, with an error naming an id that no longer
exists anywhere. Check both lists match before running.

Pushes to this remote fail with HTTP 408 unless git's slow transfer abort is
off:

```
git -c http.version=HTTP/1.1 -c http.postBuffer=524288000 \
    -c http.lowSpeedLimit=0 -c http.lowSpeedTime=999999 push origin main
```

## Perspective

Everything in the scene is placed by one projection in `scr_perspective`, at
depth `z`:

```
ground_y(z) = horizon + ground_k / z
cloud_y(z)  = horizon - cloud_k / z
persp_scale(z) = z_near / z
```

All three invert in closed form, so a screen position can be turned back into a
depth. The rain, the grass, the trees, the dock, the rocks and the duck all read
these. Nothing carries its own idea of how far away it is.

## One answer, shared

Four things are computed once per step and read everywhere:

- `global.pal`, the palette for this instant, blended between 3 phase keys.
- `global.light`, the key light position and strength, from `sky_light()`.
- `global.wind`, one travelling gust.
- `global.seq_bar`, the bar count. The music waits for it, and so do the chimes.

A scene where each system has a private copy of the light is a scene lit from
two directions at once, and nobody can say which one is wrong.

## God rays

`shd_post` finds light sources by two tests, in
`shaders/shd_post/shd_post.fsh`:

1. Below `u_ray_floor` (the horizon), a pixel never emits, at any brightness.
2. Above it, a pixel emits if its luminance is over `u_ray_thresh` (0.83).

The second test alone is not enough. `pal.rain` is 0.93 luminance, brighter than
the sun disc at 0.90, so no threshold can separate rain from sun. The first test
is the real rule: the sky is the part above the horizon, and an occluder cannot
also be a light source.

CAUTION: anything drawn above the horizon must stay under 0.83 luminance or it
smears toward the sun. Use `ray_safe()` to cap a colour, or `UI_INK` for
interface. Below the horizon, brightness is free, which is why the instrument
labels are plain white.

## Audio

Positioned sounds go through `audio_play_sound_at`, placed by screen x and
depth, so the porch pans in stereo on its own.

NOTE: GameMaker silently refuses to position a stereo sound. Every positioned
sample here is mono.

The listener orientation is `audio_listener_orientation(0, 0, 1, 0, -1, 0)`. The
default puts left and right the wrong way round.

Every instrument sample peaks at 0.850. Normalise any new one to match, rather
than correcting it with a gain: `sndDuck` arrived at 0.082 and no gain value
recovers 28 dB.

NOTE: the instruments are `channelFormat: 2` (3D). `sndDuck`, `sndTorch` and
`sndChimes` are `0` (Mono), so their positional maths currently does nothing.
Setting them to 3D turns panning on and also applies distance falloff, which
cuts them to about a third.

## Live tuning

The project runs on a GML MCP bridge. `gmlmcp_tunable(name, default)` registers
a value that can be read and changed at runtime without a rebuild. Grep for it
to find every dial.
