/// The lantern hanging from the porch ceiling.
///
/// The one warm thing in the scene, and the only light in it the player owns.
/// Everything else here is lit by a sun crossing the far side of the lake,
/// which means the porch is backlit at every hour of the cycle and the deck
/// never gets anything thrown onto it from the near side. This is the answer
/// to that: a light source on *this* side of the railing, close enough to the
/// viewer to put warmth on the boards and on whatever is standing on them.
///
/// Hung on the right, where the view is closed by the porch post rather than
/// open water, so it frames rather than interrupts. The cord hangs from the
/// fascia line at 112, which is where the roof boards stop and the open view
/// begins — so it reads as fixed to the underside of the roof it is drawn in
/// front of.

/// The chain is anchored above the top of the screen, not at the fascia line.
///
/// A thing hanging from a beam you can see is at the depth of that beam. Run
/// the chain off the top of the frame instead and there is no visible fixing,
/// so the eye puts the hook somewhere in front of the roof — which is where
/// something this size would have to be. The size and the missing anchor argue
/// for the same thing, and neither works alone: a big lantern on a short chain
/// under the fascia just reads as an oversized lantern.
#macro LANTERN_X     1204
#macro LANTERN_TOP   -28   // above the frame, so the chain has no visible end
#macro LANTERN_DROP  214   // chain length down to the top of the glass
#macro LANTERN_W      48
#macro LANTERN_H      84

/// Height of one chain link.
#macro LANTERN_LINK   12

/// The block the lantern is drawn on, matching the scene's posterise grid.
#macro LANTERN_BLOCK   4

/// How far away it sounds. Near, like the chime: the chain runs off the top of
/// the frame rather than ending at a beam you can see, which puts the hook out
/// in front of the roof and the lamp within arm's reach.
#macro LANTERN_Z 1.4

/// When it lights itself, and when it puts itself out.
#macro LANTERN_ON_HOUR   18
#macro LANTERN_OFF_HOUR   5

function lantern_init() {
	global.lantern_on = false;

	// Eased rather than switched. A lantern that snaps to full brightness reads
	// as a UI toggle; one that comes up over a third of a second reads as a
	// flame catching, and it costs one lerp a frame.
	global.lantern_lit = 0;

	global.lantern_t = 0;

	// The swing. The integrator lives in scr_wind, beside the gust that drives
	// it, because the porch has more than one thing hanging off it now.
	global.lantern_pend = pendulum_new();

	// The hour last seen, for the crossing test below. Undefined rather than a
	// number, because obj_lantern's Create may run before obj_daylight's and
	// there may be no clock to read yet — the first step settles it.
	global.lantern_hour = undefined;
}

/// Should a lantern be lit at this hour?
function lantern_wants_on(_h) {
	return (_h >= LANTERN_ON_HOUR || _h < LANTERN_OFF_HOUR);
}

/// Light it at dusk and put it out at dawn, without taking it off the player.
///
/// The obvious version of this — set the state from the hour every step — is
/// wrong, and quietly so: it would hold the switch down. A player who turned
/// the lantern off at 9pm would see it come straight back on the next frame
/// and conclude the thing was broken.
///
/// So this is edge triggered. It acts only in the frame the clock *crosses*
/// one of the two hours, and between crossings the lantern is entirely the
/// player's. Turn it off at 9pm and it stays off until 5am puts it out again
/// — which it already is — and 6pm the next evening lights it.
///
/// The exception is a scrub. The day scrubber can move the clock hours in one
/// frame, and stepping over a crossing in a single jump would either miss it
/// or, going backwards, trigger both. Any jump bigger than an hour is treated
/// as a scrub and the lantern is simply snapped to suit the hour it landed on.
function lantern_auto() {
	var _h = sky_hour();

	// First frame, or straight after a scrub: settle rather than edge trigger.
	if (is_undefined(global.lantern_hour)) {
		global.lantern_hour = _h;
		global.lantern_on   = lantern_wants_on(_h);
		global.lantern_lit  = global.lantern_on ? 1 : 0;
		return;
	}

	var _prev = global.lantern_hour;
	global.lantern_hour = _h;

	// How far the clock moved, forward, around a 24 hour circle.
	var _moved = (_h - _prev + 24) mod 24;

	if (_moved > 1) {
		global.lantern_on = lantern_wants_on(_h);
		return;
	}

	if (hour_crossed(_prev, _moved, LANTERN_ON_HOUR))  global.lantern_on = true;
	if (hour_crossed(_prev, _moved, LANTERN_OFF_HOUR)) global.lantern_on = false;
}

