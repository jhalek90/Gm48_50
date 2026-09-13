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

/// The tubes, as offsets across the disc and lengths down from it.
///
/// Uneven on purpose, and not symmetric. A chime is tuned, so its tubes are
/// deliberately different lengths — and a set that reads left-to-right short
/// to long looks manufactured, where a jumble looks hung by hand.
#macro CHIME_TUBES 5

function chime_init() {
	global.chime_pend = pendulum_new();
	global.chime_t    = 0;
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

	// The tubes. Offsets and lengths are fixed rather than hashed: there are
	// five of them and they were placed by hand, which is what a chime is.
	var _off = [-4.5, -2.2,  0.2,  2.6,  4.8];
	var _len = [   0,    0,     0,    0,    0];
	_len[0] = 52; _len[1] = 80; _len[2] = 62; _len[3] = 92; _len[4] = 68;

	for (var _i = 0; _i < CHIME_TUBES; _i++) {
		var _tx = _cx + _off[_i] * _b * 2;
		var _y1 = _dy + _b * 2;
		var _y2 = _y1 + _len[_i];

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
