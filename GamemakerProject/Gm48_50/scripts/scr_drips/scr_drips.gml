/// Water coming off the edge of the roof.
///
/// The roof has been a lid the rain does nothing with. Everything else in the
/// scene gets wet — the timber darkens, the lake is a wave field, the bank
/// catches drops — but the one surface directly over the player's head simply
/// stopped the weather and never passed any of it on.
///
/// These are the single most near-field thing in the picture. Everything else
/// is out past the railing; this falls between the viewer and the whole view,
/// which is what makes it read as shelter rather than as more rain.
///
/// --- Why this is not the particle system --------------------------------
///
/// The field is particles because it is thousands of identical drops nobody
/// looks at individually. This is fifteen, and you look at each one: a drip
/// does not stream, it gathers at a point until it is heavy enough and then
/// lets go, and the pause before it lets go is most of what makes it a drip.
/// A particle type cannot hold that, because the waiting is per-point state
/// and particles have no per-point anything.
///
/// So it is fifteen structs, each owning one bead. Cheaper than the particle
/// system it replaces, and it can do the thing that matters.

/// How many places along the eave gather water.
#macro DRIP_POINTS 15

/// The fascia line the roof ends at, and the row they vanish behind.
///
/// They are not stopped at the railing so much as lost behind it: the porch is
/// drawn over the top of this, so a drip simply passes out of sight at the
/// rail's front face, which is where a drip off an overhanging eave would
/// actually go.
#macro DRIP_TOP  112
#macro DRIP_LAND 470

function drips_init() {
	global.drips = [];

	for (var _i = 0; _i < DRIP_POINTS; _i++) {
		// Irregular but fixed. A roof drips where its boards happen to sag, not
		// on a pitch — and evenly spaced drips read as a machine. Taken from a
		// hash rather than random() so the same roof drips in the same places
		// every launch.
		var _t = (_i + 0.5) / DRIP_POINTS;
		var _x = lerp(40, room_width - 40, _t) + (rock_hash(_i * 7 + 3) - 0.5) * 70;

		array_push(global.drips, {
			x:    _x,
			y:    DRIP_TOP,
			vy:   0,
			fall: false,

			// Staggered at birth, so the first second is not fifteen drops
			// released in unison.
			wait: rock_hash(_i * 13 + 5) * 3.2,
			bead: 0,
		});
	}
}

function drips_step() {
	var _dt = min(0.05, delta_time / 1000000);

	// Leaning on the one gust, like everything else. A drip that fell straight
	// down while the rain behind it came in at an angle would be the thing
	// that gave away that the wind is a single number.
	var _wind = gmlmcp_tunable("rain_wind", -4) * (0.35 + 0.9 * wind_strength());

	var _list = global.drips;

	for (var _i = 0; _i < array_length(_list); _i++) {
		var _d = _list[_i];

		if (!_d.fall) {
			// Gathering. The bead swells over the last of the wait, so the
			// release is anticipated rather than sudden — it is the only part
			// of this that tells you which point is about to go.
			_d.wait -= _dt;
			_d.bead = clamp(1 - _d.wait / 0.9, 0, 1);

			if (_d.wait <= 0) {
				_d.fall = true;
				_d.y    = DRIP_TOP;
				_d.vy   = 40;
			}
			continue;
		}

		// Falling, under gravity rather than at a speed. A drip off a roof is
		// slow for the first few pixels and quick by the time it passes you,
		// and that acceleration is most of the weight it appears to have.
		_d.vy += 900 * _dt;
		_d.y  += _d.vy * _dt;
		_d.x  += _wind * 0.8 * _dt;

		if (_d.y > DRIP_LAND) {
			_d.fall = false;
			_d.bead = 0;
			_d.y    = DRIP_TOP;

			// A fresh wait, so the roof never settles into a rhythm. Fifteen
			// points on fixed intervals would beat against the sequencer, and
			// this scene has quite enough things keeping time already.
			_d.wait = 0.5 + random(1.9) * max(0.25, gmlmcp_tunable("drip_gap", 1.0));
		}
	}
}

function drips_draw() {
	// Four pixels, like the near rain, not two. These fall nearer than the
	// near plane — nearer than anything the field contains — so drawing them
	// thinner than the drops behind them was backwards, and it was why they
	// read as rain rather than as something coming off the roof above you.
	var _px  = 4;

	// Whiter than the rain, for the same reason — but at the same level, not
	// above it. This claimed to be under the god ray threshold and was not: at
	// 0.95 luminance a bead running off the roof was the brightest thing in the
	// frame, and a column of them four pixels wide read as a beam pointing the
	// wrong way. What separates them from the rain is the width, which is what
	// this was reaching for anyway; the extra brightness was never doing the
	// work the comment gave it credit for.
	var _col = ray_safe(merge_colour(global.pal.rain, c_white, 0.35));

	draw_set_colour(_col);

	var _list = global.drips;

	for (var _i = 0; _i < array_length(_list); _i++) {
		var _d = _list[_i];
		var _x = floor(_d.x / _px) * _px;

		if (!_d.fall) {
			// The bead, hanging under the fascia and growing.
			if (_d.bead <= 0.15) continue;

			var _r = max(_px, round(_d.bead * 2) * _px);
			draw_set_alpha(0.45 + 0.5 * _d.bead);
			draw_rectangle(_x - _r * 0.5, DRIP_TOP, _x + _r * 0.5, DRIP_TOP + _r, false);
			continue;
		}

		// Falling: stretched by its own speed, so it starts as a bead and is a
		// streak by the time it passes the rail. Same trick the rain uses, but
		// here the speed is changing, so the streak grows as it comes.
		var _len = clamp(_d.vy * 0.035, _px * 2, 30);
		var _y   = floor(_d.y / _px) * _px;

		draw_set_alpha(0.66);
		draw_rectangle(_x - _px * 0.5, _y - _len, _x + _px * 0.5, _y, false);

		// A brighter head, which is where the water actually is — the streak
		// behind it is only where it has been.
		draw_set_alpha(0.95);
		draw_rectangle(_x - _px, _y - _px * 1.5, _x + _px, _y, false);
	}

	draw_set_alpha(1);
}
