var _half = SEQ_SIZE * 0.5;
var _top = RAIL_Y - SEQ_SIZE;

// Step guides. Every fourth is brighter so the bar lines read at a glance and
// the player can see where the loop divides without counting cells.
draw_set_colour(c_white);
for (var _i = 0; _i < SEQ_STEPS; _i++) {
	var _x = seq_slot_x(_i);
	draw_set_alpha((_i mod 4 == 0) ? 0.24 : 0.10);
	draw_rectangle(_x - _half, _top, _x + _half, RAIL_Y, true);
}

// Playhead.
var _px = seq_slot_x(playhead);
draw_set_alpha(0.20);
draw_set_colour(make_colour_rgb(255, 238, 196));
draw_rectangle(_px - _half - 3, RAIL_Y - SEQ_SIZE * 1.6, _px + _half + 3, RAIL_Y + 10, false);

// Placed objects. A struck object lifts and pales for a moment: motion reads
// faster than a colour change alone, and it ties the sound to the thing that
// made it.
for (var _i = 0; _i < SEQ_STEPS; _i++) {
	var _ins = slots[_i];
	if (_ins < 0) continue;

	var _d = global.instruments[_ins];
	var _f = flash[_i];
	var _x = seq_slot_x(_i);
	var _lift = _f * 7;

	draw_set_alpha(1);
	draw_set_colour(merge_colour(_d.colour, c_white, _f * 0.65));
	draw_rectangle(_x - _half, _top - _lift, _x + _half, RAIL_Y - _lift, false);

	draw_set_colour(c_black);
	draw_set_alpha(0.45);
	draw_rectangle(_x - _half, _top - _lift, _x + _half, RAIL_Y - _lift, true);
}

// The step under the cursor, outlined in what would be dropped there.
var _hover = seq_slot_at(mouse_x);
if (_hover >= 0) {
	var _hx = seq_slot_x(_hover);
	draw_set_alpha(0.9);
	draw_set_colour(global.instruments[selected].colour);
	draw_rectangle(_hx - _half, _top, _hx + _half, RAIL_Y, true);
}

// --- Palette -------------------------------------------------------------
// Laid out on a pitch wide enough for the longest name. Sized to the boxes
// instead, the labels run into each other.
var _bw = 62;
var _pitch = 84;
var _by = room_height - 104;

draw_set_halign(fa_center);
for (var _k = 0; _k < instrument_count(); _k++) {
	var _d = global.instruments[_k];
	var _bx = 40 + _k * _pitch;
	var _cx = _bx + _bw * 0.5;
	var _on = (_k == selected);

	draw_set_alpha(_on ? 1 : 0.4);
	draw_set_colour(_d.colour);
	draw_rectangle(_bx, _by, _bx + _bw, _by + _bw, false);

	draw_set_colour(_on ? c_white : c_black);
	draw_set_alpha(_on ? 0.95 : 0.55);
	draw_rectangle(_bx, _by, _bx + _bw, _by + _bw, true);

	draw_set_colour(c_black);
	draw_set_alpha(_on ? 0.8 : 0.5);
	draw_text(_cx, _by + 20, string(_k + 1));

	draw_set_colour(c_white);
	draw_set_alpha(_on ? 0.95 : 0.5);
	draw_text(_cx, _by + _bw + 5, _d.name);
}
draw_set_halign(fa_left);

draw_set_colour(c_white);
draw_set_alpha(0.7);
draw_text(40, _by - 26, "1-7 pick   LMB place   RMB remove   Backspace clear   " + string(round(gmlmcp_tunable("bpm", 84))) + " BPM");
draw_set_alpha(1);
