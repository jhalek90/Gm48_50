/// The porch timber.
///
/// The shader does the looking; this file only hands it the numbers, the same
/// split scr_water, scr_sky and scr_grass use. A member is a rectangle, a
/// palette tone and a grain direction, and every piece of the porch is one
/// call — so a roof, a post and a rail cannot end up looking like three
/// different materials.
///
/// Opened and closed around the whole porch rather than per piece. There are
/// seventeen balusters alone, and setting and resetting the shader for each of
/// them would mean twenty-five state changes a frame to draw one fence.

/// Grain runs the length of the member. Named rather than passed as 0 and 1,
/// because a bare number at a call site tells the next reader nothing.
#macro GRAIN_ALONG_X 0
#macro GRAIN_ALONG_Y 1

/// Cache the uniform handles.
function wood_init() {
	global.wood_u = {
		rect:   shader_get_uniform(shd_wood, "u_rect"),
		base:   shader_get_uniform(shd_wood, "u_base"),
		dir:    shader_get_uniform(shd_wood, "u_dir"),
		plank:  shader_get_uniform(shd_wood, "u_plank"),
		seed:   shader_get_uniform(shd_wood, "u_seed"),
		pixel:  shader_get_uniform(shd_wood, "u_pixel"),
		levels: shader_get_uniform(shd_wood, "u_levels"),
		grain:  shader_get_uniform(shd_wood, "u_grain"),
		relief: shader_get_uniform(shd_wood, "u_relief"),
		light:  shader_get_uniform(shd_wood, "u_light"),
		key:    shader_get_uniform(shd_wood, "u_key"),
	};
}

/// Start drawing timber. Sets the uniforms every piece shares.
function wood_begin() {
	var _u = global.wood_u;

	shader_set(shd_wood);

	shader_set_uniform_f(_u.pixel,  max(1, gmlmcp_tunable("wood_pixel",  4)));
	shader_set_uniform_f(_u.levels, max(2, gmlmcp_tunable("wood_levels", 7)));
	shader_set_uniform_f(_u.grain,  gmlmcp_tunable("wood_grain",  0.30));
	shader_set_uniform_f(_u.relief, gmlmcp_tunable("wood_relief", 0.20));

	// Lit from the scene key rather than from a fixed corner, so the posts
	// change which side they catch as the day goes round. Floored well above
	// zero: at night the light is weak but the timber still has to have form,
	// and relief that falls to nothing turns the porch back into flat shapes.
	var _l = global.light;
	shader_set_uniform_f_array(_u.light, [_l.x, _l.y]);
	shader_set_uniform_f(_u.key, 0.4 + 0.6 * _l.strength);

	// Drawn white: the shader multiplies by the vertex colour, so anything else
	// here would tint the palette tone it was just handed.
	draw_set_colour(c_white);
	draw_set_alpha(1);
}

/// One piece of timber.
///
/// _plank is the board width across the grain. Passing the width of the member itself
/// makes it a single board, which is what a rail or a baluster is; passing
/// less divides it into boards, which is what a roof and a floor are.
function wood_piece(_x1, _y1, _x2, _y2, _colour, _dir, _plank, _seed) {
	var _u = global.wood_u;

	shader_set_uniform_f_array(_u.rect, [_x1, _y1, _x2, _y2]);
	shader_set_uniform_f_array(_u.base, colour_vec3(_colour));

	shader_set_uniform_f(_u.dir,   _dir);
	shader_set_uniform_f(_u.plank, max(2, _plank));
	shader_set_uniform_f(_u.seed,  _seed);

	draw_rectangle(_x1, _y1, _x2, _y2, false);
}

function wood_end() {
	shader_reset();
}
