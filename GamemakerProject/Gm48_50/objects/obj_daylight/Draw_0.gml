/// The debug scrubber.
///
/// A development tool, not part of the game — `T` hides it. It is drawn in room
/// space like everything else here rather than on the GUI layer, because the
/// room and the window are the same size and a second coordinate space earns
/// nothing.
if (!show_ui || !game_playing()) exit;

var _x1 = DAY_UI_X1;
var _x2 = DAY_UI_X2;
var _y  = DAY_UI_Y;
var _h  = DAY_UI_H;

// Panel behind it. The roof it hangs on is already dark, but the timber has
// grain and plank seams running through it and white text on grain is no
// easier to read up here than it is on the deck.
//
// The bottom edge is cut to land on the seam at 96, where the roof boards end
// and the fascia begins, rather than at a comfortable margin below the phase
// names: sitting the panel exactly within the boards is what makes it read as
// part of the porch instead of as a box floating in front of it.
draw_set_colour(c_black);
draw_set_alpha(0.5);
draw_rectangle(_x1 - 16, _y - 46, _x2 + 16, _y + _h + 30, false);
draw_set_alpha(1);

// The bar is painted with the cycle it controls: each slice is the sky at the
// time it stands for, top colour to horizon colour. Reading the gradient tells
// you what a scrub will give you before you drag it, which a grey trough
// cannot, and it doubles as a check that the palettes actually blend smoothly.
var _slices = 64;
var _w = (_x2 - _x1) / _slices;
for (var _i = 0; _i < _slices; _i++) {
	var _t = _i / _slices;
	var _sx = _x1 + _i * _w;
	var _top = day_sample(_t, "sky_top");
	var _bot = day_sample(_t, "sky_warm");
	// +1 on the right edge: at this width the slices land on fractional pixels
	// and a seam of background shows through between them otherwise.
	draw_rectangle_colour(_sx, _y, _sx + _w + 1, _y + _h, _top, _top, _bot, _bot, false);
}

// Phase boundaries, ticked and named on the bar they divide.
draw_set_halign(fa_center);
for (var _p = 0; _p < DAY_PHASES; _p++) {
	var _px = _x1 + (_x2 - _x1) * (_p / DAY_PHASES);

	draw_set_colour(c_white);
	draw_set_alpha(0.35);
	draw_line(_px, _y, _px, _y + _h);

	// The tick marks the boundary, but the label names the span after it, so it
	// is centred in that span rather than on the line it follows.
	var _lx = _x1 + (_x2 - _x1) * ((_p + 0.5) / DAY_PHASES);
	draw_set_alpha((_p == day_phase_index()) ? 0.95 : 0.45);
	draw_text(_lx, _y + _h + 6, day_phase_name(_p));
}
draw_set_halign(fa_left);

// The handle.
var _hx = day_slider_x(global.day_t);
draw_set_colour(c_black);
draw_set_alpha(0.7);
draw_rectangle(_hx - 3, _y - 6, _hx + 3, _y + _h + 6, false);
draw_set_colour(c_white);
draw_set_alpha(dragging ? 1 : 0.85);
draw_rectangle(_hx - 2, _y - 5, _hx + 2, _y + _h + 5, false);

// Readout. The phase being blended toward is named as well as the current one,
// because halfway between two keys the scene looks like neither and the
// question is always "heading where".
var _i = day_phase_index();
var _pct = string(floor(day_phase_progress() * 100));

draw_set_colour(c_white);
draw_set_alpha(0.9);
// Written "to" rather than as an arrow. fntPixels does not carry an arrow
// character, and it does not carry ">" either — its set is ASCII less <, >, ^,
// ` and ~ — so both spellings draw as an empty box. Anything added to this
// line wants checking against that set.
draw_text(_x1, _y - 40, day_clock() + "   " + day_phase_name(_i) + " to " +
	day_phase_name(_i + 1) + "  " + _pct + "%" + (paused ? "   [paused]" : ""));

draw_set_alpha(0.5);
draw_text(_x1, _y - 22, "drag to scrub   P pause   T hide   " +
	string(round(gmlmcp_tunable("day_secs", music_cycle_secs()))) + "s cycle");
draw_set_alpha(1);
