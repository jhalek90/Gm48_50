/// Every instrument in one table.
///
/// THIS IS THE PLACE TO CHANGE WHAT AN OBJECT SOUNDS LIKE. Nothing else in the
/// game names a sound asset for an instrument — the sequencer, the drawing and
/// the palette all read this table — so giving the bucket its own recording is
/// a one-line edit here and nothing else has to know.
///
/// `gain` balances the samples against each other. Every sample was peak
/// normalised on import, but peak is not loudness: the bell and the glass ring
/// for over two seconds where a hat is gone in a tenth of one, so at equal peak
/// they are much louder in the mix. These gains come from the RMS of each
/// sample's audible part, which is a closer match for what the ear does.
///
/// Pitches are authored in semitones on a minor pentatonic scale (0, 3, 5, 7,
/// 10, 12, 15) rather than as raw playback ratios. Two reasons. A ratio like
/// 1.1892 is unreadable and easy to typo, and more importantly a pentatonic
/// scale has no dissonant interval in it — so whatever the player arranges,
/// and in whatever order the sequencer fires it, the result is consonant. The
/// arrangement cannot sound wrong, which is the whole design.

/// One row of the table.
function instrument(_name, _sound, _semitones, _gain, _colour) {
	return {
		name: _name,
		sound: _sound,
		/// Semitones are the authoring unit; the playback rate is derived,
		/// because an equal-tempered step is a ratio and hand-written ratios
		/// invite arithmetic nobody can check by eye.
		pitch: power(2, _semitones / 12),
		gain: _gain,
		colour: _colour,
	};
}

function instruments_init() {
	global.instruments = [
		instrument("Bucket",  snd_bucket,  0, 0.86, make_colour_rgb(150, 166, 178)),
		instrument("Bowl",    snd_glass,   3, 0.64, make_colour_rgb(216, 198, 166)),
		instrument("Tin",     snd_hat2,    5, 0.94, make_colour_rgb(178, 188, 180)),
		instrument("Barrel",  snd_drop,    7, 0.84, make_colour_rgb(150, 104,  62)),
		instrument("Tray",    snd_hat1,   10, 0.95, make_colour_rgb(118, 132, 146)),
		// A pitcher is a smaller vessel than a bucket, so it borrows the same
		// recording an octave up rather than needing its own.
		instrument("Pitcher", snd_bucket, 12, 0.86, make_colour_rgb(228, 226, 214)),
		instrument("Bell",    snd_bell,   15, 0.66, make_colour_rgb(214, 172,  88)),
	];
}

function instrument_count() {
	return array_length(global.instruments);
}

/// Strike an instrument standing somewhere in the scene.
///
/// Positioned through the same audio space the rain uses, so an object on the
/// left sounds to your left exactly as rain landing there does, and the two sit
/// in one scene rather than in two unrelated mixes. Depth comes from the track,
/// so the back row is genuinely further away rather than merely quieter — the
/// falloff model handles the level, and it arrives nearer the centre because it
/// really is closer to straight ahead. Priority is above the rain's so a full
/// pattern never loses notes to a downpour.
function instrument_play(_index, _screen_x, _screen_y, _z) {
	var _d = global.instruments[_index];
	var _ax = (_screen_x - room_width * 0.5) * global.rain_audio_pan;
	var _ay = (global.persp_horizon - _screen_y) * 0.25;
	var _az = _z * global.rain_audio_depth;

	audio_play_sound_at(
		_d.sound, _ax, _ay, _az,
		90, 1400, 1,
		false, 6,
		_d.gain, undefined, _d.pitch
	);
}
