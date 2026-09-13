/// A short dock, running out from the bank into the lake.
///
/// The first thing in the scene that goes *away* from the viewer rather than
/// standing at one depth, and the projection makes that much easier than it
/// sounds.
///
/// --- Why it is a trapezoid, and why the rows are easy --------------------
///
/// The deck sits a fixed height above the water. The water at depth z is drawn
/// at horizon + ground_k/z, and a height h above it comes off as
/// h * persp_scale(z), so:
///
///     deck_y(z) = horizon + (ground_k - DOCK_H * z_near) / z
///
/// which is the same 1/z curve the ground is, with a smaller constant. So the
/// deck has its own ground plane, one that floats, and it inverts in closed
/// form exactly like everything else here:
///
///     z = DOCK_K / (y - horizon)
///
/// And the half-width at a deck row, being DOCK_W/2 * z_near/z, substitutes
/// down to a term linear in y. Which is the long way of saying the dock is a
/// trapezoid — but deriving it rather than eyeballing one means it sits at the
/// right depth automatically, and stays right if the horizon or ground_k are
/// ever retuned from the live bridge.
///
/// Drawn as rows of snapped bars rather than a polygon, so its edges step the
/// way everything else in this scene does, and so the plank seams can be
/// spaced in *world* distance and bunch up toward the far end on their own.

/// Just left of centre, reaching out far enough to read and no further.
/// Proportion is the whole of whether this reads as a dock.
///
/// The first attempt was 220 wide over a 78 pixel run — wider on screen than
/// it was long — and no amount of detail rescues that. It is not a dock shape,
/// it is a pyramid, and the eye called it one. A dock is long and narrow, so
/// the width comes down and the far end goes further out until the run is
/// comfortably longer than the deck is wide.
///
/// DOCK_Z_NEAR is what decides whether it looks like a dock or like a ramp
/// that stops at the railing. The bank stands at BANK_Z, so a near end beyond
/// that never touches grass at all — it ended in mid-water, and with the
/// railing covering the join the eye read it as ending *at* the railing. Bring
/// it inside BANK_Z and the last stretch runs up onto the bank, seen in slices
/// between the balusters, and the dock finally comes from somewhere.
#macro DOCK_X      289
#macro DOCK_W      188   // deck width at the near plane
#macro DOCK_H       26   // how far the deck stands above the water, near plane
#macro DOCK_Z_NEAR 2.32  // up onto the grass, nearer than BANK_Z
#macro DOCK_Z_FAR  8.50  // the end of it

/// Where the lengthwise board seams sit, as fractions of the half width.
///
/// Lengthwise, not crosswise, and that is the whole difference between this
/// reading as a dock and reading as a staircase.
///
/// Cross planks were the first attempt and they were wrong twice over. They
/// draw horizontal lines, the tapering deck already steps horizontally as it
/// narrows on the pixel grid, and the two together are indistinguishable from
/// a flight of steps — the eye had no reason to prefer one reading. Run the
/// boards the other way and their seams converge toward the vanishing point
/// instead, which is a cue nothing else in the frame is making and which no
/// staircase seen head-on would ever produce.
#macro DOCK_SEAMS  4

/// The constant of the deck's own 1/z curve.
function dock_k() {
	return global.persp_ground_k - DOCK_H * global.persp_z_near;
}

/// Screen row of the deck surface at depth z.
function dock_y(_z) {
	return global.persp_horizon + dock_k() / _z;
}

/// Half the deck's width at a given deck row. Linear in y, as derived above.
function dock_half(_y) {
	return DOCK_W * 0.5 * global.persp_z_near * (_y - global.persp_horizon) / max(1, dock_k());
}

