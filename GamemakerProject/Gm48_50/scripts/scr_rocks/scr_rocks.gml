/// Rocks, on the bank and standing out of the shallows.
///
/// A table, like the trees, and for the same reasons: the composition is
/// decided in one readable place, and every rock is positioned by depth alone
/// so the projection gives it its screen row, its size and its haze without
/// anyone maintaining three numbers that have to agree.
///
/// Drawn rather than sprited. A rock at this distance is a lump of four or
/// five stacked bars, and building it out of the same snapped blocks the props
/// and the lantern use costs less than an art pipeline and keeps it on the
/// scene's grid.
///
/// --- Which side of the water a rock is on --------------------------------
///
/// The bank stands at BANK_Z. Anything nearer than that is on grass; anything
/// beyond it is standing in the lake, because the ground plane at that depth
/// *is* the water surface. So one number in the table decides which a rock is,
/// and rocks_draw is called twice from obj_scene — once after the water and
/// its reflections, once after the bank — so each group lands in the right
/// place in the draw order without a second table.

function rocks_init() {
	// Sorted far to near within each group, so drawing order does the sorting
	// the same way it does for the trees.
	//
	// `w` and `h` are the size at the near plane; on screen they come out as
	// w * persp_scale(z). Depths are spread on purpose — a row of rocks at one
	// depth lands on one screen row and reads as a wall.
	global.rocks = [
		// --- In the water ------------------------------------------------
		// Kept beyond z 3.6, which is where the ground plane rises above the
		// railing. Nearer than that and a rock would sit behind the porch and
		// nobody would ever see it.

		// A far scatter, small and close to the horizon, just enough to say the
		// lake has a bottom.
		{ x: 1124, z: 7.4, w:  58, h: 30, wet: true },
		{ x:  636, z: 6.6, w:  70, h: 34, wet: true },

		// The mid pair: one large, one small beside it. Two rocks at different
		// sizes read as scale; one on its own reads as an island.
		{ x:  946, z: 4.9, w:  86, h: 40, wet: true },
		{ x:  392, z: 5.4, w:  74, h: 36, wet: true },

		// The near ones, big enough to break the waterline properly.
		{ x:  878, z: 3.95, w: 128, h: 56, wet: true },
		{ x:  296, z: 4.15, w: 108, h: 50, wet: true },

		// --- On the bank -------------------------------------------------
		// Seen through the gaps between the balusters, which is the only way
		// the bank is seen at all. Kept clear of the trees' columns so a rock
		// never has to argue with a trunk about which of them is in front.
		{ x:  704, z: 2.54, w:  70, h: 32, wet: false },
		{ x:  480, z: 2.44, w:  92, h: 42, wet: false },   // clear of the dock's landing
		{ x:  570, z: 2.22, w: 118, h: 52, wet: false },   // clear of the dock's landing
		{ x:  868, z: 2.08, w:  84, h: 38, wet: false },
	];
}

/// A stable pseudo-random in [0, 1) from an integer.
///
/// Rocks need to be lumpy, and lumpy means asymmetric. Taking that from
/// random() at init would reshape every rock on every launch, which for a
/// hand-placed composition is the wrong kind of variety — you would tune a
/// scene and then never see it again. This gives each rock the same lumps
/// every time without a seed to store.
function rock_hash(_n) {
	return frac(sin(_n * 12.9898) * 43758.5453);
}