/// Did a step of `_moved` hours starting at `_prev` pass `_mark`?
///
/// Distances are measured forward around the circle so midnight is not a
/// special case: the step from 23:50 to 00:10 is twenty minutes like any
/// other, and a mark at 05:00 is simply not within it.
function hour_crossed(_prev, _moved, _mark) {
	var _to_mark = (_mark - _prev + 24) mod 24;
	return (_to_mark > 0 && _to_mark <= _moved);
}

/// Screen y of the top of the glass.
function lantern_body_y() {
	return LANTERN_TOP + LANTERN_DROP;
}

/// Is this screen position on the lantern?
///
/// The whole fitting, not the cord: nobody reaches for a piece of string. Grown
/// a little in both directions, because this is a thing you click once in a
/// while and not a target worth being precise about.
function lantern_at(_mx, _my) {
	// Carried by the swing, or the target sits still while the thing you are
	// aiming at drifts twenty pixels away from it.
	var _top = lantern_body_y();
	var _cx  = LANTERN_X + lantern_sway_at(_top + LANTERN_H * 0.4);

	return (_mx >= _cx - LANTERN_W * 0.5 - 8 &&
	        _mx <= _cx + LANTERN_W * 0.5 + 8 &&
	        _my >= _top - 28 && _my <= _top + LANTERN_H);
}

/// Switch it, and let it be heard.
///
/// The sound lives here and not beside the two lines in lantern_auto that do
/// the same thing at dusk and dawn, and that is deliberate. This function is
/// the player reaching up and working the lamp; those are the clock arriving at
/// six. A lantern that lit itself with a strike would be odd on its own, and
/// under a scrub it would be worse than odd — dragging the sky through a week
/// would fire one for every crossing.
///
/// Positioned like everything else that makes a noise out here, so it comes
/// from the right-hand side where the lamp actually hangs. Unpitched, unlike
/// the duck and the chime: this is a mechanism, not a voice, and putting it in
/// the scale would make the porch light sound like an instrument.
function lantern_toggle() {
	global.lantern_on = !global.lantern_on;

	var _y = lantern_body_y() + LANTERN_H * 0.4;
	var _x = LANTERN_X + lantern_sway_at(_y);

	audio_play_sound_at(
		sndTorch,
		(_x - room_width * 0.5) * global.rain_audio_pan,
		(_y - global.persp_horizon) * 0.25,
		LANTERN_Z * global.rain_audio_depth,
		90, 1400, 1,
		false, 6,
		gmlmcp_tunable("lantern_gain", 0.9) * mix_sfx()
	);
}

function lantern_step() {
	global.lantern_t += delta_time / 1000000;

	lantern_auto();

	// Framerate-independent approach to the target, so the flame catches at the
	// same rate whatever the frame is doing — the same reason every other clock
	// in this scene is on delta_time rather than on steps.
	var _target = global.lantern_on ? 1 : 0;
	var _rate   = 1 - power(0.02, (delta_time / 1000000) / max(0.05, gmlmcp_tunable("lantern_fade", 0.35)));

	global.lantern_lit += (_target - global.lantern_lit) * _rate;
	if (abs(_target - global.lantern_lit) < 0.002) global.lantern_lit = _target;

	lantern_sway_step();
}

/// Swing it, on the same wind as everything else.
///
/// It reads global.wind through pendulum_step — the one gust in the scene, the
/// same number that slants the rain and bends the grass and sways the trees. A
/// lantern swinging on a wind of its own would be the thing that gives away
/// that none of them are real.
///
/// Stiffness is g over the length of the chain, so 6.3 is about a two and a
/// half second swing — what something this size on a chain this long would do.
function lantern_sway_step() {
	pendulum_step(global.lantern_pend,
		gmlmcp_tunable("lantern_sway",  3.5),
		gmlmcp_tunable("lantern_stiff", 6.3),
		gmlmcp_tunable("lantern_damp",  0.9));
}

/// How far a row at screen y is carried sideways by the swing.
///
/// The whole fitting turns about the hook, which is off the top of the screen,
/// so displacement grows with distance from it: the chain barely moves where
/// it leaves the frame and the lantern at the bottom travels furthest. That is
/// also what leans the body — each bar is offset by the swing at its own
/// middle, so the fitting tilts in whole blocks rather than staying rigid.
/// Stepped, not smooth, which is the same rotation the rest of this scene's
/// four-pixel grid would give anything else.
function lantern_sway_at(_y) {
	return pendulum_offset(global.lantern_pend, _y - LANTERN_TOP);
}