function dock_draw() {
	// Two pixels, not the scene's four. Everything else drawn on the four pixel
	// grid is made of axis-aligned edges, where snapping is invisible. The
	// dock's sides are diagonals, and a diagonal quantised to four pixels comes
	// out as a flight of steps four pixels deep — which is exactly what it
	// looked like. Halving the grid halves the step.
	var _px = 2;

	var _yf = dock_y(DOCK_Z_FAR);

	// Down to the *ground* at the near end, not to the deck curve. Out on the
	// water the deck stands DOCK_H above the surface, which is what the
	// pilings hold it up on — but where it has run up onto the bank it is
	// lying on the grass, so the boards carry on down to meet it. Stopping at
	// the deck curve left it hovering a finger's width over the bank.
	var _yn = ground_y(DOCK_Z_NEAR);

	// Drawn the whole way down, with no clip at the railing. The porch is drawn
	// over the top of this and hides most of the last stretch by itself, but
	// what shows through the gaps between the balusters is the dock running up
	// onto the grass — which is the only thing that says it comes from the
	// bank rather than starting at the handrail.
	var _k = dock_k();

	// --- What it casts on the water -------------------------------------
	// Before the dock, so the dock sits down onto it. The water surface is
	// lower on screen than the deck by exactly the height it stands, so the
	// shadow is the same trapezoid shifted down and faded.
	// Each bar reaches down to where the *next* row's shadow starts, rather
	// than being one row tall. The deck and the surface under it are two
	// different 1/z curves, and they diverge as they come nearer — so toward
	// the shore consecutive shadow rows are several pixels apart and a stack of
	// one-pixel bars comes out as a dark grille with the grass showing between
	// the teeth. Filling the gap makes it one shape again.
	// And only while it is over water. A dock standing on pilings throws
	// something onto the surface below it; a dock lying flat on the bank has
	// nothing to throw it onto, and a shadow there reads as the boards
	// hovering above the grass — which is exactly what it looked like.
	draw_set_colour(merge_colour(global.pal.water, c_black, 0.5));
	for (var _y = _yf; _y < _yn; _y += _px) {
		var _z  = _k / max(1, _y - global.persp_horizon);
		if (_z < BANK_Z) break;   // rows only get nearer from here

		var _hw = dock_half(_y);
		var _gy = ground_y(_z);

		var _zn2 = _k / max(1, _y + _px - global.persp_horizon);
		var _gy2 = max(ground_y(_zn2), _gy + _px);

		draw_set_alpha(0.30 * (1 - far_haze(_z, 0.5)));
		draw_rectangle(floor((DOCK_X - _hw * 0.9) / _px) * _px, floor(_gy / _px) * _px,
		               floor((DOCK_X + _hw * 0.9) / _px) * _px, floor(_gy2 / _px) * _px,
		               false);
	}

	// --- The pilings ------------------------------------------------------
	// Drawn before the deck so the deck caps them. Each runs from its own deck
	// row down to its own waterline, both of which the projection already
	// answers — so a near post is tall and a far one is a couple of pixels,
	// with nothing here deciding that.
	draw_set_alpha(1);
	for (var _z = DOCK_Z_NEAR + 0.35; _z < DOCK_Z_FAR; _z += 0.95) {
		// Nothing to stand on once it is ashore, for the same reason there is
		// no shadow there: on the bank the dock is lying down, not held up.
		if (_z < BANK_Z) continue;

		var _dy = dock_y(_z);
		if (_dy > _yn) continue;

		var _hw = dock_half(_dy);
		var _gy = ground_y(_z);
		var _pw = max(_px, round(10 * persp_scale(_z) / _px) * _px);

		draw_set_colour(merge_colour(pal_lit(make_colour_rgb(58, 46, 36)),
			global.pal.water, far_haze(_z, 0.45)));

		dock_post(DOCK_X - _hw, _dy, _gy, _pw, _px);
		dock_post(DOCK_X + _hw, _dy, _gy, _pw, _px);
	}

	// --- The deck ---------------------------------------------------------
	// One bar per screen row, its width taken from the row itself, then the
	// board seams laid on as short marks at fixed fractions of that width. A
	// fraction of a shrinking width is a converging line, so the seams draw
	// the perspective for free and stay exactly on the boards at every row.
	for (var _y = _yf; _y < _yn; _y += _px) {
		var _z  = _k / max(1, _y - global.persp_horizon);
		var _hw = dock_half(_y);
		var _hz = far_haze(_z, 0.45);

		draw_set_colour(merge_colour(pal_lit(make_colour_rgb(122, 96, 66)),
			global.pal.water, _hz));
		draw_rectangle(floor((DOCK_X - _hw) / _px) * _px, _y,
		               floor((DOCK_X + _hw) / _px) * _px, _y + _px, false);

		// The seams between boards.
		draw_set_colour(merge_colour(pal_lit(make_colour_rgb(84, 64, 44)),
			global.pal.water, _hz));

		for (var _b = 1; _b < DOCK_SEAMS; _b++) {
			var _fx = DOCK_X + _hw * (_b * 2.0 / DOCK_SEAMS - 1.0);
			var _sx = floor(_fx / _px) * _px;
			draw_rectangle(_sx, _y, _sx + max(1, _px * 0.5), _y + _px, false);
		}

		// A darker strip down the near edge on each side: the thickness of the
		// deck, turned away from the sky. Without it the dock is a flat shape
		// lying on the water rather than a thing standing above it.
		draw_rectangle(floor((DOCK_X - _hw) / _px) * _px, _y,
		               floor((DOCK_X - _hw) / _px) * _px + _px, _y + _px, false);
		draw_rectangle(floor((DOCK_X + _hw) / _px) * _px - _px, _y,
		               floor((DOCK_X + _hw) / _px) * _px, _y + _px, false);
	}

	// --- Mooring posts at the far corners ---------------------------------
	// Two short posts standing above the deck at the end. They are the one
	// thing in the drawing with real vertical extent, and a pair of verticals
	// at the narrow end is what finally says "this goes away from you" rather
	// than "this goes up".
	var _hwe = dock_half(_yf);
	var _ph  = max(_px * 2, round(30 * persp_scale(DOCK_Z_FAR) / _px) * _px);
	var _pw  = max(_px, round(12 * persp_scale(DOCK_Z_FAR) / _px) * _px);

	draw_set_colour(merge_colour(pal_lit(make_colour_rgb(74, 58, 42)),
		global.pal.water, far_haze(DOCK_Z_FAR, 0.45)));

	dock_post(DOCK_X - _hwe + _pw * 0.5, _yf - _ph, _yf, _pw, _px);
	dock_post(DOCK_X + _hwe - _pw * 0.5, _yf - _ph, _yf, _pw, _px);

	// The end board, catching the sky. Without it the dock stops rather than
	// ends, and the eye reads the taper as the boards getting narrower instead
	// of as distance.
	var _hwf = dock_half(_yf);
	draw_set_colour(merge_colour(pal_lit(make_colour_rgb(150, 122, 88)),
		global.pal.water, far_haze(DOCK_Z_FAR, 0.45)));
	draw_rectangle(floor((DOCK_X - _hwf) / _px) * _px, _yf - _px,
	               floor((DOCK_X + _hwf) / _px) * _px, _yf, false);

	draw_set_alpha(1);
}

/// One piling, from the deck edge down into the water.
function dock_post(_x, _deck_y, _water_y, _w, _px) {
	var _x1 = floor((_x - _w * 0.5) / _px) * _px;
	draw_rectangle(_x1, floor(_deck_y / _px) * _px,
	               _x1 + _w, floor(_water_y / _px) * _px + _px, false);
}
