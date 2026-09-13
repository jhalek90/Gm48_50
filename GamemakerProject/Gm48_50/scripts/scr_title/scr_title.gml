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

/// The click a browser needs before it will make a sound.
///
/// Every browser refuses to start an audio context until the page has had a
/// real user gesture. A game that begins playing rain and music the instant the
/// room loads does not get quiet audio on the web, it gets an audio context
/// that never starts, and often stays broken for the rest of the session even
/// after the player does click.
///
/// So nothing sounds until this is passed, and the only way past it is a mouse
/// click. Not a keypress: a click is the gesture every browser accepts, and
/// this screen has one job.
///
/// It sits in front of the title card rather than replacing it. The title is
/// the game introducing itself and wants to be looked at; this is a door, and
/// it should be got through and forgotten.
///
/// Three things start sound without being asked: the rain bed, the drop plinks
/// and the music. Each checks this. Everything else in the game makes noise
/// because somebody clicked something, which by definition is after the gate.
function audio_gate_init() {
	global.audio_gated = true;
}

function audio_gated() {
	if (!variable_global_exists("audio_gated")) audio_gate_init();
	return global.audio_gated;
}

function audio_ungate() {
	global.audio_gated = false;
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

/// The interface's click.
///
/// Played flat, not positioned: a button is not in the scene, it is on the
/// glass in front of it, and panning a click to wherever the button happens to
/// sit would put the interface in the world.
///
/// Deliberately not through mix_sfx. That fader is for the objects on the
/// railing, and a player who pulls it to zero to hear the rain has not asked
/// for the buttons to stop responding. Master still covers it, as it covers
/// everything.
function ui_click() {
	var _i = audio_play_sound(snd_click, 12, false);
	audio_sound_gain(_i, gmlmcp_tunable("click_gain", 0.55), 0);
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
	// Nothing while the gate is up. The gate draws over the whole screen, so
	// the buttons behind it are invisible but would still take the click that
	// opens the gate: one press would let the audio through and toggle whatever
	// happened to be under the pointer. Hiding them here covers the volume
	// panel, the controls panel and the fullscreen button in one place, because
	// all three already ask this question.
	if (audio_gated()) return false;

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

/// The wordmark.
///
/// Drawn by both screens that show it, the gate and the title card, so the game
/// cannot end up wearing its name at two sizes. Only the position differs.
///
/// Sets fntLogo and puts fntPixels back. The font is global draw state and
/// obj_render sets fntPixels once for the whole game because the interface only
/// ever wants that one; leaving fntLogo set would hand it to every UI event on
/// the following frame.
///
/// Scaled to a target width rather than by a fixed multiplier, so a
/// regenerated fntLogo comes out sharper at the same size on screen rather than
/// larger.
///
/// The ink is 0.77 luminance and that is not a taste decision. The wordmark
/// sits above the horizon, where shd_post takes its light sources, and white
/// letters would put every stroke over the 0.83 threshold and smear a copy of
/// the name across the sky toward the sun.
/// Bone white, 0.77 luminance. Not a taste decision: see the note above.
#macro TITLE_INK make_colour_rgb(202, 196, 182)

function title_wordmark(_cy) {
	var _name = "Petrichord";
	var _cx   = room_width * 0.5;

	draw_set_font(fntLogo);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _s = gmlmcp_tunable("title_size", 560) / max(1, string_width(_name));

	draw_set_colour(c_black);
	draw_set_alpha(0.45);
	draw_text_transformed(_cx + 6, _cy + 6, _name, _s, _s, 0);

	draw_set_colour(TITLE_INK);
	draw_set_alpha(1);
	draw_text_transformed(_cx, _cy, _name, _s, _s, 0);

	// The bottom of the letters, for anything that wants to sit under them.
	// Measured while fntLogo is still set: once the font is put back, the same
	// call would measure the interface face instead and answer for the wrong
	// text entirely.
	var _bottom = _cy + string_height(_name) * _s * 0.5;

	draw_set_font(fntPixels);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);

	return _bottom;
}

/// A line under the wordmark, in the same face.
///
/// Its own function for the same reason the wordmark is: it is drawn in fntLogo
/// and the font is global draw state, so the setting and the putting back
/// belong together rather than at opposite ends of somebody's draw event.
function title_line(_msg, _y, _alpha, _target) {
	var _cx = room_width * 0.5;

	draw_set_font(fntLogo);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _s = _target / max(1, string_width(_msg));

	draw_set_colour(c_black);
	draw_set_alpha(_alpha * 0.5);
	draw_text_transformed(_cx + 3, _y + 3, _msg, _s, _s, 0);

	draw_set_colour(TITLE_INK);
	draw_set_alpha(_alpha);
	draw_text_transformed(_cx, _y, _msg, _s, _s, 0);

	draw_set_alpha(1);
	draw_set_font(fntPixels);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

// --- The gate screen -----------------------------------------------------

/// Where the button sits, and how big it is.
///
/// Centred, and the whole rectangle is the target rather than the words in it.
/// A player who has been told to click has been told to click somewhere, and a
/// generous box is the difference between a game that starts and a game that
/// appears broken.
#macro GATE_W  340
#macro GATE_H   88

#macro GATE_X1 ((room_width  - GATE_W) * 0.5)
#macro GATE_Y1 ((room_height - GATE_H) * 0.5)
#macro GATE_X2 (GATE_X1 + GATE_W)
#macro GATE_Y2 (GATE_Y1 + GATE_H)

function gate_at(_mx, _my) {
	return (_mx >= GATE_X1 && _mx <= GATE_X2 &&
	        _my >= GATE_Y1 && _my <= GATE_Y2);
}

/// The door.
///
/// Solid, not a dim over the scene. The scene is the thing the title card is
/// about to show off, and showing it through a haze here spends that twice.
///
/// The whole panel sits below the horizon, where shd_post takes no light
/// sources, so the text can be plain white. See the luminance note in
/// DEVNOTES: above that line it would have to be UI_INK.
function gate_draw() {
	draw_set_colour(make_colour_rgb(14, 12, 14));
	draw_set_alpha(1);
	draw_rectangle(0, 0, room_width, room_height, false);

	// The name, at the same size the title card wears it. A door with nothing
	// on it is a door to nowhere, and this is the first thing anybody sees.
	title_wordmark(gmlmcp_tunable("gate_title_y", 236));

	var _hot = gate_at(mouse_x, mouse_y);

	draw_set_colour(c_black);
	draw_set_alpha(_hot ? 0.5 : 0.35);
	draw_rectangle(GATE_X1, GATE_Y1, GATE_X2, GATE_Y2, false);

	draw_set_colour(c_white);
	draw_set_alpha(_hot ? 0.9 : 0.55);
	draw_rectangle(GATE_X1, GATE_Y1, GATE_X2, GATE_Y2, true);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _msg = "click to start";
	var _s   = gmlmcp_tunable("gate_size", 240) / max(1, string_width(_msg));

	draw_set_colour(c_white);
	draw_set_alpha(_hot ? 1 : 0.8);
	draw_text_transformed(room_width * 0.5, room_height * 0.5, _msg, _s, _s, 0);

	// Said once, small, under the button. A browser will not let a page make a
	// sound until somebody clicks it, and a player who knows that is a player
	// who does not think the game is silent.
	draw_set_alpha(0.4);
	draw_text_transformed(room_width * 0.5, GATE_Y2 + 34,
		"your browser needs a click before it will play sound", _s * 0.55, _s * 0.55, 0);

	draw_set_alpha(1);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}
