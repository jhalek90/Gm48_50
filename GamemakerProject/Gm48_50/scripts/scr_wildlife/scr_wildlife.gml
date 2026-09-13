/// The things that live here.
///
/// Three of them, and between them they cover the clock: birds cross the sky
/// while the sun is up, a duck works the lake through the day, and fireflies
/// come out over the bank once it has gone down. The scene already changes
/// colour and key across the cycle; this is what makes the hours feel
/// different rather than merely look different.
///
/// None of it is interactive and none of it is simulated any further than it
/// has to be. Each one is a handful of numbers advanced on the same delta_time
/// clock everything else here uses, drawn in the same snapped blocks, hazed by
/// the same aerial_fade, and tinted out of the same palette.
///
/// --- Where they are drawn ------------------------------------------------
///
/// Depth order is the whole of the sorting, so each has to go in at the right
/// point rather than on top of everything. Birds and the duck are drawn from
/// inside obj_scene's Draw, between the layers they belong between: birds
/// after the mountains, so they pass in front of the range; the duck after the
/// water and its reflections but before the near bank and the trees, so it
/// floats on the lake and drifts behind a trunk rather than across it.
///
/// The fireflies are a particle system at depth 40, which puts them in front
/// of the bank they are over and behind the porch — so they wink out as they
/// pass behind a baluster, which is most of what makes them read as being out
/// there in the grass rather than painted on the glass.

/// How many fireflies are in the air on a full night.
#macro FLY_COUNT   26

/// How many birds the sky holds at once.
#macro BIRD_COUNT   7

function wildlife_init() {
	global.wildlife_t = 0;

	birds_init();
	duck_init();
	fireflies_init();
}

function wildlife_step() {
	global.wildlife_t += delta_time / 1000000;

	birds_step();
	duck_step();
	fireflies_update();
}

/// How much of a day it is, and how much of a night.
///
/// Taken from the sun's altitude rather than from the phase index, because the
/// phases change on a hard boundary and this has to cross over gradually — a
/// sky that swaps its birds for fireflies in one frame at 22:00 would undo
/// every other thing in this project that blends.
///
/// The threshold sits a little above the horizon, so the fireflies are already
/// coming out while there is light left in the sky, which is when they
/// actually do.
function wildlife_day() {
	var _alt = sky_sun().alt;
	return clamp((_alt + 0.27) / 0.45, 0, 1);
}

function wildlife_night() {
	return 1 - wildlife_day();
}

/// A colour with the scene's light falling on it.
///
/// Multiplied, not blended. The trees already do exactly this by handing
/// pal.light to draw_sprite_ext as a tint; this is the same operation for
/// something drawn as rectangles, and it has to be the same or the wildlife
/// will be the one set of things in the scene lit by a different sun.
///
/// The distinction is not academic. pal.light runs from (70,80,120) at night
/// to (255,255,250) at noon, so multiplying leaves a thing alone in daylight
/// and sinks it at night — which is what light does. Blending *toward* it
/// instead washes dark things pale at noon, and that is what turned the duck
/// into a gull on the first attempt.
function wildlife_lit(_c) {
	var _l = global.pal.light;
	return make_colour_rgb(
		colour_get_red(_c)   * colour_get_red(_l)   / 255,
		colour_get_green(_c) * colour_get_green(_l) / 255,
		colour_get_blue(_c)  * colour_get_blue(_l)  / 255);
}

/// How far into the air a thing at depth z has receded.
///
/// Not aerial_fade, which is the shared curve for the near scene and saturates
/// at about z 3.5 — every bird in the sky sits well beyond that, so the shared
/// curve returned its maximum for all of them and the whole flock came out at
/// one washed-out tone with no depth in it at all. This keeps a gradient
/// across the range the sky actually uses.
function wildlife_haze(_z, _max) {
	return clamp(1 - persp_scale(_z) * 2.0, 0, _max);
}

// --- Birds ---------------------------------------------------------------
//
// Placed by depth like everything else, so one number gives a bird its size,
// how fast it crosses, and how far it has washed out into the air. A flock of
// identical birds at identical heights is the thing that reads as wallpaper.

function birds_init() {
	global.birds = [];
	for (var _i = 0; _i < BIRD_COUNT; _i++) array_push(global.birds, bird_new(true));
}

/// One bird. `_seeded` scatters it across the sky rather than starting it at
/// the edge, so the first frame already has birds in it.
function bird_new(_seeded) {
	var _z   = random_range(4.0, 13.0);
	var _dir = choose(-1, 1);

	return {
		z:     _z,
		dir:   _dir,
		x:     _seeded ? random_range(-380, room_width + 380)
		               : (_dir > 0 ? -380 : room_width + 380),

		// Between the roof line and the horizon. Birds below the horizon would
		// be standing on the lake.
		y:     random_range(128, 248),

		// Wingbeats per second, and where in the beat it starts. Both random,
		// because a flock beating in unison is a single bird copied.
		rate:  random_range(5.5, 9.5),
		phase: random(2 * pi),
	};
}

