/// Drawing the instruments.
///
/// One renderer for all seven. Each is a vessel, and a vessel is rotationally
/// symmetric, so its silhouette is entirely described by the half-width at each
/// height — the profile in scr_instruments. Drawing them from that rather than
/// from placed primitives means seven objects that unmistakably belong to the
/// same set, and it means a new one is four numbers rather than a new function.
///
/// Built from bars snapped to the pixel grid, like the shadows and the grass,
/// so the objects the player places sit on the same grid as the scene they are
/// placed in. A smoothly drawn ellipse here would be the only antialiased
/// thing on screen.

/// Half-width of a profile at height _t, or -1 above where the vessel starts.
function prop_profile_at(_prof, _t) {
	var _n = array_length(_prof);

	// Above the first point the vessel has not begun. That is what lets a bowl
	// sit in the bottom half of its box and a tray in the bottom quarter,
	// without either needing its own idea of where the ground is.
	if (_t < _prof[0][0]) return -1;

	for (var _i = 1; _i < _n; _i++) {
		if (_t <= _prof[_i][0]) {
			var _a = _prof[_i - 1];
			var _b = _prof[_i];
			return lerp(_a[1], _b[1], (_t - _a[0]) / max(_b[0] - _a[0], 0.0001));
		}
	}
	return _prof[_n - 1][1];
}

/// Draw an instrument standing on _base_y, _size tall, centred on _cx.
///
/// _tint is the colour the caller has already hazed and flashed, so this
/// function never has to know what hour it is or whether the note just fired.
function prop_draw(_index, _cx, _base_y, _size, _tint, _alpha) {
	if (_alpha <= 0.01 || _size < 2) exit;

	var _d   = global.instruments[_index];
	var _px  = max(1, gmlmcp_tunable("prop_pixel", 4));
	var _top = _base_y - _size;

	// Lit from the side the scene key is on, like the porch. At this size two
	// tones is all a vessel can carry — a gradient across six pixels is noise,
	// not roundness — so it gets a body and one lit edge.
	var _lit_left = (_cx >= global.light.x);
	var _hi = merge_colour(_tint, c_white, 0.32);
	var _lo = merge_colour(_tint, c_black, 0.30);

	var _y0 = floor(_top / _px) * _px;
	var _y1 = ceil(_base_y / _px) * _px;
	var _row = 0;

	draw_set_alpha(_alpha);

	for (var _y = _y0; _y < _y1; _y += _px) {
		// Sampled at the middle of the bar, so a bar is either part of the
		// vessel or it is not.
		var _t = (_y + _px * 0.5 - _top) / max(_size, 1);
		if (_t < 0 || _t > 1) continue;

		var _hw = prop_profile_at(_d.profile, _t);
		if (_hw < 0) continue;

		var _w = _hw * _size;
		if (_w < _px * 0.4) continue;

		var _x1 = floor((_cx - _w) / _px) * _px;
		var _x2 = ceil((_cx + _w) / _px) * _px;
		if (_x2 <= _x1) continue;

		// The mouth. Lighter the whole way across rather than shaded, because
		// you are looking into the opening and not at the side of it.
		var _is_mouth = (_d.rim && _row < 2);

		draw_set_colour(_is_mouth ? _hi : _tint);
		draw_rectangle(_x1, _y, _x2, _y + _px, false);

		if (!_is_mouth) {
			var _edge = min(_px * 2, max(_px, (_x2 - _x1) * 0.34));

			draw_set_colour(_hi);
			if (_lit_left) draw_rectangle(_x1, _y, _x1 + _edge, _y + _px, false);
			else           draw_rectangle(_x2 - _edge, _y, _x2, _y + _px, false);

			// And a turned edge away from the light. Without it the vessels
			// read as flat cards with a stripe down one side.
			draw_set_colour(_lo);
			if (_lit_left) draw_rectangle(_x2 - _px, _y, _x2, _y + _px, false);
			else           draw_rectangle(_x1, _y, _x1 + _px, _y + _px, false);
		}

		_row++;
	}

	draw_set_alpha(1);
}
