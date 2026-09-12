/// Contact shadows.
///
/// Authored rather than computed. A depth buffer and a shadow map would be the
/// general answer, but this scene already knows exactly where everything is
/// standing — the trees carry a z, the instruments carry a ledge — and at this
/// resolution a blob placed by the projection reads better than anything a
/// shadow map would resolve. The general machinery would also mean every
/// future thing drawn has to remember to write depth, or the lighting quietly
/// breaks and nobody notices until dusk.
///
/// Everything here leans on global.light, so the shadows, the porch relief and
/// the light shafts cannot disagree about where the sun is.

/// Draw an ellipse on the pixel grid.
///
/// Built from snapped horizontal bars rather than with draw_ellipse: a smooth
/// antialiased edge is the one thing that would give away that the rest of the
/// scene is posterised into blocks.
function shadow_ellipse(_cx, _cy, _rx, _ry, _colour, _alpha) {
	if (_alpha <= 0.01 || _rx <= 0 || _ry <= 0) exit;

	var _px = max(1, gmlmcp_tunable("shadow_pixel", 4));

	draw_set_colour(_colour);
	draw_set_alpha(_alpha);

	var _y0 = floor((_cy - _ry) / _px) * _px;
	var _y1 = ceil((_cy + _ry) / _px) * _px;

	for (var _y = _y0; _y < _y1; _y += _px) {
		// Sampled at the middle of the bar, so a bar is either inside the
		// ellipse or outside it rather than half-covering its own row.
		var _t = (_y + _px * 0.5 - _cy) / _ry;
		if (abs(_t) >= 1) continue;

		var _w = _rx * sqrt(1 - _t * _t);
		draw_rectangle(floor((_cx - _w) / _px) * _px, _y,
		               ceil((_cx + _w) / _px) * _px, _y + _px, false);
	}

	draw_set_alpha(1);
}

/// Drop a shadow from something of width _size standing at _x on row _base_y.
///
/// The shadow leans away from the key light and stretches as the light drops
/// toward the horizon. That is the one thing a shadow has to get right to say
/// what hour it is — a blob that sits underfoot all day reads as an object
/// pasted onto the ground rather than standing on it.
function shadow_cast(_x, _base_y, _size, _colour, _strength) {
	var _l = global.light;
	if (_l.strength <= 0.02 || _strength <= 0.01) exit;

	// Overhead light gives a tight shadow underfoot; a low one throws it long.
	var _alt  = clamp(_l.alt, 0, 1);
	var _lean = (1 - _alt) * gmlmcp_tunable("shadow_lean", 0.85);

	// Away from the light, whichever side of the caster it is on.
	var _dir = (_x >= _l.x) ? 1 : -1;

	var _rx = _size * (0.42 + 0.50 * _lean);
	var _ry = _size * 0.13 * (1 - 0.35 * _lean);

	// A long shadow is a fainter one: the light throwing it is grazing, so less
	// of it is being blocked per unit of ground.
	var _a = _strength
	       * gmlmcp_tunable("shadow_alpha", 0.5)
	       * (1 - 0.35 * _lean)
	       * (0.35 + 0.65 * _l.strength);

	shadow_ellipse(_x + _dir * _size * 0.35 * _lean, _base_y, _rx, _ry, _colour, _a);
}
