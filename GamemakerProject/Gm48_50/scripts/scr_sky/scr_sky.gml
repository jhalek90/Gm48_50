/// The sky: two lights on an arc, and a ceiling of cloud.
///
/// The shader does the looking; this file only hands it the numbers — the same
/// split scr_water uses. Every uniform is something the game already knows: the
/// projection from scr_perspective, the colours from the day/night table, and
/// the hour from the same clock the scrubber drives. So the sky cannot disagree
/// with the scene about where the horizon is, what time it is, or what colour
/// the weather is today.
///
/// Where the sun is lives here rather than in the .fsh on purpose. It is a fact
/// about the world, not about how the sky is painted, and the porch lighting
/// and the water glints will both want to ask for it later.

/// Cache the uniform handles.
///
/// Looked up once rather than per frame: shader_get_uniform is a string lookup
/// into the compiled program, and there are twenty-four of them on a draw that
/// happens sixty times a second.
function sky_init() {
	global.sky_u = {
		time:      shader_get_uniform(shd_sky, "u_time"),
		horizon:   shader_get_uniform(shd_sky, "u_horizon"),
		cloud_k:   shader_get_uniform(shd_sky, "u_cloud_k"),
		z_far:     shader_get_uniform(shd_sky, "u_z_far"),
		centre:    shader_get_uniform(shd_sky, "u_centre"),
		top:       shader_get_uniform(shd_sky, "u_top"),
		mid:       shader_get_uniform(shd_sky, "u_mid"),
		warm:      shader_get_uniform(shd_sky, "u_warm"),
		cloud:     shader_get_uniform(shd_sky, "u_cloud"),
		cloud_lit: shader_get_uniform(shd_sky, "u_cloud_lit"),
		sun:       shader_get_uniform(shd_sky, "u_sun"),
		moon:      shader_get_uniform(shd_sky, "u_moon"),
		sun_col:   shader_get_uniform(shd_sky, "u_sun_col"),
		moon_col:  shader_get_uniform(shd_sky, "u_moon_col"),
		sun_r:     shader_get_uniform(shd_sky, "u_sun_r"),
		moon_r:    shader_get_uniform(shd_sky, "u_moon_r"),
		glow:      shader_get_uniform(shd_sky, "u_glow"),
		light:     shader_get_uniform(shd_sky, "u_light"),
		pixel:     shader_get_uniform(shd_sky, "u_pixel"),
		levels:    shader_get_uniform(shd_sky, "u_levels"),
		sky_bands: shader_get_uniform(shd_sky, "u_sky_bands"),
		scale:     shader_get_uniform(shd_sky, "u_scale"),
		speed:     shader_get_uniform(shd_sky, "u_speed"),
		stretch:   shader_get_uniform(shd_sky, "u_stretch"),
		cover:     shader_get_uniform(shd_sky, "u_cover"),
		soft:      shader_get_uniform(shd_sky, "u_soft"),
		march:     shader_get_uniform(shd_sky, "u_march"),
	};

	// The cloud's own clock, kept here rather than read from current_time so it
	// starts at zero — a float that has been counting milliseconds since the
	// machine booted loses its precision inside a sin(), and the field visibly
	// quantises. Same reasoning as global.water_time.
	global.sky_time = 0;
}

/// The hour the scene is at, 0 to 24.
///
/// The clock the scrubber drives is a fraction of a cycle; this is that same
/// value said in hours, so the celestial arc below can be written in the units
/// a person thinks in rather than in twelfths of a phase.
function sky_hour() {
	return (DAY_START_HOUR + day_wrap(global.day_t) * 24) mod 24;
}

/// Where a body at this hour sits on the sky, and how visible it is.
///
/// Rise at 06:00, peak at noon, set at 18:00. The height is a sine of the
/// progress through that half of the clock and the horizontal sweep is linear,
/// which is the shape the real thing traces: quick through the middle of the
/// sky in height, even in azimuth. Below the horizon the sine simply goes
/// negative and the visibility ramp takes the body away, so there is no
/// separate "is it up" branch anywhere.
function sky_body(_hour) {
	var _u   = (_hour - 6) / 12;
	var _alt = sin(_u * pi);
	// The arc is scaled to the gap between the roof and the horizon, not to the
	// whole sky. The porch overhang owns the top 112 pixels of the screen, and an
	// arc sized to the full height parks both bodies behind it for the middle
	// third of the day — which does not read as a porch roof, it reads as a sun
	// that is broken.
	var _arc = global.persp_horizon * gmlmcp_tunable("sky_arc", 0.5);

	return {
		x:   room_width * _u,
		y:   global.persp_horizon - _alt * _arc,
		alt: _alt,

		// Faded across the horizon rather than switched, so neither body pops
		// on. The ramp starts slightly below zero so the glow has already gone
		// by the time the disc would be clipping through the far shore.
		vis: clamp((_alt + 0.06) / 0.14, 0, 1),
	};
}

/// The sun, and the moon opposite it.
///
/// The moon is the sun twelve hours away rather than a second arc with its own
/// numbers. One body model means they cannot drift out of opposition, and the
/// handover at dawn happens because the arithmetic says so.
function sky_sun() {
	return sky_body(sky_hour());
}

