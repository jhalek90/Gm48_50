/// Dragging, and pushing master out to the engine.

// A drag can only start on a fader, and once started it keeps that fader even
// if the pointer slides off it. Releasing anywhere ends it. Without the first
// rule a click anywhere on the porch would grab whichever fader was nearest;
// without the second, a fast drag would drop the handle halfway across.
//
// Not on the title card, where the faders are not drawn and the click that
// starts the game would otherwise grab whichever one it happened to land on.
if (game_playing() && ui_shown()) {
	if (mouse_check_button_pressed(mb_left)) {
		dragging = mixer_row_at(mouse_x, mouse_y);
	}
	if (!mouse_check_button(mb_left)) dragging = -1;

	if (dragging >= 0) {
		global.mix[dragging] = mixer_value_at(mouse_x);
	}
} else {
	dragging = -1;
}

// Master is the one fader the engine applies for us, and it is the only way to
// reach the music — nothing else in the project touches that gain. The other
// two are multiplied in at the point the sound is played.
audio_master_gain(mix_master());
