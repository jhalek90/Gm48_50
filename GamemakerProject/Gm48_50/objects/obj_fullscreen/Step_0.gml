// Not gated on game_playing: this is usable before the game starts. obj_title
// locks its own any-click-to-start out of this rectangle, so a click here
// cannot both resize the window and begin the game.
// Locked out while the volume panel is open, like everything else: the first
// click puts the panel away, and the second works the button. Dismissing a
// panel and toggling the window on one click is the two-actions rule again.
if (ui_shown() && !ui_claims(mouse_x, mouse_y) &&
    mouse_check_button_pressed(mb_left) && fullscreen_at(mouse_x, mouse_y)) {
	fullscreen_toggle();
}
