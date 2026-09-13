/// Adopt a time set from outside.
///
/// The clock is mirrored into the tunable registry every step so the live
/// bridge can read it. If what is in there is not what this object put there
/// last frame, something else wrote it — take that value rather than stamping
/// over it, so the slider and a change sent over the bridge cannot end up
/// disagreeing about what time it is. Same arrangement obj_rain uses for the
/// bed gain.
var _ext = gmlmcp_tunable("time_of_day", global.day_t);
if (_ext != sent) global.day_t = day_wrap(_ext);

// Not on the title card. Any key starts the game there, and a player who
// started it with T would arrive with the scrubber already hidden.
if (game_playing()) {
	if (keyboard_check_pressed(ord("T"))) show_ui = !show_ui;
	if (keyboard_check_pressed(ord("P"))) paused  = !paused;
}

// --- Scrubbing -----------------------------------------------------------
// A drag can only start on the bar, and the sequencer only acts on the frame a
// button goes down, so dragging the clock across the ledges cannot leave a
// trail of instruments behind it.
if (show_ui && game_playing()) {
	if (mouse_check_button_pressed(mb_left) && day_slider_hit(mouse_x, mouse_y)) {
		dragging = true;
	}
	if (!mouse_check_button(mb_left)) dragging = false;
	if (dragging) global.day_t = day_slider_t(mouse_x);
} else {
	dragging = false;
}

// --- The clock -----------------------------------------------------------
// Advanced on real elapsed time rather than frames, for the reason the
// sequencer's clock is: a dropped frame should cost the cycle nothing. Held
// still while dragging, so the scrub does not fight the cycle for the handle.
if (!paused && !dragging) {
	// Defaulted from the music rather than from a round number: a phase lasts
	// exactly one track, so the sky finishes changing as the piece finishes.
	var _secs = max(1, gmlmcp_tunable("day_secs", music_cycle_secs()));

	// The elapsed time is floored at zero before it is added. The wrap turns any
	// negative step into a jump most of the way round the clock, so a single odd
	// frame at dawn does not read as a sudden cut to the middle of the night.
	var _dt = max(0, delta_time) / 1000000;
	global.day_t = day_wrap(global.day_t + _dt / _secs);
}

// Blended once per step rather than once per draw: several draw events read
// the palette and they all have to be looking at the same instant.
daylight_apply();

// The gust, advanced once alongside the palette so the rain, the grass and the
// trees are all leaning on the same instant of the same wind.
wind_step();

// The scene's key light, resolved once alongside the palette. The porch, the
// shadows and the light shafts all read this, and they have to be lit from the
// same instant the colours were blended for.
global.light = sky_light();

// The rhythm track for this phase, faded and handed over on the beat.
music_step();

global.gmlmcp_tunables[$ "time_of_day"] = global.day_t;
sent = global.day_t;
