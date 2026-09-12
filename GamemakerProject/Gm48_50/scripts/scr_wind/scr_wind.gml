/// The wind, as one travelling gust.
///
/// One answer, shared, the same way sky_light() is one answer for the light.
/// The rain slants harder in it, the grass leans further, the trees quicken —
/// so a gust reads as one thing crossing the scene rather than as three
/// systems that happen to be moving at once. Weather that does not agree with
/// itself is the thing that makes a scene feel assembled.
///
/// Advanced once per step by obj_daylight, alongside the palette and the light,
/// so everything drawing this frame is working from the same gust.

function wind_init() {
	global.wind_time = 0;
	global.wind      = 0;
}

function wind_step() {
	// Real elapsed time, like every other clock here.
	global.wind_time += delta_time / 1000000;

	var _r = gmlmcp_tunable("wind_rate", 0.19);
	var _t = global.wind_time;

	// Two sines at a deliberately irrational ratio. A single one is a metronome
	// and a listener starts counting it; two that never line up give gusts that
	// arrive at times nobody can predict, which is the whole of what weather
	// sounds and looks like.
	var _a = sin(_t * _r);
	var _b = sin(_t * _r * 2.37 + 1.7);

	global.wind = clamp(_a * 0.7 + _b * 0.3, -1, 1);
}

/// The gust as a 0..1 magnitude, for anything that wants strength and not
/// direction. The prevailing direction of this storm is set per system — the
/// rain has always blown one way — and the gust only says how hard.
function wind_strength() {
	return 0.5 + 0.5 * global.wind;
}
