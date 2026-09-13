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

function game_start() {
	global.playing = true;
}
