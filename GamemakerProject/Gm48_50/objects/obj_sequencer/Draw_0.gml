// The ledges, the playhead, the picker and the faders are the game's
// interface, and the title card is the one moment the scene is meant to be
// looked at on its own.
if (!game_playing()) exit;

// The board's chrome — the step guides, the cell under the cursor, the picker
// and the help line — answers to T. The objects, the playhead and the notes do
// not: those are the game running, not the controls for it.
var _ui   = ui_shown();
var _cell = _ui ? seq_cell_at(mouse_x, mouse_y) : { track: -1, step: -1 };
// Distance hazes toward the water behind it, so the far ledges recede into
// whatever colour the lake is at this hour instead of a fixed dusk blue.
var _haze = global.pal.water;

// Back to front, so a nearer ledge overlaps the one behind it.
for (var _t = SEQ_TRACKS - 1; _t >= 0; _t--) {
	var _k = global.tracks[_t];
	var _half = _k.size * 0.5;
	var _top = _k.y - _k.size;

	// Distance washes things out, on the shared curve, so an object on the
	// back ledge belongs to the same scene as the trees and the rain behind it
	// rather than sitting on top of the picture.
	var _fade = aerial_fade(_k.z, 0.45);

	// Placeholder ledge. Track 0 is the porch railing, which obj_porch draws.
	if (_t > 0) {
		draw_set_alpha(1);
		draw_set_colour(merge_colour(make_colour_rgb(58, 42, 34), _haze, _fade));
		draw_rectangle(_k.x1 - 28, _k.y, _k.x2 + 28, _k.y + max(4, round(_k.size * 0.3)), false);
	}

	// Step guides. Every fourth is brighter so the bar lines read at a glance
	// and the loop divisions are visible without counting cells.
	if (_ui) {
		draw_set_colour(UI_INK);
		for (var _i = 0; _i < SEQ_STEPS; _i++) {
			var _gx = track_slot_x(_t, _i);
			draw_set_alpha(((_i mod 4 == 0) ? 0.24 : 0.10) * (1 - _fade));
			draw_rectangle(_gx - _half, _top, _gx + _half, _k.y, true);
		}
	}

	// Playhead.
	var _px = track_slot_x(_t, playhead);
	draw_set_alpha(0.20 * (1 - _fade));
	draw_set_colour(make_colour_rgb(255, 238, 196));
	draw_rectangle(_px - _half - 3, _k.y - _k.size * 1.6, _px + _half + 3, _k.y + 8, false);

	// Placed objects. A struck object lifts and pales for a moment: motion
	// reads faster than a colour change alone, and it ties the sound to the
	// thing that made it.
	for (var _i = 0; _i < SEQ_STEPS; _i++) {
		var _ins = slots[_t][_i];
		if (_ins < 0) continue;

		var _d = global.instruments[_ins];
		var _f = flash[_t][_i];
		var _x = track_slot_x(_t, _i);
		var _lift = _f * 7 * (1 - _fade);
		var _col = merge_colour(_d.colour, _haze, _fade);

		// Contact shadow on the ledge. Cast from the ledge row rather than from
		// the object, so a struck instrument lifts off its own shadow instead
		// of dragging it up with it, and the shadow tightens as it rises.
		shadow_cast(_x, _k.y, _k.size * 1.15, c_black,
			(1 - _fade) * (1 - _f * 0.45));

		// The object itself, standing on the ledge. Handed a colour that is
		// already hazed for its distance and paled for the strike, so the
		// renderer never has to know the hour or whether the note just fired.
		prop_draw(_ins, _x, _k.y - _lift, _k.size,
			ray_safe(merge_colour(_col, UI_INK, _f * 0.65)), 1);
	}

	// The cell under the cursor, outlined in what would be dropped there.
	if (_cell.track == _t) {
		var _hx = track_slot_x(_t, _cell.step);
		draw_set_alpha(0.9);
		draw_set_colour(global.instruments[selected].colour);
		draw_rectangle(_hx - _half, _top, _hx + _half, _k.y, true);
	}
}

// The notes coming off anything just tuned. Drawn after the ledges so a note
// rises in front of the objects either side of the one that threw it, and
// before the palette, which is interface and belongs over everything.
notepuff_draw();

// Everything below is the interface: the picker, the randomiser and the line
// of help under them. T takes all of it away.
if (!_ui) exit;

// --- Palette -------------------------------------------------------------
// Laid out on a pitch wide enough for the longest name. Sized to the boxes
// instead, the labels run into each other.
var _bw  = PICK_SIZE;
var _by  = PICK_Y;
var _px  = pick_x();
var _hot = seq_palette_at(mouse_x, mouse_y);

