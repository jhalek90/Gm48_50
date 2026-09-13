if (game_playing()) exit;

t += delta_time / 1000000;

// The gate takes a click and nothing else. A keypress is not a gesture every
// browser accepts for starting audio, and this screen exists for exactly that
// gesture. It also swallows the click rather than passing it through, or the
// same press would open the gate and start the game in one go, and the title
// card would never be seen.
if (audio_gated()) {
	if (mouse_check_button_pressed(mb_left)) audio_ungate();
	exit;
}

// Any key, or any button. A title that names a particular key is asking to be
// read before the player has decided to read anything, and the answer to
// "press any key" has to actually be any key or the line is a lie.
// The fullscreen toggle and the volume are the two controls available before
// the game begins, and both are locked out of this. A click that both resized
// the window and started the game would make the button unusable exactly where
// it is most wanted — the same rule the picker and the die follow on the board.
//
// Keys are not locked out, only clicks: the faders are dragged and the buttons
// are pressed, so nothing up there is waiting on a keystroke, and "press any
// key" has to keep meaning any key.
var _taken = fullscreen_at(mouse_x, mouse_y) || ui_claims(mouse_x, mouse_y);

if (keyboard_check_pressed(vk_anykey) ||
    (mouse_check_button_pressed(mb_any) && !_taken)) {
	game_start();
}
