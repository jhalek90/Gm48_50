/// The things that live here, advanced.
///
/// In a Step rather than inside the Draw that puts them on screen, because
/// birds and the duck are drawn from two different points in that event and
/// neither should be the one that decides how far they have moved. The same
/// split the sequencer and the daylight use: the clock runs once, and drawing
/// only ever reads it.
wildlife_step();

// The duck answers if you click it.
//
// Not on the title card, where any click starts the game, and not while the
// volume panel is open — the same two locks every other clickable thing in
// this scene carries. It needs no lock against the board: it was moved off the
// ledge row precisely so the two could never want the same click.
if (game_playing() && !mixer_claims(mouse_x, mouse_y) &&
    mouse_check_button_pressed(mb_left) && duck_at(mouse_x, mouse_y)) {
	duck_quack();
}
