/// Every instrument in one table.
///
/// THIS IS THE PLACE TO CHANGE WHAT AN OBJECT SOUNDS LIKE. Nothing else in the
/// game names a sound asset for an instrument — the sequencer, the drawing and
/// the palette all read this table — so giving the bucket its own recording is
/// a one-line edit here and nothing else has to know.
///
/// Every instrument currently shares snd_drop and is told apart by pitch alone,
/// which is a placeholder. Swapping in a real sample per row changes nothing
/// downstream.
///
/// Pitches are authored in semitones on a minor pentatonic scale (0, 3, 5, 7,
/// 10, 12, 15) rather than as raw playback ratios. Two reasons. A ratio like
/// 1.1892 is unreadable and easy to typo, and more importantly a pentatonic
/// scale has no dissonant interval in it — so whatever the player arranges,
/// and in whatever order the sequencer fires it, the result is consonant. The
/// arrangement cannot sound wrong, which is the whole design.

/// One row of the table.
function instrument(_name, _sound, _semitones, _colour) {
	return {
		name: _name,
		sound: _sound,
		/// Semitones are the authoring unit; the playback rate is derived,
		/// because an equal-tempered step is a ratio and hand-written ratios
		/// invite arithmetic nobody can check by eye.
		pitch: power(2, _semitones / 12),
		gain: 0.85,
		colour: _colour,
	};
}

function instruments_init() {
	global.instruments = [
		instrument("Bucket",  snd_drop,  0, make_colour_rgb(150, 166, 178)),
		instrument("Bowl",    snd_drop,  3, make_colour_rgb(216, 198, 166)),
		instrument("Tin",     snd_drop,  5, make_colour_rgb(178, 188, 180)),
		instrument("Barrel",  snd_drop,  7, make_colour_rgb(150, 104,  62)),
		instrument("Tray",    snd_drop, 10, make_colour_rgb(118, 132, 146)),
		instrument("Pitcher", snd_drop, 12, make_colour_rgb(228, 226, 214)),
		instrument("Bell",    snd_drop, 15, make_colour_rgb(214, 172,  88)),
	];
}

function instrument_count() {
	return array_length(global.instruments);
}

/// Strike an instrument standing at a given column of the railing.
///
/// Positioned through the same audio space the rain uses, so an object on the
/// left of the railing sounds to your left exactly as rain landing there does,
/// and the two sit in one scene rather than in two unrelated mixes. Priority is
/// above the rain's so a full pattern never loses notes to a downpour.
function instrument_play(_index, _screen_x) {
	var _d = global.instruments[_index];
	var _ax = (_screen_x - room_width * 0.5) * global.rain_audio_pan;
	var _ay = (global.persp_horizon - RAIL_Y) * 0.25;
	var _az = RAIL_Z * global.rain_audio_depth;

	audio_play_sound_at(
		_d.sound, _ax, _ay, _az,
		90, 1400, 1,
		false, 6,
		_d.gain, undefined, _d.pitch
	);
}