function birds_step() {
	var _dt = delta_time / 1000000;

	for (var _i = 0; _i < array_length(global.birds); _i++) {
		var _b = global.birds[_i];

		// Screen speed off the same projection as the size, so a near bird
		// crosses fast and a far one crawls — which is most of what separates
		// them, since at this scale they are all much the same shape.
		_b.x += _b.dir * 230 * persp_scale(_b.z) * _dt;

		// Gone past the far side: replace it rather than wrap it, so the sky
		// is a changing set of birds instead of the same seven on a loop.
		if (_b.x < -420 || _b.x > room_width + 420) global.birds[_i] = bird_new(false);
	}
}

function birds_draw() {
	var _day = wildlife_day();
	if (_day <= 0.02) return;

	// Two pixels rather than the scene's four. A bird at this distance is a
	// handful of pixels across, and on a four pixel grid a wingbeat would be a
	// quarter of the whole bird moving at once.
	var _px = 2;

	for (var _i = 0; _i < array_length(global.birds); _i++) {
		var _b = global.birds[_i];

		// Half a wingspan. The whole bird is four bars and a body, which at
		// fourteen pixels across is as much bird as there is room for — what
		// says bird is the beat, not the outline.
		var _s  = 46 * persp_scale(_b.z) * 0.5;
		var _f  = sin(global.wildlife_t * _b.rate + _b.phase);

		var _hz = wildlife_haze(_b.z, 0.55);
		var _c  = merge_colour(wildlife_lit(make_colour_rgb(26, 28, 36)),
			global.pal.sky_mid, _hz);

		draw_set_colour(_c);
		draw_set_alpha(_day * (1 - _hz * 0.3));

		var _x = floor(_b.x / _px) * _px;
		var _y = floor(_b.y / _px) * _px;

		// Body.
		draw_rectangle(_x - _px, _y - _px * 0.5, _x + _px, _y + _px * 0.5, false);

		// Each wing in two segments, the outer one swinging further than the
		// inner, so the wing bends at the wrist instead of pivoting as a plank.
		bird_wing(_x, _y, -1, _s, _f, _px);
		bird_wing(_x, _y,  1, _s, _f, _px);
	}

	draw_set_alpha(1);
}

function bird_wing(_x, _y, _side, _s, _f, _px) {
	var _i1 = _y + _f * _s * 0.22;
	var _o1 = _y + _f * _s * 0.58;

	draw_rectangle(_x + _side * _s * 0.18, _i1 - _px * 0.5,
	               _x + _side * _s * 0.55, _i1 + _px * 0.5, false);

	draw_rectangle(_x + _side * _s * 0.55, _o1 - _px * 0.5,
	               _x + _side * _s * 1.00, _o1 + _px * 0.5, false);
}

// --- The duck ------------------------------------------------------------
//
// One, not a flock. A single bird working a whole lake is calm; four of them
// is a pond at a park.

function duck_init() {
	global.duck = {
		z:     3.8,
		x:     room_width * 0.42,
		dir:   1,
		phase: random(2 * pi),

		// Seconds until it thinks about turning around. A duck that only turns
		// at the edges of its range paces like something in a cage.
		turn:  random_range(6, 16),
	};
}

function duck_step() {
	var _dt = delta_time / 1000000;
	var _d  = global.duck;

	_d.x += _d.dir * 20 * persp_scale(_d.z) * _dt;

	_d.turn -= _dt;
	if (_d.turn <= 0) {
		_d.dir  = -_d.dir;
		_d.turn = random_range(8, 22);
	}

	// And it turns at the edges regardless, so it stays on open water rather
	// than paddling off behind the porch post.
	if (_d.x < 240)                   { _d.dir =  1; _d.turn = random_range(8, 22); }
	if (_d.x > room_width - 240)      { _d.dir = -1; _d.turn = random_range(8, 22); }
}

