if (game_playing()) exit;

t += delta_time / 1000000;

// Any key, or any button. A title that names a particular key is asking to be
// read before the player has decided to read anything, and the answer to
// "press any key" has to actually be any key or the line is a lie.
// The fullscreen toggle is the one control available before the game begins,
// and it is locked out of this. A click that both resized the window and
// started the game would make the button unusable exactly where it is most
// wanted — the same rule the picker and the die follow on the board.
var _on_fs = fullscreen_at(mouse_x, mouse_y);

if (keyboard_check_pressed(vk_anykey) ||
    (mouse_check_button_pressed(mb_any) && !_on_fs)) {
	game_start();
}
