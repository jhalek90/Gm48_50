lantern_step();
chime_step();

// Not while the title card is up: any click starts the game there, and a
// player who started it by clicking the lantern would arrive having already
// turned it off again.
if (!game_playing()) exit;

// The volume panel opens directly over the lantern's chain and the top of its
// glass, so it has to be locked out here or a click meant for a fader would
// blow the lamp out behind it.
if (mouse_check_button_pressed(mb_left) && !ui_claims(mouse_x, mouse_y) &&
    lantern_at(mouse_x, mouse_y)) {
	lantern_toggle();
}