/// Draw one group of rocks.
///
/// `_wet` picks which: true for the ones standing in the lake, false for the
/// ones on the grass.
function rocks_draw(_wet) {
	// Two pixels, not the scene's four. The far rocks are a dozen pixels
	// across and on a four pixel grid a single row would be a third of the
	// whole rock.
	var _px   = 2;
	var _list = global.rocks;

	for (var _i = 0; _i < array_length(_list); _i++) {
		var _r = _list[_i];
		if (_r.wet != _wet) continue;

		var _s = persp_scale(_r.z);
		var _w = _r.w * _s;
		var _h = _r.h * _s;
		var _y = ground_y(_r.z);

		// Hazed on the far curve rather than the near one. A rock in the lake
		// sits well past where aerial_fade saturates, so on the shared curve
		// every one of them came out at the same maximum — and at that
		// strength a grey rock blended into a grey lake and disappeared.
		var _hz = _wet ? far_haze(_r.z, 0.38) : aerial_fade(_r.z, 0.5);

		// Stone takes the day's light rather than being repainted by it. Wet
		// stone is darker and cooler than dry, which is the whole visual
		// difference between a rock on the grass and the same rock standing in
		// the water — and out there it has to be dark enough to read as a
		// silhouette against the lake, because there is nothing else to
		// separate it from the water but tone.
		var _base = _wet ? make_colour_rgb(50, 53, 58) : make_colour_rgb(112, 108, 98);
		var _body = merge_colour(pal_lit(_base), global.pal.water, _hz);
		var _top  = merge_colour(pal_lit(merge_colour(_base, c_white, 0.30)),
			global.pal.water, _hz);

		var _cx = floor(_r.x / _px) * _px;
		var _by = floor(_y / _px) * _px;

		draw_set_alpha(1);

		if (_wet) rock_water(_r, _cx, _by, _w, _s, _px, _hz);

		// The lump itself: bars stacked from the top down, widening toward the
		// base, with each edge nudged on its own so no two rocks and no two
		// rows of one rock share a silhouette.
		var _prof = [0.44, 0.72, 0.90, 1.00];
		var _n    = array_length(_prof);
		var _rh   = max(_px, floor(_h / _n / _px) * _px);

		// Stacked up from the waterline, not down from the rock's nominal top.
		// Row height is floored onto the two pixel grid, so rows * height is
		// usually a little short of h — measure from the top and that shortfall
		// becomes a gap underneath, and the smaller rocks hover above the water
		// they are supposed to be standing in.
		var _stack = _by - _rh * _n;

		for (var _k = 0; _k < _n; _k++) {
			var _hw = _w * 0.5 * _prof[_k];

			// Two hashes per row, so the left and right edges wander
			// independently — one offset applied to both would slide the row
			// sideways and the rock would come out as a leaning stack.
			var _el = (rock_hash(_i * 17 + _k * 3 + 1) - 0.5) * _w * 0.22;
			var _er = (rock_hash(_i * 17 + _k * 3 + 2) - 0.5) * _w * 0.22;

			var _y1 = _stack + _rh * _k;
			var _y2 = _y1 + _rh;

			draw_set_colour((_k == 0) ? _top : _body);
			draw_rectangle(floor((_cx - _hw + _el) / _px) * _px, floor(_y1 / _px) * _px,
			               floor((_cx + _hw + _er) / _px) * _px, floor(_y2 / _px) * _px, false);
		}
	}

	draw_set_alpha(1);
}

/// What a rock standing in the lake does to the water around it.
///
/// Drawn before the rock, so the rock sits down into it rather than on top of
/// it. Two things: a short dark reflection, and a pale line of water breaking
/// against the stone. The line is what actually sells it — without something
/// happening at the waterline a rock in a lake reads as a rock in front of a
/// lake.
function rock_water(_r, _cx, _by, _w, _s, _px, _hz) {
	// Riding the lake's own clock, so the water laps at the rock in time with
	// the waves the shader is drawing behind it.
	var _wob = sin(global.water_time * 1.5 + _r.x * 0.031) * 2.2 * _s;

	// The reflection. Short, faint and narrower than the rock — on water this
	// broken up, anything more would read as a second rock.
	draw_set_alpha((1 - _hz) * 0.30);
	draw_set_colour(merge_colour(global.pal.water, c_black, 0.45));
	draw_rectangle(_cx - _w * 0.34, _by, _cx + _w * 0.34, _by + max(_px, _px * 2 * _s), false);

	// And the break. Wider than the rock on both sides, because that is where
	// the water is being pushed aside.
	draw_set_alpha((1 - _hz) * 0.5);
	draw_set_colour(merge_colour(global.pal.water, c_white, 0.35));
	draw_rectangle(floor((_cx - _w * 0.72 + _wob) / _px) * _px, _by - _px,
	               floor((_cx + _w * 0.72 + _wob) / _px) * _px, _by, false);

	draw_set_alpha(1);
}
