if (game_playing()) exit;

t += delta_time / 1000000;

// Any key, or any button. A title that names a particular key is asking to be
// read before the player has decided to read anything, and the answer to
// "press any key" has to actually be any key or the line is a lie.
if (keyboard_check_pressed(vk_anykey) || mouse_check_button_pressed(mb_any)) {
	game_start();
}
