/// The rain, as a particle system.
///
/// The field used to be a few thousand structs advanced and drawn by hand in
/// GML. It looked right, but a profile put the two loops at 6.4ms of a 10.8ms
/// step — two thirds of the frame — and almost none of that was the drawing.
/// 4,000 draw_vertex_colour calls cost 0.15ms; the `for` that issued them cost
/// twenty-four times as much. The work was the walking, not the rain.
///
/// GameMaker's particle system does the same walking in the runtime, in native
/// code, and batches the result. So the job here is to say the same thing in
/// terms a particle type can hold.
///
/// --- How the projection survives -----------------------------------------
///
/// A particle type is a fixed set of numbers, and every property of a drop in
/// this scene is a function of its depth: how fast it falls, how long its
/// streak is, how washed out it looks, and where it stops. A continuum of
/// depths cannot be one type, so the range is cut into RAIN_BANDS sheets, each
/// a type of its own with its depth's numbers baked in.
///
/// That is the trade this makes: depth goes from continuous to stepped. In a
/// scene already posterised to four-pixel blocks and five tone bands it is the
/// right kind of approximation, and the band count is a tunable, so the point
/// where stepping becomes visible can be found by eye rather than argued.
///
/// One number falls out of the 1/z model and makes the whole thing work. A
/// drop at depth z falls from cloud_y to ground_y, a distance of
/// (cloud_k + ground_k)/z, at a speed of rain_speed * z_near/z. Divide one by
/// the other and z cancels:
///
///     lifetime = (cloud_k + ground_k) / (rain_speed * z_near)
///
/// Every drop in the scene, near or far, is in the air for the same number of
/// steps. So one lifetime serves every band, and the emission rate needed to
/// hold a band's population steady is just its share of the count divided by
/// that. The only bands that differ are the ones the railing catches, which
/// stop short and so live proportionally less.

/// --- What used to be here, and is not ------------------------------------
///
/// `rain_new_drop` picked a depth first and let everything else follow from
/// it, so a drop never had to know whether it was near or far. That idea did
/// not go anywhere — it is what the bands below are built on, and
/// rain_audio_sample draws its candidates from the same biased depth sample
/// and the same overshot column range.
///
/// Splashes went earlier, for cost. Every drop that landed pushed a ring onto
/// a list and every frame drew the live ones as outlined ellipses, up to the
/// 320 the list was capped at, each its own unbatched primitive. If they come
/// back they should come back cheaper — filled quads, or written into the
/// water shader, which already knows the surface and the hour. What they
/// needed still exists: landing_at answers where a column at a depth comes to
/// rest and on what, and the audio reads exactly that.

/// How many depth sheets the range is cut into.
///
/// Each is one particle type and one emitter, so this is cheap to raise — the
/// per-frame cost is a handful of property calls per band, not per drop.
#macro RAIN_BANDS 28

function rain_particles_init() {
	global.rain_ps = part_system_create();

	// The same depth obj_rain drew at: between obj_scene at 60 and the porch at
	// -100, so the rain is behind the railing you are sitting at and in front of
	// the lake. Depth rather than a layer, so it goes through the normal draw
	// pipeline and into the application surface — and therefore through
	// shd_post, which posterises it with the rest of the picture.
	part_system_depth(global.rain_ps, 30);

	global.rain_bands = [];

	for (var _i = 0; _i < RAIN_BANDS; _i++) {
		var _t = part_type_create();

		// One emitter each. They are re-shaped every step rather than at
		// creation, because the projection they are placed against is live —
		// horizon, ground_k and the rest are all tunables.
		var _e = part_emitter_create(global.rain_ps);

		part_type_sprite(_t, spr_rain_streak, false, false, false);
		part_type_life(_t, 1, 1);

		// The streak lies along the drop's own velocity. `true` at the end makes
		// the orientation relative to the direction of travel, so the sprite
		// aims itself and wind tilts the rain without anything here computing an
		// angle. The sprite's head is at its origin and its tail runs back along
		// -x, which at a relative angle of zero is exactly behind the drop.
		part_type_orientation(_t, 0, 0, 0, 0, true);

		array_push(global.rain_bands, { type: _t, emitter: _e, z: 0, acc: 0 });
	}
}

