/// A wind chime, hung from the roof on the left.
///
/// There to answer the lantern. The lantern hangs on the right and the left
/// side of the roof had nothing on it, so the porch read as decorated rather
/// than lived on — one deliberate object, placed once, and nothing else.
///
/// It is also the only thing on this porch besides the instruments that would
/// make a noise if you touched it, which for a game about listening to rain
/// seems like the right second object. It does not make one yet. If it ever
/// does it should take its notes from music_scale like everything else, or it
/// will be the one voice in the scene not in the same key.
///
/// --- Why it swings differently from the lantern -------------------------
///
/// Both hang in the same wind, but a chime is small and on a short cord and a
/// lantern is heavy on a long chain — so they must not move together. Sharing
/// one angle would have been cheaper and would have read as both being bolted
/// to the same swinging beam. They share the *integrator* instead, from
/// scr_wind, and each gets its own stiffness: the chime's is high, so it
/// answers a gust quickly and fusses where the lantern leans.

/// Hung from above the frame like the lantern, not from the fascia line.
///
/// Same reasoning as the lantern's chain: a thing hanging from a beam you can
/// see is at the depth of that beam, and running the cord off the top of the
/// frame instead leaves the eye to put the hook somewhere in front of the
/// roof — which is where something this size would have to be.
///
/// The cord passes behind the day scrubber's panel on its way up. That is
/// correct and not worth avoiding: the scrubber is a development tool that
/// hides with T, and things pass behind panels.
#macro CHIME_X     190
#macro CHIME_TOP   -28   // above the frame, so the cord has no visible end
#macro CHIME_DROP  198   // cord down to the disc it hangs from

/// The block it is drawn on, and the whole of its size.
///
/// Everything below is a multiple of this, so the chime scales by changing one
/// number — which is how it went from half this size to twice it without a
/// single position being re-picked by hand.
#macro CHIME_BLOCK   4

/// How far away it sounds. Nearer than the railing, because the cord runs off
/// the top of the frame — the hook is somewhere in front of the roof, which is
/// the whole reason it was hung that way.
#macro CHIME_Z 1.4

/// The tubes, as offsets across the disc and lengths down from it.
///
/// Uneven on purpose, and not symmetric. A chime is tuned, so its tubes are
/// deliberately different lengths — and a set that reads left-to-right short
/// to long looks manufactured, where a jumble looks hung by hand.
#macro CHIME_TUBES 5

function chime_init() {
	global.chime_pend = pendulum_new();
	global.chime_t    = 0;

	// Where the pointer was last frame, and which tube it was on. The sweep is
	// detected as a change of tube rather than as presence over one, so a
	// pointer parked in the middle of the set is silent and a pointer dragged
	// through it rings once per tube it passes — which is what your hand does
	// to a chime.
	global.chime_tube_last = -1;
	global.chime_mx        = 0;
	global.chime_my        = 0;
}

function chime_step() {
	global.chime_t += delta_time / 1000000;

	// Stiffness is g over the length of the line, so hanging it from above the
	// frame rather than from the fascia — nearly three times the drop — has to
	// slow it down. It was 22 on the short cord; leaving it there would have
	// been a long pendulum swinging at a short one's rate, which is the exact
	// thing that reads as animation rather than as weight.
	//
	// Still quicker and less damped than the lantern, because it is far
	// lighter. A light thing on a cord keeps moving after a gust has passed,
	// and that is the whole character of a chime.
	//
	// The angle came down as well. The tubes now hang a long way below the
	// pivot, so the same few degrees carry them much further across — 6.5 was
	// right when the lever was eighty pixels and is a lurch at two hundred.
	pendulum_step(global.chime_pend,
		gmlmcp_tunable("chime_sway",   4.0),
		gmlmcp_tunable("chime_stiff",  9.0),
		gmlmcp_tunable("chime_damp",   0.7));

	chime_sweep();
}

/// Ring whatever the pointer just went through.
///
/// Not a click. A chime is the one thing on this porch you play by brushing
/// past it, and asking for a button press would turn the one gesture in the
/// game that is not a button press into another button.
///
/// The trigger is a *change* of tube, so the length of a sweep decides how many
/// notes come out of it: across the top, where every tube is present, you get
/// five; low down you only catch the two long ones, because that is all that
/// hangs that far. A pointer that stops ringing nothing follows from the same
/// rule, without needing a timer to say so.
///
/// Movement is required as well as a new tube. The set swings on its own, so a
/// parked pointer near an edge would otherwise have tubes drift across it and
/// the chime would sit there playing itself at whoever left the mouse there.
function chime_sweep() {
	var _moved = (mouse_x != global.chime_mx || mouse_y != global.chime_my);
	var _dx    = mouse_x - global.chime_mx;

	global.chime_mx = mouse_x;
	global.chime_my = mouse_y;

	var _i = _moved ? chime_tube_at(mouse_x, mouse_y) : global.chime_tube_last;

	if (_i >= 0 && _i != global.chime_tube_last) chime_ring(_i, _dx);

	global.chime_tube_last = _i;
}

