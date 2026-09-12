/// A single drop of rain.
///
/// Depth is chosen first and everything else follows from it, so a drop never
/// needs to know whether it is "near" or "far" — the projection decides how
/// fast it falls, how long its streak is and where it stops.

/// A fresh drop at a random depth and column.
///
/// `_stagger` starts it partway through its fall. Used when seeding the field
/// so the first frame already has rain hanging in the air, instead of a curtain
/// of drops released in unison and marching down the screen in lockstep.
function rain_new_drop(_stagger) {
	// Biasing the depth sample pushes most of the drop count into the distance,
	// where drops are small and cheap, and keeps the big near streaks sparse.
	// Too many near streaks reads as static rather than rain.
	var _t = power(random(1), global.rain_depth_bias);
	var _z = lerp(global.persp_z_near, global.persp_z_far, _t);

	// Columns are picked in screen space, overshooting both edges so wind can
	// blow drops in from off-screen rather than having them appear at the edge.
	var _x = random_range(-140, room_width + 140);

	var _land = landing_at(_x, _z);
	var _top = cloud_y(_z);

	return {
		x: _x,
		y: _stagger ? lerp(_top, _land.y, random(1)) : _top,
		z: _z,
		land: _land.y,
		kind: _land.kind,
	};
}

/// The mark a drop leaves when it arrives.
///
/// Splashes are flattened by the same perspective as everything else: a ring
/// seen at a shallow angle is an ellipse, and the further away it is the
/// flatter and smaller it reads.
function rain_add_splash(_x, _y, _scale, _kind) {
	// Far splashes are sub-pixel and only cost fill rate, and the list is
	// capped so a downpour cannot let it grow without bound.
	if (_scale < 0.10) return;
	if (array_length(global.rain_splashes) >= 320) return;
	array_push(global.rain_splashes, {
		x: _x, y: _y, s: _scale, kind: _kind, t: 0,
	});
}

/// Draw the splashes, in two passes at different depths.
///
/// A splash sits *on* the surface it hit, so it has to be drawn with that
/// surface rather than with the rain. Water lands out in the scene and belongs
/// behind the railing; the railing's own splashes sit on top of it and would be
/// swallowed if they were drawn with everything else. `_wood` picks the pass.
function rain_draw_splashes(_wood) {
	var _life = gmlmcp_tunable("splash_life", 18);
	draw_set_colour(global.pal.splash);

	var _list = global.rain_splashes;
	for (var _i = 0, _n = array_length(_list); _i < _n; _i++) {
		var _s = _list[_i];
		if ((_s.kind == "wood") != _wood) continue;

		var _p = _s.t / _life;
		var _r = (3 + 17 * _p) * _s.s;

		// Fading on distance as well as age, but on the square root of it, so
		// mid-distance splashes stay readable instead of dropping out early.
		draw_set_alpha((1 - _p) * 0.62 * sqrt(_s.s));
		draw_ellipse(_s.x - _r, _s.y - _r * 0.30, _s.x + _r, _s.y + _r * 0.30, true);

		// Wood throws a short vertical tick instead of a spreading ring — a
		// hard surface scatters the drop upward where open water swallows it.
		if (_wood && _p < 0.5) {
			draw_line(_s.x, _s.y, _s.x, _s.y - 9 * _s.s * (1 - _p * 2));
		}
	}

	draw_set_alpha(1);
}