draw_set_halign(fa_center);
for (var _p = 0; _p < instrument_count(); _p++) {
	var _pd = global.instruments[_p];
	var _bx = _px + _p * PICK_PITCH;
	var _cx = _bx + _bw * 0.5;
	var _on    = (_p == selected);
	var _hover = (_hot == _p);

	// The picker draws the objects the same way the ledges do, so what you
	// choose from is what you get. A row of coloured squares meant learning
	// which square was the pitcher.
	draw_set_alpha(_on ? 0.22 : (_hover ? 0.18 : 0.10));
	draw_set_colour(c_black);
	draw_rectangle(_bx, _by, _bx + _bw, _by + _bw, false);

	prop_draw(_p, _cx, _by + _bw - 4, _bw - 10, _pd.colour, _on ? 1 : (_hover ? 0.8 : 0.45));

	draw_set_colour((_on || _hover) ? UI_INK : c_black);
	draw_set_alpha(_on ? 0.95 : (_hover ? 0.7 : 0.55));
	draw_rectangle(_bx, _by, _bx + _bw, _by + _bw, true);

	// Tucked into the corner. Centred, it sat squarely on top of the object it
	// was there to label, which was fine when the button was a plain swatch.
	draw_set_halign(fa_left);
	draw_set_colour(UI_INK);
	draw_set_alpha(_on ? 0.85 : 0.4);
	draw_text(_bx + 4, _by + 1, string(_p + 1));
	draw_set_halign(fa_center);

	// Above the button rather than below it.
	//
	// The help line went under the row, and under the row is where these were.
	// There is no third place: the buttons end 42 pixels off the bottom of the
	// screen and two lines of text do not fit in that, and the row cannot move
	// up because the deck edge is at 660 and it would straddle it.
	//
	// A label above a button is as clearly its label as one below, so the swap
	// costs nothing — the help line is the one of the two that has to be read
	// left to right as a sentence, and the bottom of the screen is where a
	// sentence belongs.
	// Solid white, always, and the same whether this one is held or not.
	//
	// These were UI_INK at half alpha unless selected, which is a fine way to
	// show state and a poor way to show a word: eight of the nine names were
	// permanently half faded over moving grass, and the one you had already
	// chosen was the only one you could read. Which instrument is held is
	// already said three times over by the button — its fill, its border and
	// the object inside it — so the label does not have to say it a fourth
	// time at the cost of being legible.
	//
	// Shadowed rather than merely bright. This sits over grass that is a
	// different colour every hour and never still, and no single tone of text
	// is legible against all of it.
	draw_set_colour(c_black);
	draw_set_alpha(0.6);
	draw_text(_cx + 2, _by - 20, _pd.name);

	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_text(_cx, _by - 22, _pd.name);
}

// The randomiser, on the end of the same row and in the same box, because it
// is reached for in the same moment and with the same hand. It has no selected
// state — it is a thing you do, not a thing you are holding — so it only ever
// draws hot or cold.
var _dx   = seq_dice_x();
var _dcx  = _dx + _bw * 0.5;
var _dhot = seq_dice_at(mouse_x, mouse_y);

draw_set_alpha(_dhot ? 0.18 : 0.10);
draw_set_colour(c_black);
draw_rectangle(_dx, _by, _dx + _bw, _by + _bw, false);

dice_draw(_dcx, _by + _bw * 0.5, _bw - 14, dice_face,
	make_colour_rgb(226, 222, 210), make_colour_rgb(52, 44, 40), _dhot ? 1 : 0.55);

draw_set_colour(_dhot ? UI_INK : c_black);
draw_set_alpha(_dhot ? 0.7 : 0.55);
draw_rectangle(_dx, _by, _dx + _bw, _by + _bw, true);

draw_set_colour(c_black);
draw_set_alpha(0.6);
draw_text(_dcx + 2, _by - 20, "Roll");

draw_set_colour(c_white);
draw_set_alpha(1);
draw_text(_dcx, _by - 22, "Roll");

// The help line, under the row it describes and centred on it.
//
// Under, because it is a list of things you can do and it reads as one line of
// prose — putting it above the buttons made it the first thing the eye met on
// the way down to them, which is backwards for something you consult rather
// than read. Centred rather than pinned to a margin, or it would be the one
// piece of the bottom interface still hugging a corner.
//
// T is in it now. It was advertised on the day scrubber's help line and that
// went with the bar, which left the key that hides the interface as the only
// control in the game nothing mentioned.
//
// Solid white and shadowed, for the same reason the names are: it lies across
// the rug, which is the busiest thing on the deck, and at the alpha it used to
// carry it was a grey suggestion of a sentence.
var _help = "1-" + string(instrument_count()) +
	" pick   LMB place, click again to tune   RMB remove   Backspace clear   T hide UI";
var _hx   = _px + pick_width() * 0.5;
var _hy   = _by + _bw + 8;

draw_set_colour(c_black);
draw_set_alpha(0.6);
draw_text(_hx + 2, _hy + 2, _help);

draw_set_colour(c_white);
draw_set_alpha(1);
draw_text(_hx, _hy, _help);

draw_set_halign(fa_left);