/// Which tube a screen point is on, or -1.
///
/// Grabbed wider than the tube is drawn, and for a different reason than the
/// lantern's grow: the tubes stand about eighteen pixels apart and are eight
/// wide, so at their drawn width a fast sweep would skip between them and ring
/// two out of five. Widened to most of the gap, a sweep catches every tube it
/// crosses and the sound follows the hand instead of sampling it.
///
/// Each tube is tested against its own length, not the longest. Carried by the
/// swing, too — the tube you can ring has to be where the tube looks.
function chime_tube_at(_mx, _my) {
	for (var _i = 0; _i < CHIME_TUBES; _i++) {
		var _t = chime_tube(_i);
		if (_my < _t.y1 || _my > _t.y2) continue;

		var _tx = _t.x + chime_sway_at((_t.y1 + _t.y2) * 0.5);
		if (abs(_mx - _tx) <= _t.half * 2.2) return _i;
	}
	return -1;
}

/// Strike one tube.
///
/// The note is rolled through music_roll_notes and read at the current instant,
/// the same way a placed instrument's and the duck's are, so the chime is in
/// the same scale and the same section and changes key at the same handover.
///
/// And it gets pushed. A chime that answers a hand sweeping through it without
/// moving is the thing that gives away that the swing is a decoration — so the
/// pointer's own travel goes into the pendulum, capped, because the mouse can
/// cross the whole set in one frame and a raw delta would throw the tubes over
/// the top of their arc.
function chime_ring(_i, _dx) {
	var _t = chime_tube(_i);
	var _y = (_t.y1 + _t.y2) * 0.5;
	var _x = _t.x + chime_sway_at(_y);

	var _semi = chime_note(_i);

	var _ax = (_x - room_width * 0.5) * global.rain_audio_pan;
	var _ay = (_y - global.persp_horizon) * 0.25;
	var _az = CHIME_Z * global.rain_audio_depth;

	audio_play_sound_at(
		sndChimes, _ax, _ay, _az,
		90, 1400, 1,
		false, 6,
		gmlmcp_tunable("chime_gain", 0.9) * mix_sfx(), undefined,
		power(2, (gmlmcp_tunable("chime_tune", 0) + _semi) / 12)
	);

	// Each tube takes a little of the hand's travel, and the total is capped.
	// One tube's worth is small on purpose: a sweep rings several in a row, all
	// pushing the same way, so anything that felt right as a single shove would
	// put the set over the top of its arc by the fifth. The clamp is the only
	// thing standing between a fast scrub across the tubes and a chime spinning
	// round its own hook.
	var _p = global.chime_pend;
	_p.vel = clamp(_p.vel + clamp(_dx, -40, 40) * gmlmcp_tunable("chime_push", 0.005),
		-1.0, 1.0);

	// The note it just sounded, thrown like everything else here that plays a
	// pitch, so a swept chime reads back in the same colours the board does.
	var _look = music_note_look(_semi);
	notepuff_add(_x, _t.y1 - 16, _look.colour, _look.label);
}

/// One tube, as the rectangle it hangs in before the swing carries it.
///
/// Offsets and lengths are fixed rather than hashed: there are five of them and
/// they were placed by hand, which is what a chime is. Uneven on purpose and
/// not symmetric — a chime is tuned, so its tubes are deliberately different
/// lengths, and a set running short to long left to right looks manufactured
/// where a jumble looks hung by hand.
///
/// Said once, here, because the drawing is no longer the only thing that needs
/// it: you can sweep a pointer through them now, and a tube you can ring has to
/// be the tube you can see. Two copies of this table is two places for them to
/// come apart.
function chime_tube(_i) {
	var _b  = CHIME_BLOCK;
	var _y1 = CHIME_TOP + CHIME_DROP + _b * 2;

	var _off = [-4.5, -2.2,  0.2,  2.6,  4.8];
	var _len = [  52,   80,   62,   92,   68];

	return {
		x:    floor(CHIME_X / _b) * _b + _off[_i] * _b * 2,
		y1:   _y1,
		y2:   _y1 + _len[_i],
		half: _b,
	};
}

/// Where a tube sits in the set by pitch, lowest first.
///
/// Derived from the lengths in chime_tube rather than written down beside
/// them, so the two cannot disagree — and derived at all because the lengths
/// are deliberately jumbled. They were jumbled to stop the set reading as
/// manufactured, and that decision stands; this is what lets the notes be
/// ordered anyway.
///
/// Counting how many tubes are longer than this one gives the rank directly:
/// nothing is longer than the longest, so it comes out 0.
function chime_tube_rank(_i) {
	var _t = chime_tube(_i);
	var _l = _t.y2 - _t.y1;

	var _rank = 0;
	for (var _j = 0; _j < CHIME_TUBES; _j++) {
		var _o = chime_tube(_j);
		if ((_o.y2 - _o.y1) > _l) _rank++;
	}

	return _rank;
}

