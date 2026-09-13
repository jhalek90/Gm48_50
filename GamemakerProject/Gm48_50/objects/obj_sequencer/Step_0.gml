// Guarded against zero: the clock below consumes time in a loop, and a step
// length of zero would never drain the accumulator.
var _bpm = max(20, gmlmcp_tunable("bpm", SEQ_BPM));
var _secs = 60 / _bpm / 4;

// --- Input ---------------------------------------------------------------
for (var _k = 0; _k < instrument_count(); _k++) {
	if (keyboard_check_pressed(ord(string(_k + 1)))) selected = _k;
}

// The picker is clickable as well as keyed. Tested before the ledges and used
// to lock them out, so a click on a button can never also drop an object —
// the two areas do not overlap today, but a layout change should not be able
// to turn one click into two actions.
var _pick = seq_palette_at(mouse_x, mouse_y);
if (_pick >= 0 && mouse_check_button_pressed(mb_left)) selected = _pick;

var _cell = (_pick >= 0) ? { track: -1, step: -1 } : seq_cell_at(mouse_x, mouse_y);
if (_cell.track >= 0) {
	var _row = slots[_cell.track];
	if (mouse_check_button_pressed(mb_left) && _row[_cell.step] != selected) {
		_row[_cell.step] = selected;

		// One note per phase and half, rolled once, here. The object then
		// follows the day on its own: when the track hands over it already
		// knows what it should be playing in the new key, so the pattern the
		// player built survives into the next piece instead of going sour the
		// moment the music changes.
		notes[_cell.track][_cell.step] = music_roll_notes();

		dirty = true;
	}
	if (mouse_check_button_pressed(mb_right) && _row[_cell.step] != -1) {
		_row[_cell.step] = -1;
		dirty = true;
	}
}

if (keyboard_check_pressed(vk_backspace)) {
	for (var _t = 0; _t < SEQ_TRACKS; _t++) {
		for (var _i = 0; _i < SEQ_STEPS; _i++) slots[_t][_i] = -1;
	}
	dirty = true;
}

// Rebuilt here rather than in Create so it cannot depend on which instance's
// Create event the room happens to run first.
if (dirty) {
	seq_rebuild_surfaces(slots);
	dirty = false;
}

// --- Clock ---------------------------------------------------------------
// Real elapsed time is accumulated and consumed in a loop. A dropped frame
// makes the sequencer catch up on the next one instead of falling permanently
// behind, so the pattern does not drift away from the beat over minutes.
acc += delta_time / 1000000;
while (acc >= _secs) {
	acc -= _secs;
	playhead = (playhead + 1) mod SEQ_STEPS;
	if (playhead == 0) global.seq_bar++;

	for (var _t = 0; _t < SEQ_TRACKS; _t++) {
		var _ins = slots[_t][playhead];
		if (_ins < 0) continue;

		var _k = global.tracks[_t];
		instrument_play(_ins, track_slot_x(_t, playhead), _k.y - _k.size * 0.5, _k.z,
			music_note_now(notes[_t][playhead]));
		flash[_t][playhead] = 1;
	}
}

for (var _t = 0; _t < SEQ_TRACKS; _t++) {
	for (var _i = 0; _i < SEQ_STEPS; _i++) {
		flash[_t][_i] = max(0, flash[_t][_i] - 0.06);
	}
}
