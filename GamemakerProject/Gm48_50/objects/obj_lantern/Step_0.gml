lantern_step();

// Not while the title card is up: any click starts the game there, and a
// player who started it by clicking the lantern would arrive having already
// turned it off again.
if (!game_playing()) exit;

if (mouse_check_button_pressed(mb_left) && lantern_at(mouse_x, mouse_y)) {
	lantern_toggle();
}