function sky_moon() {
	return sky_body((sky_hour() + 12) mod 24);
}

/// Where the light in this scene comes from, and how strong a key it is.
///
/// One answer, shared. The sky shades its clouds with it, the porch turns its
/// lit edges toward it, the trees and the instruments drop their shadows away
/// from it, and the post pass throws its shafts out of it. Four consumers each
/// working from a private copy of where the sun is, is how a scene ends up lit
/// from two directions at once and nobody can say which one is wrong.
///
/// Cached into global.light once per step by obj_daylight, next to the palette
/// and for the same reason: everything drawing this frame has to be looking at
/// the same instant.
function sky_light() {
	var _sun  = sky_sun();
	var _moon = sky_moon();

	// The moon is a key too, but a far weaker one. Shadows at night want to be
	// present and soft rather than absent, which is what the second weight is
	// for.
	var _sw = _sun.vis;
	var _mw = _moon.vis * 0.3;

	// Position comes from whichever body is actually lighting the scene, not
	// from an average of the two.
	//
	// Averaging reads as the careful thing to do and is wrong. At dawn the two
	// bodies sit at opposite ends of the sky, so the blend lands in the middle
	// — the one place neither light is — and everything downstream is lit from
	// a sun that is not there. It showed up as the porch posts refusing to
	// change which side they caught, all the way through sunrise.
	//
	// The handover is a jump. That is fine: it happens when both bodies are on
	// the horizon and the key is at its weakest, so there is nothing to see.
	var _b = (_sw >= _mw) ? _sun : _moon;

	return {
		x: _b.x,
		y: _b.y,

		strength: max(_sw, _mw),

		// Altitude of whichever body is up, for shadow length. Only one of them
		// is ever above the horizon, so the larger is the one that matters.
		alt: max(_sun.alt, _moon.alt),

		sun_vis: _sun.vis,
	};
}

/// Draw the sky between two screen rows.
function sky_draw(_y1, _y2) {
	// Real elapsed time, like every other clock in the project, so the cloud
	// drifts at the same speed whatever the frame rate is doing.
	global.sky_time += delta_time / 1000000;

	var _u    = global.sky_u;
	var _sun  = sky_sun();
	var _moon = sky_moon();

	shader_set(shd_sky);

	shader_set_uniform_f(_u.time,    global.sky_time);
	shader_set_uniform_f(_u.horizon, global.persp_horizon);
	shader_set_uniform_f(_u.cloud_k, global.persp_cloud_k);
	shader_set_uniform_f(_u.z_far,   global.persp_z_far);
	shader_set_uniform_f(_u.centre,  room_width * 0.5);

	shader_set_uniform_f_array(_u.top,       colour_vec3(global.pal.sky_top));
	shader_set_uniform_f_array(_u.mid,       colour_vec3(global.pal.sky_mid));
	shader_set_uniform_f_array(_u.warm,      colour_vec3(global.pal.sky_warm));
	shader_set_uniform_f_array(_u.cloud,     colour_vec3(global.pal.cloud));
	shader_set_uniform_f_array(_u.cloud_lit, colour_vec3(global.pal.cloud_lit));

	shader_set_uniform_f_array(_u.sun,      [_sun.x,  _sun.y,  _sun.vis]);
	shader_set_uniform_f_array(_u.moon,     [_moon.x, _moon.y, _moon.vis]);
	shader_set_uniform_f_array(_u.sun_col,  colour_vec3(global.pal.sun));
	shader_set_uniform_f_array(_u.moon_col, colour_vec3(global.pal.moon));

	shader_set_uniform_f(_u.sun_r,  gmlmcp_tunable("sun_size",  26));
	shader_set_uniform_f(_u.moon_r, gmlmcp_tunable("moon_size", 20));
	shader_set_uniform_f(_u.glow,   gmlmcp_tunable("sky_glow",   4));

	// Whichever body is up lights the cloud, from the one shared answer rather
	// than from a copy of the crossfade kept here.
	var _l = sky_light();
	shader_set_uniform_f_array(_u.light, [_l.x, _l.y]);

	shader_set_uniform_f(_u.pixel,     max(1, gmlmcp_tunable("sky_pixel",   4)));
	shader_set_uniform_f(_u.levels,    max(2, gmlmcp_tunable("sky_levels",  5)));
	shader_set_uniform_f(_u.sky_bands, max(2, gmlmcp_tunable("sky_bands",  14)));
	shader_set_uniform_f(_u.scale,     gmlmcp_tunable("cloud_scale",   1.0));
	shader_set_uniform_f(_u.speed,     gmlmcp_tunable("cloud_speed",   0.16));
	shader_set_uniform_f(_u.stretch,   gmlmcp_tunable("cloud_stretch", 1.0));
	shader_set_uniform_f(_u.cover,     gmlmcp_tunable("cloud_cover",   0.55));
	shader_set_uniform_f(_u.soft,      gmlmcp_tunable("cloud_soft",    0.12));
	shader_set_uniform_f(_u.march,     gmlmcp_tunable("cloud_march",    14));

	// Drawn white: the shader multiplies by the vertex colour, so anything else
	// here would tint the palette it was just handed.
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_rectangle(0, _y1, room_width, _y2, false);

	shader_reset();
}
