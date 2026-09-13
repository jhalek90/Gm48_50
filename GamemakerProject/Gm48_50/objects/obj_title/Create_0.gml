/// The title card.
///
/// In front of everything the scene draws. The day scrubber sits at -200 and
/// is the deepest thing in the room, and a title the debug tool can cover is
/// not much of a title.
///
/// Drawn in a plain Draw event rather than on the GUI layer, so the name goes
/// through shd_post with the rest of the picture and is posterised by the same
/// shader that posterises the water behind it. A logo that missed that pass
/// would be the one crisp thing on a screen full of blocks.
depth = -300;

title_init();

// Its own clock, for the prompt's breathing. Real seconds, like every other
// clock here, so it keeps its rate whatever the frame rate does.
t = 0;
