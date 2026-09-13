// Not gated on game_playing: this is usable before the game starts. obj_title
// locks its own any-click-to-start out of this rectangle, so a click here
// cannot both resize the window and begin the game.
if (mouse_check_button_pressed(mb_left) && fullscreen_at(mouse_x, mouse_y)) {
	fullscreen_toggle();
}