/// Re-read the live numbers and re-shape every band. Once per step.
///
/// Everything is recomputed rather than cached because every input is a
/// tunable: the projection, the wind, the drop count and the palette all move
/// while the game runs. RAIN_BANDS iterations of this is a rounding error
/// against the thousands it replaces.
function rain_particles_update() {
	var _count  = max(0, gmlmcp_tunable("rain_count", 2000));
	var _speed  = gmlmcp_tunable("rain_speed", 30);
	var _wind   = gmlmcp_tunable("rain_wind",  -4) * (0.35 + 0.9 * wind_strength());
	var _streak = gmlmcp_tunable("rain_streak", 62);
	var _a_near = gmlmcp_tunable("rain_alpha_near", 0.80);
	var _a_far  = gmlmcp_tunable("rain_alpha_far",  0.24);
	var _col    = global.pal.rain;

	var _zn = global.persp_z_near;
	var _zf = global.persp_z_far;

	// Velocity direction is the same at every depth: both components scale by
	// the same persp_scale, so depth changes the length of the vector and never
	// its angle. One direction serves every band.
	//
	// GameMaker measures direction anticlockwise from east, and point_direction
	// already flips screen y for you — so the velocity is handed over in plain
	// screen terms, y positive downward, and it comes back as the 270-ish that
	// means falling. Negating the speed here to "make it go down" negates it
	// twice and the rain flies off the top of the screen.
	var _dir = point_direction(0, 0, _wind, _speed);

	// Bands are spaced evenly in apparent size, not in depth.
	//
	// Depth is the wrong axis to cut on. Everything you can see about a drop —
	// its length, its speed, how washed out it is — goes as 1/z, so even slices
	// of z put twenty-six of twenty-eight sheets in the far haze, where they
	// are indistinguishable from each other, and leave the near half of the
	// screen to two. Worse, sampling each slice at its centre means the nearest
	// sheet sits at 74% of full size and the biggest streaks in the scene, the
	// ones an arm's length from your face, never get drawn at all.
	//
	// Cutting evenly in s = z_near/z fixes both: equal steps in apparent size,
	// resolution concentrated near the viewer where a drop is a distinct streak
	// rather than part of a wash, and the top band reaching s = 1.
	//
	// The count then has to be weighted, because the bands are no longer equal
	// slices of depth. A drop's depth is uniform over the range, so a band's
	// share of the field is its share of that range — which for the near bands
	// is very little. That is correct and is what the old field did: near
	// drops were always rare, and they read as rain rather than as static
	// precisely because they were.
	var _s_far = _zn / _zf;
	var _span  = max(0.0001, _zf - _zn);

	for (var _i = 0; _i < RAIN_BANDS; _i++) {
		var _b = global.rain_bands[_i];

		// The band's edges in apparent size, and the depths they correspond to.
		// Note the swap: a bigger s is a nearer drop, so the low edge in s is
		// the far edge in z.
		var _s_lo = lerp(_s_far, 1, _i / RAIN_BANDS);
		var _s_hi = lerp(_s_far, 1, (_i + 1) / RAIN_BANDS);

		var _s = (_s_lo + _s_hi) * 0.5;
		var _z = _zn / _s;
		_b.z = _z;

		// This band's share of the field, from how much of the depth range it
		// covers. The sheets nest rather than tile on screen — each spans from
		// its own cloud row to its own landing row, and a nearer one is strictly
		// wider — so the union is continuous and the stepping shows up as
		// discrete streak lengths, never as gaps between sheets.
		var _per = _count * ((_zn / _s_lo) - (_zn / _s_hi)) / _span;

		var _top  = cloud_y(_z);

		// Where this sheet stops. The railing catches a thin slice of depth
		// across the full width of the view, so a band either lands on the rail
		// entirely or misses it entirely — no band is half caught, which is what
		// lets a whole sheet share one lifetime.
		//
		// The exception is a placed instrument, which is a narrow surface on top
		// of the rail. Those are not modelled here: they are a couple of percent
		// of the field, sitting behind the objects themselves. The audio still
		// gets them right, because it asks landing_at directly.
		var _caught = (_z >= RAIL_Z_NEAR && _z <= RAIL_Z_FAR);
		var _land   = _caught ? RAIL_Y : ground_y(_z);

		var _fall = max(1, _land - _top);
		var _px   = max(0.01, _speed * _s);   // pixels per step
		var _life = max(1, ceil(_fall / _px));

		part_type_life(_b.type, _life, _life);
		part_type_speed(_b.type, _px, _px, 0, 0);
		part_type_direction(_b.type, _dir, _dir, 0, 0);

		// Streak length in pixels, as a multiple of the sprite's own 64. Its
		// thickness is held near a pixel in the distance and allowed to grow to
		// the full four close up, because a one pixel line cannot carry a drop
		// that is meant to be an arm's length from your face.
		part_type_scale(_b.type, _streak * _s / 64, lerp(0.3, 1.0, _s));

		// Distance washes the rain out. The palette gives the colour, so the
		// rain darkens and warms with the hour without this knowing the time.
		part_type_colour1(_b.type, _col);
		part_type_alpha1(_b.type, lerp(_a_far, _a_near, _s));

		// A line across the top of the sheet, overshooting both edges so wind
		// can blow drops in from off screen rather than having them wink into
		// existence at the frame's edge.
		part_emitter_region(global.rain_ps, _b.emitter,
			-140, room_width + 140, _top, _top,
			ps_shape_line, ps_distr_linear);

		// Emission rate to hold this band's share of the field in the air. A
		// step's worth is fractional, so it is accumulated and spent in whole
		// drops — rounding it every step would quietly drop the sparse bands to
		// nothing or double the dense ones.
		_b.acc += _per / _life;
		var _n = floor(_b.acc);
		if (_n > 0) {
			_b.acc -= _n;
			part_emitter_burst(global.rain_ps, _b.emitter, _b.type, _n);
		}
	}
}
