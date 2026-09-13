/// The cat answers if you click it.
///
/// Handled here rather than in obj_scene, where the duck's click lives, because
/// the cat is porch clutter: this object draws it, so this object owns what
/// happens when it is touched.
///
/// The same two locks every other clickable thing in this scene carries. Not on
/// the title card, where any click starts the game, and not while a panel is
/// open, which owns every click while it is up. It needs no lock against the
/// board: the ledges are at the railing and the cat is on the deck in front of
/// it, so the two cannot want the same click.
if (game_playing() && !ui_claims(mouse_x, mouse_y) &&
    mouse_check_button_pressed(mb_left) && cat_at(mouse_x, mouse_y)) {
	cat_meow();
}
