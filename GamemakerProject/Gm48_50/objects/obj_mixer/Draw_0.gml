/// Draw the speaker, and the panel if it is open.
///
/// The button is drawn whether or not the game has started, like the
/// fullscreen toggle beside it and for the same reason: how loud this is going
/// to be is a thing somebody might reasonably want to settle before they begin,
/// and a control that only appears after you commit is a control you find by
/// accident.
///
/// Both still answer to T, which takes away everything that is only there to be
/// operated.

if (!ui_shown()) exit;

mixer_btn_draw();
mixer_panel_draw(dragging);
