/// Opening, dragging, and pushing master out to the engine.

// A drag can only start on a fader, and once started it keeps that fader even
// if the pointer slides off it. Releasing anywhere ends it. Without the first
// rule a click anywhere on the porch would grab whichever fader was nearest;
// without the second, a fast drag would drop the handle halfway across.
if (ui_shown()) {
	if (mouse_check_button_pressed(mb_left)) {
		if (mixer_btn_at(mouse_x, mouse_y)) {
			// One panel at a time. The two overlap in that corner, and two
			// solid panels stacked there is worse than either alone.
			help_close();
			mixer_toggle();
		} else if (mixer_open() && !mixer_panel_at(mouse_x, mouse_y)) {
			// Click away to dismiss. That click does nothing else — while the
			// panel is open mixer_claims() holds off the title card, the board
			// and the lantern, so putting the faders away cannot also start the
			// game or drop an instrument on a ledge.
			mixer_close();
		}
	}

	if (mouse_check_button_pressed(mb_left)) {
		dragging = mixer_row_at(mouse_x, mouse_y);

		// On taking hold of a fader, not on every pixel of the drag.
		if (dragging >= 0) ui_click();
	}
	if (!mouse_check_button(mb_left)) dragging = -1;

	if (dragging >= 0) {
		global.mix[dragging] = mixer_value_at(mouse_x);
	}
} else {
	// Hidden with the rest of the interface, and shut rather than merely
	// invisible: T is for looking at the scene, and a panel that was open when
	// it went away would come back over the view it was pressed to clear.
	mixer_close();
	dragging = -1;
}

// Master is the one fader the engine applies for us, and it is the only way to
// reach the music — nothing else in the project touches that gain. The other
// two are multiplied in at the point the sound is played.
audio_master_gain(mix_master());
