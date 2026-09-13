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

/// Set up the audio space. Called once, before any drop lands.
function rain_audio_init() {
	// Clamped exponent falloff: gain is (d / ref) ^ -factor between the
	// reference and maximum distances, and flat outside them. The clamp is what
	// stops a drop landing almost on the listener from blowing out.
	audio_falloff_set_model(audio_falloff_exponent_distance_clamped);

	// The listener is the person on the porch: at the origin, looking out into
	// the scene along +z.
	//
	// The up vector is -y, not +y, and that is not a typo. GameMaker's audio
	// is OpenAL underneath, which is right handed with -z forward — so looking
	// along +z is a half turn, and a half turn swaps left and right. With the
	// default up of +y the listener's right vector comes out as
	//
	//     at x up = (0,0,1) x (0,1,0) = (-1, 0, 0)
	//
	// which puts everything at positive x in the left ear. The whole scene was
	// mirrored: objects on the right of the railing sounded on the left.
	//
	// Flipping up to -y makes that cross product (+1, 0, 0) and puts the stereo
	// field the right way round. It also lands the vertical the right way up
	// for free: with -y as up, world +y is down, and screen y already increases
	// downward — so all three axes are now plain screen and scene coordinates
	// and nothing has to be negated where sounds are played.
	audio_listener_position(0, 0, 0);
	audio_listener_orientation(0, 0, 1, 0, -1, 0);

	global.rain_voice_budget = 0;

	// No bed yet. These used to be set only by rain_bed_start, which was called
	// straight from obj_rain's Create and so always ran. The audio gate makes
	// it return early, so the first rain_bed_update after the player clicks
	// through would have read an undefined global and thrown.
	global.rain_bed         = -1;
	global.rain_bed_playing = -1;
}

/// Pick the drops you hear, now that nothing is simulating drops.
///
/// The visible field is a particle system and particles cannot report back —
/// there is no moment in GML where one of them lands. That turns out not to
/// matter, because the plinks never came from the field in the first place.
/// Thousands of drops arrived every second and the budget below let through
/// about fourteen; the simulation was a very expensive random number generator.
///
/// So this asks for the landings directly. A candidate is a column and a depth
/// drawn from the same distributions a drop was given at birth, put through
/// landing_at to find what it would have struck, and handed to the same test
/// that always decided whether a landing was audible. Same distribution of
/// heard drops, at a dozen calls a second instead of a few thousand a frame —
/// and it still gets the instruments right, because landing_at reads the live
/// surface registry that the sequencer rebuilds when the board changes.
function rain_audio_sample() {
	// Only ever as many candidates as there is budget to spend. Each one that
	// fails the weighting below is a drop that landed somewhere you did not
	// happen to pick out, which is what the budget is describing.
	var _tries = ceil(global.rain_voice_budget);

	for (var _i = 0; _i < _tries; _i++) {
		if (global.rain_voice_budget < 1) return;

		// The same biased depth sample rain_new_drop used, so near drops are as
		// rare here as they were in the field.
		var _t = power(random(1), global.rain_depth_bias);
		var _z = lerp(global.persp_z_near, global.persp_z_far, _t);
		var _x = random_range(-140, room_width + 140);

		var _land = landing_at(_x, _z);
		rain_audio_hit(_x, _land.y, _z, persp_scale(_z), _land.kind);
	}
}

/// A drop has landed. Decide whether it is one of the ones you hear.
function rain_audio_hit(_x, _y, _z, _scale, _kind) {
	if (audio_gated()) return;

	// TEMP: individual drop hits are off while the bed is judged on its own.
	// Returning before the budget is spent rather than after, so the voice
	// budget is not quietly draining against nothing while this is disabled.
	// Delete this comment and the return to bring the plinks back.
	return;

	if (global.rain_voice_budget < 1) return;

	// Squaring the apparent size makes the weighting sharply favour near drops.
	// Weighting linearly lets the far majority win on sheer numbers, and the
	// result is a wash of tiny identical ticks instead of distinct plinks.
	if (random(1) > _scale * _scale * global.rain_audio_reach) return;
	global.rain_voice_budget -= 1;

	var _ax = (_x - room_width * 0.5) * global.rain_audio_pan;
	var _ay = (_y - global.persp_horizon) * 0.25;
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
	var _gain = global.rain_audio_gain * mix_rain() * random_range(0.78, 1.0);

	audio_play_sound_at(
		snd_drop, _ax, _ay, _az,
		90, 1400, 1,
		false, 1,
		_gain, undefined, _pitch
	);
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
	// Nothing before the gate. rain_bed stays -1, and obj_rain starts the bed
	// on the first step after the player clicks through.
	if (audio_gated()) return;

	global.rain_bed_playing = global.rain_bed_track;
	global.rain_bed = audio_play_sound(
		rain_bed_sound(global.rain_bed_track), 2, true, global.rain_bed_gain * mix_rain()
	);
}

/// Track the live gain, and swap recordings if the track changed.
function rain_bed_update() {
	if (audio_gated()) return;

	// Not started yet, or stopped. Covers both the first step after the gate
	// lifts and a bed that was never started because the gate was up.
	if (!audio_is_playing(global.rain_bed)) {
		rain_bed_start();
		return;
	}

	if (global.rain_bed_track != global.rain_bed_playing) {
		if (audio_is_playing(global.rain_bed)) audio_stop_sound(global.rain_bed);
		rain_bed_start();
		return;
	}
	if (!audio_is_playing(global.rain_bed)) return;
	audio_sound_gain(global.rain_bed, global.rain_bed_gain * mix_rain(), 0);
}
