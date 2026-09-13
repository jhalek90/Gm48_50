/// The controls, behind a question mark.
///
/// They used to run along the bottom of the screen as one line under the
/// picker, which fitted because it only listed what the board does. It could
/// not list the rest: the sky can be dragged, the chime can be swept, the duck
/// and the lantern answer a click. None of those are discoverable and none of
/// them fitted on that line, so the game had a set of interactions nobody would
/// ever find and a help line that implied there were no others.
///
/// A panel holds all of it and costs no screen space when shut.
///
/// --- Why the button asks for attention ------------------------------------
///
/// A jam entry gets about two minutes of a voter's time. A question mark in a
/// corner is the least noticeable thing on screen, and the interactions it
/// documents are the half of the game that is not obvious, so it moves until
/// somebody opens it once. After that it goes still and stays still: an
/// attract that keeps running after it has worked is a distraction in a game
/// about sitting quietly.

/// The fourth button of the top-right row.
#macro HELP_SIZE UI_BTN_SIZE
#macro HELP_X    ui_btn_x(3)
#macro HELP_Y    UI_BTN_Y

/// The panel, hung under the row and squared off against the same right edge.
///
/// 450 wide. The key column now runs to 168 and the longest action after it is
/// "change the time of day", 22 characters. That puts the left edge at 900 and
/// overlaps the title wordmark, which reaches 963, by more than it used to. It
/// is the corner of a letter behind an opaque panel, and is worth less than
/// having the rows fit.
#macro HELP_PAD      16
#macro HELP_PANEL_X2 (ui_btn_x(0) + UI_BTN_SIZE)
#macro HELP_PANEL_X1 (HELP_PANEL_X2 - 450)
#macro HELP_PANEL_Y1 (HELP_Y + HELP_SIZE + 10)

/// Where the action column starts, measured from the panel's left edge.
///
/// 180. The longest key is "left click again" at 16 characters, which ends at
/// 168, so this is that plus a space to read across. fntPixels is monospaced,
/// so the column is the character count times the advance and anything less
/// puts a key against its own action.
#macro HELP_COL 180

/// Row pitch, and how far a blank spacer row is worth.
#macro HELP_ROW 24

function help_init() {
	global.help_open = false;

	// Whether anybody has opened it yet. The attract runs until they do.
	global.help_seen = false;
	global.help_t    = 0;

	// Key, then what it does. An empty key is a heading; an empty pair is a
	// gap. Written here rather than built in the draw so the panel's height can
	// be measured from it and the two cannot disagree about how many rows there
	// are.
	// No headings. Three labels over eleven rows was a contents page for a list
	// short enough to read in one go, and each of them named the obvious. The
	// blank rows stay, so the groups are still apart on the page without
	// anything having to say what they are.
	global.help_rows = [
		["1-8",             "pick instrument"],
		["left click",      "place on railing"],
		["left click again","increment note"],
		["right click",     "remove instrument"],
		["backspace",       "clear the railing"],
		["", ""],
		["drag sky",        "change the time of day"],
		["sweep",           "the wind chime rings"],
		["click",           "the duck, the lantern"],
		["", ""],
		["T",               "hide interface"],
		["P",               "keep the moment still"],
	];
}

function help_ensure() {
	if (!variable_global_exists("help_open")) help_init();
}

function help_opened() {
	help_ensure();
	return global.help_open;
}

/// Has anyone opened it? The attract stops when they have.
function help_seen() {
	help_ensure();
	return global.help_seen;
}

function help_toggle() {
	help_ensure();
	ui_click();

	global.help_open = !global.help_open;
	global.help_seen = true;
}

function help_close() {
	help_ensure();
	global.help_open = false;
}

function help_step() {
	help_ensure();
	global.help_t += delta_time / 1000000;
}

/// The bottom of the panel, from the rows it holds.
function help_panel_y2() {
	help_ensure();
	return HELP_PANEL_Y1 + HELP_PAD * 2 + array_length(global.help_rows) * HELP_ROW;
}

function help_btn_at(_mx, _my) {
	return (_mx >= HELP_X && _mx <= HELP_X + HELP_SIZE &&
	        _my >= HELP_Y && _my <= HELP_Y + HELP_SIZE);
}

