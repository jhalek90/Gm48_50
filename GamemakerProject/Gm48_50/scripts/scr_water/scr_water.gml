/// The lake surface.
///
/// The shader does the looking; this file only hands it the numbers. Every
/// uniform it needs is something the game already knows — the projection from
/// scr_perspective, the colours from the day/night table — so the water cannot
/// disagree with the scene about where the ground is or what hour it is. The
/// alternative, constants baked into the .fsh, means editing a shader every
/// time the horizon moves.

/// Cache the uniform handles.
///
/// Looked up once rather than per frame: shader_get_uniform is a string lookup
/// into the compiled program, and there are fourteen of them on a draw that
/// happens sixty times a second.
function water_init() {
	global.water_u = {
		time:     shader_get_uniform(shd_water, "u_time"),
		horizon:  shader_get_uniform(shd_water, "u_horizon"),
		ground_k: shader_get_uniform(shd_water, "u_ground_k"),
		z_far:    shader_get_uniform(shd_water, "u_z_far"),
		bottom:   shader_get_uniform(shd_water, "u_bottom"),
		centre:   shader_get_uniform(shd_water, "u_centre"),
		far:      shader_get_uniform(shd_water, "u_far"),
		near:     shader_get_uniform(shd_water, "u_near"),
		glint:    shader_get_uniform(shd_water, "u_glint"),
		pixel:    shader_get_uniform(shd_water, "u_pixel"),
		levels:   shader_get_uniform(shd_water, "u_levels"),
		scale:    shader_get_uniform(shd_water, "u_scale"),
		speed:    shader_get_uniform(shd_water, "u_speed"),
		stretch:  shader_get_uniform(shd_water, "u_stretch"),
	};

	// The shader's own clock. Kept here rather than read from current_time so
	// it starts at zero: a float that has been counting milliseconds since the
	// machine booted loses its precision inside a sin(), and the wave field
	// visibly quantises.
	global.water_time = 0;
}

/// A palette colour as the vec3 a shader wants.
function colour_vec3(_c) {
	return [
		colour_get_red(_c)   / 255,
		colour_get_green(_c) / 255,
		colour_get_blue(_c)  / 255,
	];
}

/// Reflect a bottom-origin sprite into the water below the horizon.
///
/// Only things standing BEYOND the water reflect into it. A mirror lying in a
/// receding plane throws its image toward the viewer from the waterline, so
/// something on the near bank would reflect onto the bank rather than into the
/// lake. That is why the far range reflects and the trees standing in front of
/// it do not, and it is geometry rather than a choice.
///
/// Drawn as strips rather than as one flipped sprite, because the image has to
/// lose strength as it comes toward the viewer and has to wander with the
/// surface it is lying on. One flipped draw is a mirror, and water is not.
function water_reflect(_spr, _x, _horizon, _colour, _alpha) {
	var _w    = sprite_get_width(_spr);
	var _sh   = sprite_get_height(_spr);
	var _step = max(2, gmlmcp_tunable("reflect_step",    8));
	var _wob  = gmlmcp_tunable("reflect_wobble",  3.5);
	var _fall = gmlmcp_tunable("reflect_falloff", 0.88);

	for (var _s = 0; _s < _sh; _s += _step) {
		// Sprite row _s sits (_sh - _s) above the horizon, so its reflection
		// sits the same distance below it.
		var _up = _sh - _s;
		var _y  = _horizon + _up;

		// 0 at the horizon, 1 at the near end. Reflections fade as they come
		// toward the viewer: more of the surface between you and the image is
		// scattering, and at a grazing angle almost none of it is a mirror.
		var _t = _up / _sh;
		var _a = _alpha * (1 - _fall * _t);
		if (_a <= 0.01) continue;

		// The surface is not flat, so the image is not straight. Driven by the
		// same clock the waves are, so the wobble and the water agree about
		// which way the lake is moving.
		var _dx = sin(global.water_time * 1.7 + _s * 0.09) * _wob * (0.35 + _t);

		draw_sprite_part_ext(_spr, 0, 0, _s, _w, _step, _x + _dx, _y, 1, -1, _colour, _a);
	}
}

/// Draw the lake between two screen rows.
function water_draw(_y1, _y2) {
	// Real elapsed time, like every other clock in the project, so the waves
	// roll at the same speed whatever the frame rate is doing.
	global.water_time += delta_time / 1000000;

	var _u = global.water_u;
	shader_set(shd_water);

	shader_set_uniform_f(_u.time,     global.water_time);
	shader_set_uniform_f(_u.horizon,  global.persp_horizon);
	shader_set_uniform_f(_u.ground_k, global.persp_ground_k);
	shader_set_uniform_f(_u.z_far,    global.persp_z_far);
	shader_set_uniform_f(_u.bottom,   _y2);
	shader_set_uniform_f(_u.centre,   room_width * 0.5);

	// Far water, near water, and the sky it reflects.
	shader_set_uniform_f_array(_u.far,   colour_vec3(global.pal.water));
	shader_set_uniform_f_array(_u.near,  colour_vec3(global.pal.water_near));
	shader_set_uniform_f_array(_u.glint, colour_vec3(global.pal.sky_warm));

	shader_set_uniform_f(_u.pixel,   max(1, gmlmcp_tunable("water_pixel",   4)));
	shader_set_uniform_f(_u.levels,  max(2, gmlmcp_tunable("water_levels",  5)));
	shader_set_uniform_f(_u.scale,   gmlmcp_tunable("water_scale",   1.0));
	shader_set_uniform_f(_u.speed,   gmlmcp_tunable("water_speed",   0.6));
	shader_set_uniform_f(_u.stretch, gmlmcp_tunable("water_stretch", 1.0));

	// Drawn white: the shader multiplies by the vertex colour, so anything
	// else here would tint the palette it was just handed.
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_rectangle(0, _y1, room_width, _y2, false);

	shader_reset();
}
