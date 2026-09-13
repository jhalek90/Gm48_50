/// Opening, and closing on a click away.
///
/// Not gated on game_playing. The controls are the one thing a player might
/// want to read before they start, which is the same argument the fullscreen
/// button and the volume panel already make for themselves. obj_title locks
/// its own any-click-to-start out of this rectangle.
help_step();

if (!ui_shown()) {
	// Hidden with the rest of the interface, and shut rather than merely
	// invisible: T is for looking at the scene, and a panel that was open when
	// it went away would come back over the view it was pressed to clear.
	help_close();
	exit;
}

if (!mouse_check_button_pressed(mb_left)) exit;

if (help_btn_at(mouse_x, mouse_y)) {
	// One panel at a time. The two overlap, and two solid panels stacked in the
	// same corner is worse than either.
	mixer_close();
	help_toggle();
	exit;
}

if (help_opened() && !help_panel_at(mouse_x, mouse_y)) help_close();
