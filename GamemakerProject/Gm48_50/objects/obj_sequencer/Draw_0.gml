var _cell = seq_cell_at(mouse_x, mouse_y);
// Distance hazes toward the water behind it, so the far ledges recede into
// whatever colour the lake is at this hour instead of a fixed dusk blue.
var _haze = global.pal.water;
var _near_z = global.tracks[0].z;

// Back to front, so a nearer ledge overlaps the one behind it.
for (var _t = SEQ_TRACKS - 1; _t >= 0; _t--) {
	var _k = global.tracks[_t];
	var _half = _k.size * 0.5;
	var _top = _k.y - _k.size;

	// Distance washes things out. The same aerial perspective the rain uses,
	// so an object on the back ledge belongs to the same scene as the rain
	// falling past it rather than sitting on top of the picture.
	var _fade = clamp((_k.z - _near_z) / 2.5, 0, 0.45);

	// Placeholder ledge. Track 0 is the porch railing, which obj_porch draws.
	if (_t > 0) {
		draw_set_alpha(1);
		draw_set_colour(merge_colour(make_colour_rgb(58, 42, 34), _haze, _fade));
		draw_rectangle(_k.x1 - 28, _k.y, _k.x2 + 28, _k.y + max(4, round(_k.size * 0.3)), false);
	}

	// Step guides. Every fourth is brighter so the bar lines read at a glance
	// and the loop divisions are visible without counting cells.
	draw_set_colour(c_white);
	for (var _i = 0; _i < SEQ_STEPS; _i++) {
		var _gx = track_slot_x(_t, _i);
		draw_set_alpha(((_i mod 4 == 0) ? 0.24 : 0.10) * (1 - _fade));
		draw_rectangle(_gx - _half, _top, _gx + _half, _k.y, true);
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

		draw_set_alpha(1);
		draw_set_colour(merge_colour(_col, c_white, _f * 0.65));
		draw_rectangle(_x - _half, _top - _lift, _x + _half, _k.y - _lift, false);

		draw_set_colour(c_black);
		draw_set_alpha(0.45 * (1 - _fade));
		draw_rectangle(_x - _half, _top - _lift, _x + _half, _k.y - _lift, true);
	}

	// The cell under the cursor, outlined in what would be dropped there.
	if (_cell.track == _t) {
		var _hx = track_slot_x(_t, _cell.step);
		draw_set_alpha(0.9);
		draw_set_colour(global.instruments[selected].colour);
		draw_rectangle(_hx - _half, _top, _hx + _half, _k.y, true);
	}
}

// --- Palette -------------------------------------------------------------
// Laid out on a pitch wide enough for the longest name. Sized to the boxes
// instead, the labels run into each other.
var _bw = 62;
var _by = room_height - 104;

draw_set_halign(fa_center);
for (var _p = 0; _p < instrument_count(); _p++) {
	var _pd = global.instruments[_p];
	var _bx = 40 + _p * 84;
	var _cx = _bx + _bw * 0.5;
	var _on = (_p == selected);

	draw_set_alpha(_on ? 1 : 0.4);
	draw_set_colour(_pd.colour);
	draw_rectangle(_bx, _by, _bx + _bw, _by + _bw, false);

	draw_set_colour(_on ? c_white : c_black);
	draw_set_alpha(_on ? 0.95 : 0.55);
	draw_rectangle(_bx, _by, _bx + _bw, _by + _bw, true);

	draw_set_colour(c_black);
	draw_set_alpha(_on ? 0.8 : 0.5);
	draw_text(_cx, _by + 20, string(_p + 1));

	draw_set_colour(c_white);
	draw_set_alpha(_on ? 0.95 : 0.5);
	draw_text(_cx, _by + _bw + 5, _pd.name);
}
draw_set_halign(fa_left);

draw_set_colour(c_white);
draw_set_alpha(0.7);
draw_text(40, _by - 26, "1-7 pick   LMB place   RMB remove   Backspace clear   " + string(round(gmlmcp_tunable("bpm", 84))) + " BPM");
draw_set_alpha(1);