function duck_draw() {
	var _d  = global.duck;
	var _px = 2;
	var _s  = persp_scale(_d.z);

	// Never fully gone at night — a duck is still out there, it is just a
	// shape on dark water — but daylight is when it is worth looking at.
	var _a = 0.28 + 0.72 * wildlife_day();

	// Riding the same clock the lake does, so it lifts with the water rather
	// than bobbing to a rhythm of its own.
	var _y = ground_y(_d.z) + sin(global.water_time * 1.4 + _d.phase) * 1.6 * _s;
	var _x = floor(_d.x / _px) * _px;
	_y = floor(_y / _px) * _px;

	var _hz   = wildlife_haze(_d.z, 0.30);
	var _body = merge_colour(wildlife_lit(make_colour_rgb(104, 76, 52)),
		global.pal.water, _hz);
	var _head = merge_colour(wildlife_lit(make_colour_rgb(40, 52, 46)),
		global.pal.water, _hz);

	var _w = max(_px * 3, round(46 * _s / _px) * _px);   // body length
	var _h = max(_px * 2, round(12 * _s / _px) * _px);   // body height
	var _f = _d.dir;                                      // which way it faces

	draw_set_alpha(_a * 0.22);
	draw_set_colour(_body);

	// What it sits in. A short dark smear under the bird, which is the whole
	// of its reflection — anything more detailed on water this broken up would
	// read as a second duck. Narrower than the hull and faint, because at full
	// width and strength it stopped reading as water and started reading as
	// the edge of a plank the duck was standing on.
	draw_rectangle(_x - _w * 0.32, _y + _h, _x + _w * 0.32, _y + _h + _px, false);

	draw_set_alpha(_a);
	draw_set_colour(_body);

	// Body: a low hull with a rounder back, and the tail lifted at the stern.
	draw_rectangle(_x - _w * 0.5, _y, _x + _w * 0.5, _y + _h, false);
	draw_rectangle(_x - _w * 0.3, _y - _h * 0.6, _x + _w * 0.32, _y, false);
	draw_rectangle(_x - _f * _w * 0.5 - _f * _px, _y - _h * 0.5,
	               _x - _f * _w * 0.34, _y, false);

	// Neck and head, at the bow.
	var _nx = _x + _f * _w * 0.30;
	draw_rectangle(_nx - _px * 0.5, _y - _h * 1.5, _nx + _px * 0.5, _y - _h * 0.4, false);

	draw_set_colour(_head);
	draw_rectangle(_nx - _px, _y - _h * 2.2, _nx + _px, _y - _h * 1.3, false);
	draw_rectangle(_nx + _f * _px, _y - _h * 1.9, _nx + _f * _px * 2, _y - _h * 1.5, false);

	draw_set_alpha(1);
}

// --- Fireflies -----------------------------------------------------------
//
// Particles, and a good fit for once: a firefly is a blink. Give a particle a
// short life and an alpha that rises and falls across it and the blink is the
// whole entity — no insect has to be tracked between flashes, because in the
// dark you cannot tell whether the next flash came from the same one.

function fireflies_init() {
	global.fly_ps = part_system_create();
	part_system_depth(global.fly_ps, 40);

	var _t = part_type_create();
	global.fly_type = _t;

	// The same soft falloff the lantern uses, at a fraction of the size. A
	// firefly is a point of light with a halo, which is exactly what that
	// sprite is.
	part_type_sprite(_t, spr_glow, false, false, false);
	part_type_scale(_t, 0.055, 0.055);
	part_type_blend(_t, true);

	// Warm green-gold, and kept under the god ray threshold like everything
	// else that glows here, or every firefly would drag a streak toward the
	// moon.
	part_type_colour1(_t, make_colour_rgb(196, 212, 104));

	// Rise, hold, fall. This is the blink.
	part_type_alpha3(_t, 0, 1, 0);
	part_type_life(_t, 55, 115);

	// Barely moving, and wandering while it does. A firefly drifts; a spark
	// travels in a straight line, and the difference is the wiggle.
	part_type_speed(_t, 0.10, 0.45, 0, 0.05);
	part_type_direction(_t, 0, 360, 0, 9);

	global.fly_emitter = part_emitter_create(global.fly_ps);
	global.fly_acc = 0;
}

function fireflies_update() {
	var _night = wildlife_night();

	// Over the bank, between the waterline and the bottom of the view. Wider
	// than the opening on both sides so they drift in from behind the posts
	// rather than appearing at the edge of the gap.
	part_emitter_region(global.fly_ps, global.fly_emitter,
		60, room_width - 60, 436, 596,
		ps_shape_rectangle, ps_distr_linear);

	if (_night <= 0.01) return;

	// Rate to hold FLY_COUNT of them in the air, from the mean life above.
	// Accumulated and spent whole, because a step's worth is a fraction of one
	// and rounding it every step would either double them or lose them.
	global.fly_acc += FLY_COUNT * _night / 85;

	var _n = floor(global.fly_acc);
	if (_n > 0) {
		global.fly_acc -= _n;
		part_emitter_burst(global.fly_ps, global.fly_emitter, global.fly_type, _n);
	}
}
