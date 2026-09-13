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

/// The depth the rain is cut at, so the trees can stand inside it.
///
/// The field used to be one particle system at one depth, which meant every
/// drop in the scene drew over every tree — including drops thirty units out,
/// in front of a trunk two units away. Nothing sorted, because depth order is
/// the whole of the sorting here and the whole field had one depth.
///
/// It is two systems now, with the trees in the gap between them:
///
///     beyond this   behind the stand         depth 55
///     nearer        in front of everything   depth 20
///
/// 2.3 is the middle of the far stand, which sits between 2.05 and 2.56.
/// Because depth is distributed uniformly, under two percent of drops land in
/// front — but those are the long bright streaks, and they are the only ones
/// big enough to read crossing a trunk anyway.
///
/// The near half goes in front of *everything*, the near tree included, and
/// that last part is a cheat worth naming. The near tree is at 1.15 and the
/// field starts at z_near 1.7, so on the geometry no drop in the scene belongs
/// in front of it. But its depth is itself a framing cheat — scr_trees says so
/// — and a tree at arm's length with nothing falling past it reads as a
/// cut-out pasted over the weather.
///
/// A third layer between the two trees was tried and thrown away. It is where
/// the strictly correct drops would go: nearer than the far stand, further
/// than the near tree. There turned out to be no way to see the difference,
/// and the whole visible effect was the drops it was withholding from the
/// front.
#macro RAIN_SPLIT_Z 2.3

function rain_particles_init() {
	// Two systems, one either side of the stand of trees. Depths rather than
	// layers, so both go through the normal draw pipeline and into the
	// application surface — and therefore through shd_post, which posterises
	// them with the rest of the picture.
	//
	// 55 is behind obj_trees at 50 and in front of obj_scene at 60; 20 is in
	// front of obj_tree_near at 25 and so in front of both. Both stay well
	// behind the porch at -100, so the rain is behind the railing you are
	// sitting at whichever side of a tree it is on.
	global.rain_ps_far   = part_system_create();
	global.rain_ps_front = part_system_create();

	part_system_depth(global.rain_ps_far,   55);
	part_system_depth(global.rain_ps_front, 20);

	global.rain_bands = [];

	for (var _i = 0; _i < RAIN_BANDS; _i++) {
		var _t = part_type_create();

		// An emitter on each system, rather than one on whichever system the
		// band belongs to. A band's depth comes from live tunables and can move
		// under it, and an emitter belongs to the system it was created on —
		// so holding both means the band can change sides between frames
		// without anything being rebuilt.
		//
		// They are re-shaped every step rather than at creation, because the
		// projection they are placed against is live: horizon, ground_k and the
		// rest are all tunables.
		var _e_far   = part_emitter_create(global.rain_ps_far);
		var _e_front = part_emitter_create(global.rain_ps_front);

		part_type_sprite(_t, spr_rain_streak, false, false, false);
		part_type_life(_t, 1, 1);

		// The streak lies along the drop's own velocity. `true` at the end makes
		// the orientation relative to the direction of travel, so the sprite
		// aims itself and wind tilts the rain without anything here computing an
		// angle. The sprite's head is at its origin and its tail runs back along
		// -x, which at a relative angle of zero is exactly behind the drop.
		part_type_orientation(_t, 0, 0, 0, 0, true);

		array_push(global.rain_bands,
			{ type: _t, far: _e_far, front: _e_front, z: 0, acc: 0 });
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
	// Capped under the god ray threshold. pal.rain is 0.93 luminance — brighter
	// than lit cloud and brighter than the sun disc — so uncapped every drop in
	// the frame was a light source, and forty thousand of them added up to a
	// wash of bloom smeared toward the sun rather than to beams through the
	// trees. The colour is unchanged; only the level comes down.
	var _col    = ray_safe(global.pal.rain);

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

		// Which layer this sheet falls in, and so which system its drops are
		// emitted into. Particles already in the air keep the system they were
		// born on, which is what should happen: a drop does not change which
		// side of a tree it is on halfway down.
		var _behind = (_z >= RAIN_SPLIT_Z);
		var _ps = _behind ? global.rain_ps_far : global.rain_ps_front;
		var _em = _behind ? _b.far : _b.front;

		// A line across the top of the sheet, overshooting both edges so wind
		// can blow drops in from off screen rather than having them wink into
		// existence at the frame's edge.
		part_emitter_region(_ps, _em,
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
			part_emitter_burst(_ps, _em, _b.type, _n);
		}
	}
}