function help_panel_at(_mx, _my) {
	if (!help_opened()) return false;

	return (_mx >= HELP_PANEL_X1 && _mx <= HELP_PANEL_X2 &&
	        _my >= HELP_PANEL_Y1 && _my <= help_panel_y2());
}

/// Does the help own a click here?
///
/// The same rule the mixer keeps: true everywhere while the panel is open, so
/// the click that dismisses it does only that. See mixer_claims.
function help_claims(_mx, _my) {
	if (!ui_shown()) return false;
	return help_opened() || help_btn_at(_mx, _my);
}

/// How far the button is nudged this instant, in pixels.
///
/// A lean rather than a shake. Two sines at an irrational ratio, the same shape
/// the wind uses, so it does not tick like a metronome in the corner of the
/// eye. Returns 0 once the panel has been opened.
function help_wiggle() {
	if (help_seen()) return 0;

	var _t = global.help_t;
	return sin(_t * 2.7) * 2.2 + sin(_t * 4.31 + 1.1) * 0.9;
}

function help_btn_draw() {
	var _hot = help_btn_at(mouse_x, mouse_y);
	var _on  = help_opened();
	var _w   = help_wiggle();

	// The attract brightens as well as moves. Motion alone is easy to miss in a
	// frame that already has rain in it.
	var _pull = help_seen() ? 0 : (0.5 + 0.5 * sin(global.help_t * 2.7));

	draw_set_alpha(1);
	draw_set_colour(merge_colour(c_black, global.pal.water, 0.18));
	draw_rectangle(HELP_X, HELP_Y, HELP_X + HELP_SIZE, HELP_Y + HELP_SIZE, false);

	// Lit for the whole attract, not only the bright half of it. Switching the
	// border colour on the pulse made it drop to near black at the trough,
	// which reads as the button going away rather than breathing. Only the
	// brightness moves.
	draw_set_colour((_hot || _on || !help_seen()) ? UI_INK : c_black);
	draw_set_alpha(_hot ? 0.7 : (0.45 + 0.35 * _pull));
	draw_rectangle(HELP_X, HELP_Y, HELP_X + HELP_SIZE, HELP_Y + HELP_SIZE, true);

	// Under the god ray threshold, like everything else drawn above the
	// horizon. See ray_safe.
	draw_set_colour(UI_INK);
	draw_set_alpha(_hot ? 0.95 : (0.6 + 0.4 * _pull));

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_text(HELP_X + HELP_SIZE * 0.5 + _w, HELP_Y + HELP_SIZE * 0.5, "?");
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);

	draw_set_alpha(1);
}

function help_panel_draw() {
	if (!help_opened()) return;

	var _y2 = help_panel_y2();

	// Solid, and tinted toward the water like the volume panel. It sits over
	// the roof and the trees, and translucency loses to that.
	draw_set_colour(merge_colour(c_black, global.pal.water, 0.18));
	draw_set_alpha(1);
	draw_rectangle(HELP_PANEL_X1, HELP_PANEL_Y1, HELP_PANEL_X2, _y2, false);

	draw_set_colour(UI_INK);
	draw_set_alpha(0.30);
	draw_rectangle(HELP_PANEL_X1, HELP_PANEL_Y1, HELP_PANEL_X2, _y2, true);

	draw_set_halign(fa_left);

	var _rows = global.help_rows;
	for (var _i = 0; _i < array_length(_rows); _i++) {
		var _k = _rows[_i][0];
		var _a = _rows[_i][1];
		if (_k == "" && _a == "") continue;

		var _y = HELP_PANEL_Y1 + HELP_PAD + _i * HELP_ROW;

		draw_set_colour(UI_INK);
		draw_set_alpha(0.72);
		draw_text(HELP_PANEL_X1 + HELP_PAD, _y, _k);

		// UI_INK, not white. This panel runs from y 60 to about 484, so most of
		// its rows sit above the horizon at 300 and inside the band shd_post
		// takes light sources from. White text here threw a legible copy of
		// itself across the panel.
		//
		// The instrument labels and the bottom help line can be pure white
		// because they are below the floor. Height decides it, not the fact
		// that a thing is interface.
		draw_set_colour(UI_INK);
		draw_set_alpha(1);
		draw_text(HELP_PANEL_X1 + HELP_PAD + HELP_COL, _y, _a);
	}

	draw_set_alpha(1);
}
