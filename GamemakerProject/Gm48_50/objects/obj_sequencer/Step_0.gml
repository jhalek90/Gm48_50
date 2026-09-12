// Guarded against zero: the clock below consumes time in a loop, and a step
// length of zero would never drain the accumulator.
var _bpm = max(20, gmlmcp_tunable("bpm", 84));
var _secs = 60 / _bpm / 4;

// --- Input ---------------------------------------------------------------
for (var _k = 0; _k < instrument_count(); _k++) {
	if (keyboard_check_pressed(ord(string(_k + 1)))) selected = _k;
}

var _hover = seq_slot_at(mouse_x);
if (_hover >= 0) {
	if (mouse_check_button_pressed(mb_left) && slots[_hover] != selected) {
		slots[_hover] = selected;
		dirty = true;
	}
	if (mouse_check_button_pressed(mb_right) && slots[_hover] != -1) {
		slots[_hover] = -1;
		dirty = true;
	}
}

if (keyboard_check_pressed(vk_backspace)) {
	for (var _i = 0; _i < SEQ_STEPS; _i++) slots[_i] = -1;
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

	var _ins = slots[playhead];
	if (_ins >= 0) {
		instrument_play(_ins, seq_slot_x(playhead));
		flash[playhead] = 1;
	}
}

for (var _i = 0; _i < SEQ_STEPS; _i++) flash[_i] = max(0, flash[_i] - 0.06);
