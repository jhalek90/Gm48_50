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
/// Pitch is NOT authored here any more. Every sample was recorded at D, and the
/// note an object plays is rolled from the scale for the current phase when the
/// player places it — see music_roll_note. An instrument chooses a timbre; the
/// slot it stands in chooses the note. That is what keeps the seven of them
/// usable at any point in the track instead of each being locked to one pitch.
///
/// `register` is what survives of the old per-instrument pitch: a semitone
/// offset added on top of the note. It is zero for everything except where two
/// instruments share one recording and need telling apart.

/// The shape of a vessel, as half-width at a given height.
///
/// Every one of these things is a turned or beaten vessel, which means it is
/// rotationally symmetric — so its whole silhouette is one function of height
/// and nothing else. Pairs of [height, half-width], both as a fraction of the
/// box the object is drawn in, from 0 at the top to 1 at the base. Heights
/// above the first pair are empty, which is how a bowl sits low in its box and
/// a bell hangs high in one.
///
/// Authored this way rather than as placed primitives because a profile is
/// four numbers a person can read and adjust, and because one renderer then
/// draws all seven — so they cannot drift into looking like seven objects from
/// different games.

/// One row of the table.
function instrument(_name, _sound, _register, _gain, _colour, _profile, _rim) {
	return {
		name: _name,
		sound: _sound,
		register: _register,
		profile: _profile,
		/// Whether the top of the profile is an opening. A bucket and a bowl
		/// are lighter across the mouth because you are looking into them; a
		/// bell and a barrel are closed and are not.
		rim: _rim,
		gain: _gain,
		colour: _colour,
	};
}

function instruments_init() {
	global.instruments = [
		// Straight-sided and flared, standing its full height.
		//
		// A plucked guitar note. Gain well under the struck samples it sits
		// beside: it rings for three quarters of a second where a bucket knock
		// is gone in a fifth, and at equal peak the longer note is far the
		// louder thing in the mix.
		instrument("Bucket",  snd_guitar_d, 0, 0.52, make_colour_rgb(150, 166, 178),
			[[0.00, 0.50], [1.00, 0.34]], true),

		// Wide and shallow, sitting low in its box with a rounded foot.
		instrument("Bowl",    snd_glass,   0, 0.64, make_colour_rgb(216, 198, 166),
			[[0.42, 0.50], [0.62, 0.47], [0.88, 0.33], [1.00, 0.16]], true),

		// Near enough a cylinder. The slight taper is what stops it reading as
		// a rectangle, which is what it was before.
		//
		// A piano rather than a hat: the only pitched recording in the set, and
		// the one that shows what the note rolls are doing. Its gain is much
		// lower than the hat it replaced because it rings for most of a second
		// where the hat was gone in a quarter of one — at equal peak that is a
		// far louder thing in the mix.
		instrument("Tin",     snd_piano_d, 0, 0.40, make_colour_rgb(178, 188, 180),
			[[0.00, 0.38], [1.00, 0.35]], true),

		// Bulged at the waist and drawn in at both ends, which is the whole of
		// what makes a barrel a barrel.
		instrument("Barrel",  snd_drop,    0, 0.84, make_colour_rgb(150, 104,  62),
			[[0.00, 0.35], [0.50, 0.48], [1.00, 0.35]], false),

		// Barely off the ground and nearly as wide as its box.
		instrument("Tray",    snd_hat1,    0, 0.95, make_colour_rgb(118, 132, 146),
			[[0.64, 0.50], [1.00, 0.46]], true),

		// The barrel's recording, two octaves down. Sharing one sample and
		// separating it by register is the one place a register offset still
		// earns its keep — and at a quarter speed the drop stops being a drop
		// and becomes the low end of the set, which nothing else was covering.
		//
		// Four times as long as the sample it came from, so it wants a lower
		// gain than the barrel even though resampling leaves the RMS alone: a
		// note that rings for three quarters of a second sits in the mix very
		// differently from one gone in a fifth.
		instrument("Pitcher", snd_drop, -24, 0.62, make_colour_rgb(228, 226, 214),
			[[0.00, 0.17], [0.22, 0.21], [0.52, 0.47], [0.82, 0.44], [1.00, 0.29]], true),

		// Hung from a point and flaring to a skirt. Closed at the top, so no
		// rim: there is nothing to look into.
		instrument("Bell",    snd_bell,    0, 0.66, make_colour_rgb(214, 172,  88),
			[[0.06, 0.09], [0.16, 0.16], [0.42, 0.25], [0.72, 0.37], [0.92, 0.49], [1.00, 0.49]], false),

		// A long narrow neck, a shoulder that flares fast, then straight sides.
		// The neck is what makes it a bottle rather than a jar, and it has to
		// stay narrow enough to read at back-ledge size where the whole object
		// is six blocks tall.
		//
		// Appended rather than slotted in beside the bowl, glass though it is:
		// inserting it would renumber every key after it, and the picker keys
		// are muscle memory by now.
		instrument("Bottle",  snd_triangle_d, 0, 0.50, make_colour_rgb(116, 164, 138),
			[[0.00, 0.10], [0.26, 0.10], [0.31, 0.17], [0.43, 0.31], [0.58, 0.33], [1.00, 0.31]], true),
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
function instrument_play(_index, _screen_x, _screen_y, _z, _note) {
	var _d = global.instruments[_index];
	var _ax = (_screen_x - room_width * 0.5) * global.rain_audio_pan;
	var _ay = (global.persp_horizon - _screen_y) * 0.25;
	var _az = _z * global.rain_audio_depth;

	audio_play_sound_at(
		_d.sound, _ax, _ay, _az,
		90, 1400, 1,
		false, 6,
		// The note this slot rolled, plus whatever register the instrument sits
		// in. Semitones are the authoring unit and the ratio is derived: a
		// hand-written 1.1892 is arithmetic nobody can check by eye.
		_d.gain * mix_sfx(), undefined, power(2, (_d.register + _note) / 12)
	);
}
