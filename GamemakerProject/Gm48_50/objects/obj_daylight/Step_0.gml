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
	if (keyboard_check_pressed(ord("T"))) ui_toggle();

	// P still works. The line of help that advertised it went with the clock
	// bar, but a key that costs nothing to keep is not worth taking away from
	// the hands that already know it.
	if (keyboard_check_pressed(ord("P"))) day_pause_toggle();

	// And the button, which is what the key is for now. Tested before the sky
	// below so a click on it cannot also start a drag — the two do not overlap
	// today, the button being up under the roof and the sky starting below it,
	// but that was true of the picker and the ledges as well.
	if (ui_shown() && !ui_claims(mouse_x, mouse_y) &&
	    mouse_check_button_pressed(mb_left) && day_pause_at(mouse_x, mouse_y)) {
		day_pause_toggle();
	}
}

// --- Scrubbing -----------------------------------------------------------
// A drag can only start on the bar, and the sequencer only acts on the frame a
// button goes down, so dragging the clock across the ledges cannot leave a
// trail of instruments behind it.
if (day_ui_shown() && game_playing()) {
	if (mouse_check_button_pressed(mb_left) && day_slider_hit(mouse_x, mouse_y)) {
		dragging = true;
	}
	if (!mouse_check_button(mb_left)) dragging = false;
	if (dragging) global.day_t = day_slider_t(mouse_x);
} else {
	dragging = false;
}

// --- Dragging the sky ----------------------------------------------------
//
// The other way to scrub, and the one a player is meant to find. No widget: you
// take hold of the sky between the posts and pull, and the sun tracks your hand
// exactly, because sky_drag_days is derived from where sky_body puts it rather
// than picked to feel right.
//
// Held here beside the scrubber instead of in an object of its own, because the
// two do the same job to the same variable and putting them in different files
// is how they would end up fighting over it. The bar wins ties — it is a
// deliberate grab at a small target, where the sky is most of the screen.
//
// Three things are locked out of it. The lantern hangs in the middle of that
// window and is a click, not a drag. The volume panel opens across the top
// right of it and owns every click while it is up. And the title card is not
// the place: any click there starts the game, and a player who began by
// dragging the sky would arrive having scrubbed it.
if (game_playing()) {
	if (mouse_check_button_pressed(mb_left) && !dragging &&
	    !ui_claims(mouse_x, mouse_y) && !day_pause_at(mouse_x, mouse_y) &&
	    !lantern_at(mouse_x, mouse_y) && sky_at(mouse_x, mouse_y)) {
		sky_drag = true;
		sky_mx   = mouse_x;
	}
} else {
	sky_drag = false;
}

if (!mouse_check_button(mb_left)) sky_drag = false;

if (sky_drag) {
	// Measured against the last frame rather than against where the grab
	// started, so letting the pointer leave the sky mid-drag costs nothing —
	// you can carry the sun up over the roof and back without the clock
	// snapping to wherever the cursor happens to re-enter.
	global.day_t = day_wrap(global.day_t + sky_drag_days(mouse_x - sky_mx));
	sky_mx = mouse_x;
}

// --- The clock -----------------------------------------------------------
// Advanced on real elapsed time rather than frames, for the reason the
// sequencer's clock is: a dropped frame should cost the cycle nothing. Held
// still while dragging, so the scrub does not fight the cycle for the handle.
if (!day_paused() && !dragging && !sky_drag) {
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

toast_step();