/// What this tube is tuned to right now, in semitones from D.
///
/// Five notes in a row off the scale, one to a tube, rather than a fresh roll
/// at every strike. A random note per tube meant the set could not be played:
/// every sweep was a different five notes and two sweeps of the same tubes had
/// nothing to do with each other. Handed a run instead, the chime becomes an
/// instrument — sweep it and you get a chord, sweep it twice and you get the
/// same chord, and the tube you brushed last time is the note you remember.
///
/// The run moves with the harmony. music_root_now says what chord the bar is
/// sitting on and the run is centred on it, so whatever you play is the chord
/// the music is already playing rather than merely the key it is in. Clamped
/// to fit the pool, which is seven notes against five tubes: a centre near
/// either end slides the window rather than running off it, and because the
/// window is five of seven the root is always inside whatever it lands on.
///
/// Pitch goes with tube length, which is the physical truth about a chime —
/// the long tube is the low note. Left to right the run therefore comes out
/// shuffled, which is also the truth: sweep a real chime and you do not get a
/// scale. The notes are the chord either way, and they overlap, so a sweep
/// sounds like the chord it is rather than like a run up it.
function chime_note(_i) {
	var _pool = music_scale(day_phase_index(), music_section());
	var _n    = array_length(_pool);
	var _span = min(CHIME_TUBES, _n);

	// Not in the pool means the tables were edited under it. Fall back to the
	// bottom of the scale rather than refusing to sound.
	var _root = max(0, music_degree_of(_pool, music_root_now()));

	var _start = clamp(_root - (_span div 2), 0, _n - _span);

	return _pool[_start + min(chime_tube_rank(_i), _span - 1)];
}

/// How far a row is carried sideways by the swing.
function chime_sway_at(_y) {
	return pendulum_offset(global.chime_pend, _y - CHIME_TOP);
}

/// One bar of the chime, carried by the swing at its own height.
function chime_bar(_cx, _y1, _y2, _half, _colour) {
	var _o = chime_sway_at((_y1 + _y2) * 0.5);

	draw_set_colour(_colour);
	draw_rectangle(_cx - _half + _o, _y1, _cx + _half + _o, _y2, false);
}

function chime_draw() {
	var _b  = CHIME_BLOCK;
	var _cx = floor(CHIME_X / _b) * _b;
	var _dy = CHIME_TOP + CHIME_DROP;   // the disc it all hangs from

	// Metal, lit by the scene key like the porch timber is. Two tones: the
	// tubes catch the sky down one side, which is the only thing that stops
	// five identical bars reading as a comb.
	var _cord = pal_lit(make_colour_rgb( 92,  78,  62));
	var _tube = pal_lit(make_colour_rgb(148, 152, 156));
	var _lit  = pal_lit(make_colour_rgb(196, 200, 204));
	var _wood = pal_lit(make_colour_rgb(118,  92,  64));

	draw_set_alpha(1);

	// The cord down from the fascia, and the disc it carries.
	chime_bar(_cx, CHIME_TOP, _dy - _b, _b * 0.5, _cord);
	// Wide enough to carry the outermost tube. The tubes sit at up to 4.8 of
	// these blocks either side and are a block wide themselves, so anything
	// narrower than eleven leaves the end pair hanging from thin air — which
	// is exactly what doubling the size exposed, because at half this scale
	// the disc happened to reach far enough by accident.
	chime_bar(_cx, _dy - _b, _dy + _b, _b * 11, _wood);

	// Which side the light is on, so the tubes catch it consistently. Same
	// source the porch posts and the jar read, so nothing on this porch is lit
	// from a different direction.
	var _side = (global.light.x < _cx) ? -1 : 1;

	// The tubes, from the one table chime_tube keeps.
	for (var _i = 0; _i < CHIME_TUBES; _i++) {
		var _t  = chime_tube(_i);
		var _tx = _t.x;
		var _y1 = _t.y1;
		var _y2 = _t.y2;

		chime_bar(_tx, _y1, _y2, _b, _tube);

		// The lit edge, one block down whichever side faces the light.
		var _o = chime_sway_at((_y1 + _y2) * 0.5);
		draw_set_colour(_lit);
		draw_rectangle(_tx + _side * _b + _o - (_side > 0 ? _b * 0.5 : 0), _y1,
		               _tx + _side * _b + _o + (_side > 0 ? 0 : _b * 0.5), _y2, false);
	}

	// The clapper, hung through the middle and lower than the shortest tube so
	// it has something to strike.
	var _clap = _dy + _b * 2 + 72;
	chime_bar(_cx, _dy + _b * 2, _clap, _b * 0.5, _cord);
	chime_bar(_cx, _clap, _clap + _b * 2, _b * 3, _wood);

	// And the sail below it, which is the part the wind actually pushes.
	chime_bar(_cx, _clap + _b * 2, _clap + _b * 5, _b * 0.5, _cord);
	chime_bar(_cx, _clap + _b * 5, _clap + _b * 11, _b * 2.5, _wood);
}
