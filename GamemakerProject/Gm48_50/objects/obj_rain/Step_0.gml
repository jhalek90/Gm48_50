/// Read the live tunables once per step and cache them.
///
/// Reading them here rather than inside the per-drop loop means the whole rain
/// system stays adjustable from outside while the game runs, without paying a
/// registry lookup a couple of thousand times a frame.
global.persp_horizon   = gmlmcp_tunable("horizon",     300);
global.persp_ground_k  = gmlmcp_tunable("ground_k",    520);
global.persp_cloud_k   = gmlmcp_tunable("cloud_k",     900);
global.persp_z_near    = gmlmcp_tunable("z_near",      1.7);
global.persp_z_far     = gmlmcp_tunable("z_far",       36);
global.rain_depth_bias = gmlmcp_tunable("depth_bias",  1.0);

global.rain_audio_gain  = gmlmcp_tunable("audio_gain",  0.55);
global.rain_audio_pan   = gmlmcp_tunable("audio_pan",   0.55);
global.rain_audio_depth = gmlmcp_tunable("audio_depth", 34);
global.rain_audio_reach = gmlmcp_tunable("audio_reach", 1.4);
global.rain_bed_gain    = gmlmcp_tunable("bed_gain",    0.45);
global.rain_bed_track   = gmlmcp_tunable("bed_track",   0);

// Up and down nudge the bed level, for mixing it against the drops by ear.
// The new value is written back into the tunable registry rather than kept
// beside it, so a key press and a change sent over the live bridge cannot
// end up disagreeing about the current level.
var _nudge = keyboard_check_pressed(vk_up) - keyboard_check_pressed(vk_down);
if (_nudge != 0) {
	global.rain_bed_gain = clamp(global.rain_bed_gain + _nudge * 0.1, 0, 1);
	global.gmlmcp_tunables[$ "bed_gain"] = global.rain_bed_gain;
}

rain_bed_update();

var _want  = gmlmcp_tunable("rain_count", 2000);
var _speed = gmlmcp_tunable("rain_speed", 30);
var _wind  = gmlmcp_tunable("rain_wind",  -4);
var _life  = gmlmcp_tunable("splash_life", 18);
var _rate  = gmlmcp_tunable("audio_rate", 14);

// Voices are earned over time, not per frame, so the plinks stay evenly spread
// instead of arriving in a clump every time a frame happens to land many drops.
// The cap allows a short burst without letting a quiet spell bank a flurry.
global.rain_voice_budget = min(global.rain_voice_budget + _rate / game_get_speed(gamespeed_fps), 4);

// Match the field to the live count, seeding new drops mid-fall so turning the
// rain up does not show as a visible band of drops entering together.
while (array_length(drops) < _want) array_push(drops, rain_new_drop(true));
while (array_length(drops) > _want) array_pop(drops);

for (var _i = 0, _n = array_length(drops); _i < _n; _i++) {
	var _d = drops[_i];
	var _s = persp_scale(_d.z);

	// Both axes scale with depth, so near rain sweeps and far rain crawls from
	// one set of numbers, and the wind shears the whole field consistently.
	_d.y += _speed * _s;
	_d.x += _wind * _s;

	if (_d.y >= _d.land) {
		rain_add_splash(_d.x, _d.land, _s, _d.kind);
		rain_audio_hit(_d.x, _d.land, _d.z, _s, _d.kind);
		drops[_i] = rain_new_drop(false);
	}
}

var _sp = global.rain_splashes;
for (var _i = array_length(_sp) - 1; _i >= 0; _i--) {
	_sp[_i].t += 1;
	if (_sp[_i].t >= _life) array_delete(_sp, _i, 1);
}
