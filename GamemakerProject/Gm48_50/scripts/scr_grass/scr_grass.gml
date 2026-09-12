/// The grass on the near bank.
///
/// The shader does the looking; this file only hands it the numbers — the same
/// split scr_water and scr_sky use. The one piece of real arithmetic here is
/// the row spacing, and it belongs on this side because it is a consequence of
/// the blade length, not a look control someone should be dragging.

/// Cache the uniform handles.
function grass_init() {
	global.grass_u = {
		time:       shader_get_uniform(shd_grass, "u_time"),
		horizon:    shader_get_uniform(shd_grass, "u_horizon"),
		ground_k:   shader_get_uniform(shd_grass, "u_ground_k"),
		z_near:     shader_get_uniform(shd_grass, "u_z_near"),
		centre:     shader_get_uniform(shd_grass, "u_centre"),
		edge:       shader_get_uniform(shd_grass, "u_edge"),
		bank:       shader_get_uniform(shd_grass, "u_bank"),
		grass:      shader_get_uniform(shd_grass, "u_grass"),
		grass_lit:  shader_get_uniform(shd_grass, "u_grass_lit"),
		pixel:      shader_get_uniform(shd_grass, "u_pixel"),
		levels:     shader_get_uniform(shd_grass, "u_levels"),
		blade_w:    shader_get_uniform(shd_grass, "u_blade_w"),
		blade_len:  shader_get_uniform(shd_grass, "u_blade_len"),
		rstep:      shader_get_uniform(shd_grass, "u_rstep"),
		wind_amp:   shader_get_uniform(shd_grass, "u_wind_amp"),
		wind_freq:  shader_get_uniform(shd_grass, "u_wind_freq"),
		wind_speed: shader_get_uniform(shd_grass, "u_wind_speed"),
		gust:       shader_get_uniform(shd_grass, "u_gust"),
	};

	// Started at zero rather than read off current_time, for the reason the
	// water and the cloud both are: a float counting milliseconds since boot
	// loses its precision inside a sin() and the motion visibly quantises.
	global.grass_time = 0;
}

/// The tallest a blade gets at a given ground row, in screen pixels.
///
/// Used to work out how far above the waterline the draw has to start. The
/// 1.45 is the top of the per-blade length spread in the shader; it is written
/// here as well because the rectangle has to contain the blades, and a
/// rectangle that is an inch too short crops every tip on the bank.
function grass_reach_px(_y, _blade_len) {
	var _q  = max(_y - global.persp_horizon, 1);
	var _sc = global.persp_z_near * _q / global.persp_ground_k;
	return _blade_len * _sc * 1.45;
}

/// Draw the bank, from the waterline at depth _edge_z down to the bottom.
function grass_draw(_edge_z) {
	// Real elapsed time, so the wind blows at the same speed whatever the frame
	// rate is doing.
	global.grass_time += delta_time / 1000000;

	var _u = global.grass_u;

	var _blade_len = gmlmcp_tunable("blade_len", 46);
	var _blade_w   = gmlmcp_tunable("blade_w",    7);

	// How far back up the depth axis a blade can reach, as a fraction. This
	// falls straight out of the projection: a blade of this length at the near
	// plane spans this share of the 1/z curve at every distance, which is why
	// the shader can find its candidate rows in closed form instead of
	// searching for them.
	var _reach = clamp(_blade_len * global.persp_z_near / global.persp_ground_k, 0.02, 0.6);

	// Rows spaced so that exactly two of them fall inside that reach. The
	// shader checks three, which then covers the range at every distance with
	// no per-depth special case and no wasted lookups.
	var _rstep = power(1 / (1 - _reach), 0.5);

	var _edge = ground_y(_edge_z);

	shader_set(shd_grass);

	shader_set_uniform_f(_u.time,     global.grass_time);
	shader_set_uniform_f(_u.horizon,  global.persp_horizon);
	shader_set_uniform_f(_u.ground_k, global.persp_ground_k);
	shader_set_uniform_f(_u.z_near,   global.persp_z_near);
	shader_set_uniform_f(_u.centre,   room_width * 0.5);
	shader_set_uniform_f(_u.edge,     _edge);

	shader_set_uniform_f_array(_u.bank,      colour_vec3(global.pal.bank));
	shader_set_uniform_f_array(_u.grass,     colour_vec3(global.pal.grass));
	shader_set_uniform_f_array(_u.grass_lit, colour_vec3(global.pal.grass_lit));

	shader_set_uniform_f(_u.pixel,      max(1, gmlmcp_tunable("grass_pixel",  4)));
	shader_set_uniform_f(_u.levels,     max(2, gmlmcp_tunable("grass_levels", 5)));
	shader_set_uniform_f(_u.blade_w,    _blade_w);
	shader_set_uniform_f(_u.blade_len,  _blade_len);
	shader_set_uniform_f(_u.rstep,      _rstep);
	shader_set_uniform_f(_u.wind_amp,   gmlmcp_tunable("wind_amp",   1.2));
	shader_set_uniform_f(_u.wind_freq,  gmlmcp_tunable("wind_freq",  0.015));
	shader_set_uniform_f(_u.wind_speed, gmlmcp_tunable("wind_speed", 0.9));

	// How hard the shared gust is blowing right now. Floored well above zero so
	// the bank never goes completely still: grass in a rainstorm is never
	// standing to attention, and a field that stops dead reads as broken.
	shader_set_uniform_f(_u.gust, 0.45 + 0.8 * wind_strength());

	// Started above the waterline so blades rooted on the front row can stand
	// proud of it. The shader leaves everything above the line transparent
	// except the blades themselves, which is what makes the bank meet the lake
	// as a ragged edge rather than as a ruled one.
	var _top = _edge - grass_reach_px(_edge, _blade_len) - 2;

	// Drawn white: the shader multiplies by the vertex colour, so anything else
	// here would tint the palette it was just handed.
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_rectangle(0, _top, room_width, room_height, false);

	shader_reset();
}
