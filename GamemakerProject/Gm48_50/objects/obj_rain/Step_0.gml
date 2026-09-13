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

// The voice budget is earned over time, not per frame, so the plinks stay
// evenly spread instead of arriving in a clump every time a frame happens to
// land many drops. The cap allows a short burst without letting a quiet spell
// bank a flurry.
global.rain_voice_budget = min(
	global.rain_voice_budget + gmlmcp_tunable("audio_rate", 14) / game_get_speed(gamespeed_fps), 4);

// The field, and then the handful of landings picked out of it. Neither walks
// a list of drops any more: the particles are advanced by the runtime, and the
// audio asks the projection for landings directly rather than waiting to be
// told about them.
rain_particles_update();
rain_audio_sample();
