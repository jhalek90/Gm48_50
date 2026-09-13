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

/// A thing hanging in the wind.
///
/// Integrated rather than evaluated, and that is the whole point of it. A sine
/// shaped to look like a swing is always exactly in step with the wind driving
/// it, so the thing would reverse at the same instant the gust did. A pendulum
/// has somewhere to keep momentum: it lags going out, overshoots coming back,
/// and swings on after the air is still. That lag is the difference between
/// hanging and being animated.
///
/// It lives here, next to the gust, because it reads global.wind and because
/// the porch has more than one thing dangling off it now. Two copies of an
/// integrator is two places for the damping to drift apart.
///
/// `_stiff` is g over the length of the line, and so sets the period: bigger
/// is shorter and faster. `_damp` is deliberately low — a heavily damped
/// pendulum tracks the wind exactly and stops looking like it is hanging from
/// anything at all.
function pendulum_new() {
	return { ang: 0, vel: 0 };
}

function pendulum_step(_p, _max_deg, _stiff, _damp) {
	// Clamped, because the integration is explicit and a long frame — the
	// first one after a shader compiles, say — would otherwise hand it a step
	// big enough to throw the thing over the top of its own arc.
	var _dt  = min(0.05, delta_time / 1000000);
	var _max = degtorad(_max_deg);

	// The wind's push, scaled so a full-strength steady gust would hold it at
	// the maximum angle. Gusts overshoot it, which is correct.
	var _acc = (_max * _stiff * global.wind) - (_stiff * _p.ang) - (_damp * _p.vel);

	_p.vel += _acc * _dt;
	_p.ang += _p.vel * _dt;
}

/// How far a point `_drop` below the pivot is carried sideways by the swing.
function pendulum_offset(_p, _drop) {
	return sin(_p.ang) * _drop;
}