/// One bar of the fitting, carried by the swing at its own height.
function lantern_bar(_cx, _y1, _y2, _half) {
	var _o = lantern_sway_at((_y1 + _y2) * 0.5);
	draw_rectangle(_cx - _half + _o, _y1, _cx + _half + _o, _y2, false);
}

/// How hard the flame is burning this instant, around 1.
///
/// Three sines at unrelated rates rather than random(): a flame wanders, it
/// does not jitter, and a value picked fresh every frame reads as television
/// static. The rates are deliberately not multiples of each other so the
/// pattern does not audibly — visibly — loop.
function lantern_flicker() {
	var _t = global.lantern_t;
	var _f = 1
		+ 0.055 * sin(_t * 5.30)
		+ 0.035 * sin(_t * 9.17 + 1.7)
		+ 0.022 * sin(_t * 14.9 + 0.6);

	// And the guttering, on the same air that swings it.
	//
	// A lamp that leans over in a gust and goes on burning perfectly evenly
	// through it is the thing that gives away that the swing is animation. The
	// glass shelters the flame — that is what the glass is for — so this is
	// small, but it has to be there, and it has to arrive when the lantern is
	// already moving rather than on a clock of its own.
	//
	// Subtracted, never added. Wind robs a flame of its shape; it does not
	// make it burn brighter, and a symmetric wobble here would read as the
	// flame pulsing rather than being pushed about. So the term runs from zero
	// down, and the flame recovers up to its own level between eddies.
	var _gut = gmlmcp_tunable("lantern_gutter", 0.20);
	_f -= abs(global.wind_air) * _gut * (0.5 + 0.5 * sin(_t * 23.4 + 2.4));

	return _f;
}

/// The light it throws, drawn additively over the scene.
///
/// Three passes at increasing size and decreasing strength. One circle at one
/// size reads as a sticker; stacking them gives a bright core that falls away
/// into a wide, weak wash, which is what a flame in a glass actually does.
///
/// Every colour here is kept under the god ray threshold in shd_post — 0.83
/// luminance — because rays march toward the *sun*, so a lantern bright enough
/// to emit would smear a streak of itself across the sky in whatever direction
/// the sun happened to be. The warmth has to come from hue, not from level.
function lantern_draw_glow() {
	var _lit = global.lantern_lit;
	if (_lit <= 0.01) return;

	var _f  = lantern_flicker();
	var _cy = lantern_body_y() + LANTERN_H * 0.36;

	// The light swings with the flame that makes it, including the pools it
	// throws further down. Those are on the deck and the rail, which are not
	// part of the pendulum — but a lamp that moves and a pool of light that
	// does not is the sort of thing you notice without knowing why.
	var _cx = LANTERN_X + lantern_sway_at(_cy);

	var _gain = _lit * _f * gmlmcp_tunable("lantern_glow", 1.0);

	gpu_set_blendmode(bm_add);

	// The wide wash. Squashed a little, because the roof is directly above and
	// a light under a ceiling spreads sideways and down rather than evenly.
	lantern_glow_pass(_cx, _cy, 4.30, 3.40, make_colour_rgb(150,  64,  16), 0.30 * _gain);
	lantern_glow_pass(_cx, _cy, 2.40, 2.15, make_colour_rgb(210, 104,  30), 0.34 * _gain);
	lantern_glow_pass(_cx, _cy, 1.00, 1.00, make_colour_rgb(238, 170,  80), 0.42 * _gain);

	// The pool it throws on the deck. The boards are the nearest surface to the
	// flame and the only one the player is looking down at, so this is most of
	// what sells the lantern as lighting the porch rather than merely glowing.
	var _deck = gmlmcp_tunable("lantern_deck", 706);
	lantern_glow_pass(_cx, _deck, 3.70, 1.00, make_colour_rgb(176,  86,  26), 0.32 * _gain);

	// And a narrower one on the railing, which sits between the two.
	lantern_glow_pass(_cx, RAIL_Y + 16, 2.60, 0.62, make_colour_rgb(190, 96, 30), 0.28 * _gain);

	gpu_set_blendmode(bm_normal);
}

function lantern_glow_pass(_x, _y, _sx, _sy, _colour, _alpha) {
	draw_sprite_ext(spr_glow, 0, _x, _y, _sx, _sy, 0, _colour, clamp(_alpha, 0, 1));
}

