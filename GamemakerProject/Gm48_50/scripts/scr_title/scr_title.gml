/// The title card, and the one piece of state that says whether it is up.
///
/// There is no title room. The scene is the title: the same lake, the same
/// rain, the same hour of the same day, with the interface stood down and a
/// name laid over it. A second room would have meant a second copy of the
/// porch to keep in step with the first, and the first thing a player saw
/// would have been a picture of the game rather than the game.
///
/// Almost nothing stops while the title is up. The rain falls, the day turns,
/// the rhythm track plays and the sequencer's clock keeps counting bars — that
/// last one matters, because the music controller starts each track on a bar
/// boundary and a stopped clock means the second track never arrives. What is
/// held back is input and interface, which is all that "not playing yet"
/// actually means here.

function title_init() {
	global.playing = false;
}

/// Is the game underway?
///
/// Guarded like the mix and the bar count are, because the objects that ask
/// this share a room with the one that answers it, and creation order is not a
/// contract.
function game_playing() {
	if (!variable_global_exists("playing")) title_init();
	return global.playing;
}

/// Is the interface showing?
///
/// T hides all of it, not just the day scrubber it used to live on. It was an
/// instance variable there because it governed one panel; once it governs the
/// picker, the faders and the fullscreen button as well it cannot sit on any
/// one of them without that object becoming the odd owner of everybody else's
/// visibility.
///
/// What it hides is chrome, not the instrument. The railing's objects, the
/// playhead sweeping them and the notes coming off them all stay: they are the
/// game running, and a clean view of the scene should still show the scene
/// doing something. What goes is everything that is only there to be operated.
///
/// Hidden also means not clickable. An invisible button you can still press by
/// remembering where it was is worse than either showing it or removing it.
function ui_init() {
	global.ui_visible = true;
}

function ui_shown() {
	if (!variable_global_exists("ui_visible")) ui_init();
	return global.ui_visible;
}

function ui_toggle() {
	global.ui_visible = !ui_shown();
}

function game_start() {
	global.playing = true;

	// And deal a board on the way in, so the first thing the player hears is
	// the game playing rather than an empty railing and a silent sweep. It is
	// also the clearest possible statement of what the board is for: something
	// is already running, and everything they do from here is a change to it
	// rather than a blank page.
	//
	// The same deal the die gives, so the button is a repeat of the opening
	// move rather than a feature they have to find.
	seq_deal();
}
