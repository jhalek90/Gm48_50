/// Draw the rain.
///
/// The bulk of the field goes out as a single line-list primitive with
/// per-vertex alpha: several thousand tapered streaks for one draw call, and
/// each streak's tail fades to nothing instead of ending in a hard stop, which
/// is what sells it as motion blur rather than a stick.
///
/// One pass, not two. The nearest streaks need real width — a 1px line cannot
/// carry a drop that is meant to be an arm's length from your face — but they
/// cannot be drawn inside a primitive block, so they are set aside as they are
/// met and stroked afterwards. Walking the field a second time to find them
/// cost about ten frames a second in a heavy downpour.
var _speed  = gmlmcp_tunable("rain_speed", 30);
var _wind   = gmlmcp_tunable("rain_wind",  -4);
var _streak = gmlmcp_tunable("rain_streak", 62);
var _a_near = gmlmcp_tunable("rain_alpha_near", 0.80);
var _a_far  = gmlmcp_tunable("rain_alpha_far",  0.24);
var _col    = global.pal.rain;

// The velocity direction is the same for every drop — only its length changes
// with depth — so the unit vector is worth computing once rather than 5000
// times with a square root each.
var _m  = max(0.0001, point_distance(0, 0, _wind, _speed));
var _dx = _wind / _m;
var _dy = _speed / _m;

var _fat = [];
var _fat_n = 0;

draw_primitive_begin(pr_linelist);
for (var _i = 0, _n = array_length(drops); _i < _n; _i++) {
	var _d = drops[_i];
	var _s = global.persp_z_near / _d.z;

	// The streak lies along the drop's own velocity, so wind tilts the rain
	// instead of leaving vertical streaks drifting sideways.
	var _len = _streak * _s;
	var _ux = _dx * _len;
	var _uy = _dy * _len;

	// Distance washes the rain out — far drops read as haze, near ones as lines.
	var _a = lerp(_a_far, _a_near, _s);
	draw_vertex_colour(_d.x, _d.y, _col, _a);
	draw_vertex_colour(_d.x - _ux, _d.y - _uy, _col, _a * 0.06);

	if (_s >= 0.55) {
		_fat[_fat_n++] = [_d.x, _d.y, _d.x - _ux, _d.y - _uy, _a * 0.55];
	}
}
draw_primitive_end();

draw_set_colour(_col);
for (var _i = 0; _i < _fat_n; _i++) {
	var _f = _fat[_i];
	draw_set_alpha(_f[4]);
	draw_line_width(_f[0], _f[1], _f[2], _f[3], 2);
}
draw_set_alpha(1);

// Splashes out in the scene. The railing's own splashes are drawn by
// obj_rain_front, in front of the railing they are sitting on.
rain_draw_splashes(false);