/// The fitting itself, in snapped blocks like everything else on this porch.
function lantern_draw_body() {
	var _b   = LANTERN_BLOCK;
	var _cx  = floor(LANTERN_X / _b) * _b;
	var _top = floor(lantern_body_y() / _b) * _b;
	var _lit = global.lantern_lit;
	var _f   = lantern_flicker();

	// Unlit metal takes the ambient light like the trees do, so the lantern
	// belongs to the hour even when it is doing nothing. Lit, it warms toward
	// the flame it is holding — the metal nearest a flame is the first thing
	// that tells you the flame is there.
	var _dark = merge_colour(
		merge_colour(make_colour_rgb(52, 44, 40), global.pal.light, 0.35),
		make_colour_rgb(132, 74, 34), _lit * 0.55);

	var _mid = merge_colour(
		merge_colour(make_colour_rgb(78, 68, 60), global.pal.light, 0.35),
		make_colour_rgb(170, 104, 48), _lit * 0.60);

	draw_set_alpha(1);

	// The chain, running off the top of the frame. Links alternate narrow and
	// wide, which at this block size is as much of a link as you can draw —
	// and enough, because a chain reads by its rhythm rather than by its
	// shape. A plain bar would have been a cord, and a cord does not hold
	// something this heavy.
	//
	// Each link is carried by the swing at its own height, so the chain bends
	// away from the hook rather than sliding sideways in one piece.
	draw_set_colour(_dark);

	var _ring = _top - _b * 6;
	for (var _y = LANTERN_TOP; _y < _ring; _y += LANTERN_LINK) {
		var _h = min(LANTERN_LINK, _ring - _y);
		if (((_y - LANTERN_TOP) div LANTERN_LINK) mod 2 == 0) {
			lantern_bar(_cx, _y, _y + _h - 1, _b);
		} else {
			lantern_bar(_cx, _y + 1, _y + _h - 2, _b * 2);
		}
	}

	// The ring it hangs by, and the cap widening down to the glass.
	lantern_bar(_cx, _ring, _top - _b * 5, _b * 2);

	draw_set_colour(_mid);
	lantern_bar(_cx, _top - _b * 4, _top - _b * 2, _b * 3);
	draw_set_colour(_dark);
	lantern_bar(_cx, _top - _b * 2, _top, _b * 6);

	// The glass. Dull and cold when out, and when lit it is the flame's colour
	// rather than white: the brightest thing here still sits under the god ray
	// threshold, so what makes it read as burning is the hue and the pool of
	// light around it, not the level.
	var _gtop = _top;
	var _gbot = _top + _b * 15;

	// Weighted hard toward the ambient rather than toward its own tone, so an
	// unlit lantern is mostly whatever light is falling on it. At an even split
	// the glass came out brighter than the night sky behind it and a dead
	// lantern was the most luminous thing on screen, which is the one thing it
	// must never be.
	var _glass = merge_colour(
		merge_colour(make_colour_rgb(72, 80, 90), global.pal.light, 0.68),
		make_colour_rgb(196, 128, 52), _lit);

	// Drawn in four rows rather than as one bar, so the glass leans with the
	// swing like everything else instead of standing rigid inside a fitting
	// that does not.
	var _rows = 4;
	var _rh   = (_gbot - _gtop) / _rows;
	for (var _r = 0; _r < _rows; _r++) {
		var _y1 = _gtop + _rh * _r;
		var _y2 = _y1 + _rh;

		draw_set_colour(_glass);
		lantern_bar(_cx, _y1, _y2, _b * 5);

		// The uprights at the corners, which is what stops a lantern reading
		// as a jar. Drawn over the glass so they stay dark against the flame.
		var _o = lantern_sway_at((_y1 + _y2) * 0.5);
		draw_set_colour(_dark);
		draw_rectangle(_cx - _b * 5 + _o, _y1, _cx - _b * 4 + _o, _y2, false);
		draw_rectangle(_cx + _b * 4 + _o, _y1, _cx + _b * 5 + _o, _y2, false);
	}

	// The flame. It sits low in the glass and is drawn as two bars: a body,
	// and a brighter core that breathes.
	if (_lit > 0.02) {
		var _fh = (_b * 6) * (0.8 + 0.35 * (_f - 1) * 6);
		var _fy = _gbot - _b * 2;

		draw_set_alpha(_lit);
		draw_set_colour(make_colour_rgb(226, 140, 46));
		lantern_bar(_cx, _fy - _fh, _fy, _b * 2);

		draw_set_colour(make_colour_rgb(252, 198, 116));
		lantern_bar(_cx, _fy - _fh * 0.7, _fy, _b);
		draw_set_alpha(1);
	}

	// Base.
	draw_set_colour(_dark);
	lantern_bar(_cx, _gbot, _gbot + _b * 2, _b * 6);
	draw_set_colour(_mid);
	lantern_bar(_cx, _gbot + _b * 2, _gbot + _b * 3, _b * 3);
}