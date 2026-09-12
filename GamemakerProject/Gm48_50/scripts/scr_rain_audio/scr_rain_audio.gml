/// Rain audio.
///
/// The field lands several thousand drops a second. One sound per landing is
/// not merely too many voices — it is the wrong sound. Rain heard from a porch
/// is a continuous bed with a handful of individual plinks picked out of it, so
/// landings compete for a small budget of voices per second and the nearest
/// ones usually win.
///
/// Positioning is real 3D rather than a stereo pan. The drop's screen column
/// becomes the audio x, its depth becomes the audio z, and the falloff model
/// does the rest. That gets distance right for free: a far drop is quiet and
/// close to centre because it genuinely is nearly straight ahead, while a near
/// one off to the side is loud and wide. Faking it with a pan computed from
/// screen x alone would put distant rain hard left and right, which is the
/// thing that makes 2D rain sound flat.

/// Seconds of rain available to cut grains from. Set by the length of the
/// excerpt in snd_drop_grain, and used to keep a random offset from running
/// past the end of it.
#macro GRAIN_SPAN 30

/// Set up the audio space. Called once, before any drop lands.
function rain_audio_init() {
	// Clamped exponent falloff: gain is (d / ref) ^ -factor between the
	// reference and maximum distances, and flat outside them. The clamp is what
	// stops a drop landing almost on the listener from blowing out.
	audio_falloff_set_model(audio_falloff_exponent_distance_clamped);

	// The listener is the person on the porch: at the origin, looking out into
	// the scene along +z. The up vector is left at GameMaker's default +y so
	// the handedness stays the one it expects — screen y is flipped where it is
	// passed in instead, which is one negation in one place.
	audio_listener_position(0, 0, 0);
	audio_listener_orientation(0, 0, 1, 0, 1, 0);

	global.rain_voice_budget = 0;
	global.rain_grain_voices = [];
}

/// A drop has landed. Decide whether it is one of the ones you hear.
function rain_audio_hit(_x, _y, _z, _scale, _kind) {
	if (global.rain_voice_budget < 1) return;

	// Squaring the apparent size makes the weighting sharply favour near drops.
	// Weighting linearly lets the far majority win on sheer numbers, and the
	// result is a wash of tiny identical ticks instead of distinct plinks.
	if (random(1) > _scale * _scale * global.rain_audio_reach) return;
	global.rain_voice_budget -= 1;

	var _ax = (_x - room_width * 0.5) * global.rain_audio_pan;
	var _ay = (global.persp_horizon - _y) * 0.25;
	var _az = _z * global.rain_audio_depth;

	// Two things move the pitch. Depth, because a near drop reads as a bigger,
	// duller sound and a distant one as thin and bright; and a random jitter,
	// because the same one-shot at a fixed pitch stops sounding like weather
	// and starts sounding like a machine gun.
	var _pitch = lerp(1.20, 0.86, _scale) * random_range(0.93, 1.08);

	// Wood is a harder, tighter surface than open water.
	if (_kind == "wood") _pitch *= 1.22;

	// Distance is already handled by the falloff model, so this jitter is only
	// here to keep repeated hits from sounding stamped from the same die.
	var _gain = global.rain_audio_gain * random_range(0.78, 1.0);

	if (global.rain_drop_mode == 1) {
		rain_grain_play(_ax, _ay, _az, _gain, _pitch);
	} else {
		audio_play_sound_at(
			snd_drop, _ax, _ay, _az,
			90, 1400, 1,
			false, 1,
			_gain, undefined, _pitch
		);
	}
}

/// Play a short slice cut from anywhere in the rain recording.
///
/// The recording has no isolated drop in it to find, so this does not try to
/// land on one. It takes whatever is at a random offset and relies on the
/// grain being short enough to read as a single event.
///
/// Two things make an arbitrary cut of noise usable. The offset leaves a whole
/// grain ahead of it so playback never runs off the end, and the grain is faded
/// in and out instead of switched on — cutting a waveform at a sample that is
/// not near zero clicks at both ends, and noise is never near zero.
function rain_grain_play(_ax, _ay, _az, _gain, _pitch) {
	var _len  = global.rain_grain_len;
	var _fade = global.rain_grain_fade;
	var _off  = random(GRAIN_SPAN - _len);

	var _v = audio_play_sound_at(
		snd_drop_grain, _ax, _ay, _az,
		90, 1400, 1,
		false, 1,
		0, _off, _pitch
	);
	audio_sound_gain(_v, _gain, _fade * 1000);

	// Stopping is scheduled in wall time, not source time, so a pitched-up
	// grain still lasts as long as every other one.
	array_push(global.rain_grain_voices, {
		v: _v,
		fade_at: current_time + (_len - _fade) * 1000,
		off_at:  current_time + _len * 1000,
		faded: false,
	});
}

/// Retire grains whose slice has run its length.
function rain_grain_update() {
	var _list = global.rain_grain_voices;
	var _fade = global.rain_grain_fade;
	for (var _i = array_length(_list) - 1; _i >= 0; _i--) {
		var _g = _list[_i];
		if (!_g.faded && current_time >= _g.fade_at) {
			audio_sound_gain(_g.v, 0, _fade * 1000);
			_g.faded = true;
		}
		if (current_time >= _g.off_at) {
			if (audio_is_playing(_g.v)) audio_stop_sound(_g.v);
			array_delete(_list, _i, 1);
		}
	}
}

/// Which recording the bed is playing.
///
/// Two beds are shipped so they can be compared by ear while the game runs:
/// 0 is the original loop, 1 is rain on a tin roof, which matches the roof the
/// player is actually sitting under. The tin recording was quieter by about
/// 12 dB and was lifted on import, so one gain setting suits both and swapping
/// between them does not jump in level.
function rain_bed_sound(_track) {
	return (_track == 1) ? snd_rain_tin : snd_rain_loop;
}

/// Start the ambient bed under the individual drops.
///
/// The bed is deliberately not positioned. It is the sound of being inside the
/// weather rather than of any one drop, so it plays flat in stereo while the
/// plinks carry all the spatial information. Giving it a position would pull
/// the whole storm to a point somewhere off the porch.
function rain_bed_start() {
	global.rain_bed_playing = global.rain_bed_track;
	global.rain_bed = audio_play_sound(
		rain_bed_sound(global.rain_bed_track), 2, true, global.rain_bed_gain
	);
}

/// Track the live gain, and swap recordings if the track changed.
function rain_bed_update() {
	if (global.rain_bed_track != global.rain_bed_playing) {
		if (audio_is_playing(global.rain_bed)) audio_stop_sound(global.rain_bed);
		rain_bed_start();
		return;
	}
	if (!audio_is_playing(global.rain_bed)) return;
	audio_sound_gain(global.rain_bed, global.rain_bed_gain, 0);
}
