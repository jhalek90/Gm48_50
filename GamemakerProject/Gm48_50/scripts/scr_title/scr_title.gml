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

/// The row of buttons in the top right corner.
///
/// There are three of them now — fullscreen, volume, pause — and they used to
/// be a chain: the speaker placed itself off the fullscreen button, and a third
/// would have placed itself off the speaker. That works right up until one of
/// them moves or goes away, at which point every button after it moves too and
/// the one you changed is not the one that broke.
///
/// Counted from the right instead, which is how the row actually reads. Index 0
/// is the corner. Adding a fourth is `ui_btn_x(3)` and nothing else.
///
/// The roof fills that corner and nothing in the scene happens there, so the
/// row sits on it without covering anything.
#macro UI_BTN_SIZE 34
#macro UI_BTN_Y    16
#macro UI_BTN_GAP  10

function ui_btn_x(_i) {
	return room_width - 16 - UI_BTN_SIZE - _i * (UI_BTN_SIZE + UI_BTN_GAP);
}

/// Does any part of the interface own a click here?
///
/// The one question everything else asks. There are two modal panels now, the
/// volume and the controls, and before this each of them had to be named
/// separately at every site that acts on a click: the title card, the board,
/// the lantern, the duck, the sky and the fullscreen button. Six sites times
/// two panels is twelve places to forget one.
///
/// A panel added later goes in here and nowhere else.
function ui_claims(_mx, _my) {
	return mixer_claims(_mx, _my) || help_claims(_mx, _my);
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

// --- Saying something briefly --------------------------------------------
//
// One line, in the middle of the screen, gone in a couple of seconds.
//
// It exists because the controls that used to announce themselves stopped.
// Pause was a key with a line of help under the clock bar and a [paused] tag on
// the clock itself; both of those went with the bar, and a button that silently
// stops time is a button you press twice wondering whether it worked. This is
// what the tag used to be, said once instead of held up forever.
//
// Deliberately general and deliberately one-at-a-time. A queue would mean two
// messages could stack up and the second would arrive after the thing it is
// about has been forgotten — a later message simply replaces the one in front
// of it, which is what you want from something this transient.

#macro TOAST_SECS 2.0

/// Hold full strength for the first quarter, then fade. A line that starts
/// fading the instant it appears reads as already leaving, and the eye has to
/// find it before it can begin to go.
#macro TOAST_HOLD 0.25

function toast_init() {
	global.toast_text = "";
	global.toast_life = 0;
}

function toast_show(_text) {
	if (!variable_global_exists("toast_life")) toast_init();

	global.toast_text = _text;
	global.toast_life = TOAST_SECS;
}

function toast_step() {
	if (!variable_global_exists("toast_life")) toast_init();

	// Real elapsed time, like every other clock here, so it lasts two seconds
	// rather than a hundred and twenty frames.
	global.toast_life = max(0, global.toast_life - delta_time / 1000000);
}

function toast_draw() {
	if (!variable_global_exists("toast_life")) return;
	if (global.toast_life <= 0) return;

	var _t = global.toast_life / TOAST_SECS;
	var _a = (_t > 1 - TOAST_HOLD) ? 1 : _t / (1 - TOAST_HOLD);

	var _cx = room_width * 0.5;
	var _cy = room_height * 0.5;

	// Sized to a target width rather than by a fixed multiplier, the same way
	// the title card is, so the line stays put if fntPixels is ever regenerated
	// at a different point size.
	var _s = gmlmcp_tunable("toast_size", 300) / max(1, string_width(global.toast_text));

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	// A shadow first: this lands over the lake, which runs from pale overcast
	// water to near black, and one tone of text cannot be legible against both.
	draw_set_colour(c_black);
	draw_set_alpha(_a * 0.5);
	draw_text_transformed(_cx + 3, _cy + 3, global.toast_text, _s, _s, 0);

	// UI_INK rather than white: this is large, central, and sits in the open
	// where the god rays would find it. A white line here would smear a copy of
	// itself across the sky toward the sun.
	draw_set_colour(UI_INK);
	draw_set_alpha(_a);
	draw_text_transformed(_cx, _cy, global.toast_text, _s, _s, 0);

	draw_set_alpha(1);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}
