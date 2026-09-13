// Guarded against zero: the clock below consumes time in a loop, and a step
// length of zero would never drain the accumulator.
var _bpm = max(20, gmlmcp_tunable("bpm", SEQ_BPM));
var _secs = 60 / _bpm / SEQ_DIV;

// --- Input ---------------------------------------------------------------
// Held back until the title card is dismissed. Only input and interface stop
// there: the clock below keeps running, because it is what counts bars and the
// music controller starts every track on a bar boundary.
if (game_playing()) {
	for (var _k = 0; _k < instrument_count(); _k++) {
		if (keyboard_check_pressed(ord(string(_k + 1)))) selected = _k;
	}

	// The picker is clickable as well as keyed. Tested before the ledges and used
	// to lock them out, so a click on a button can never also drop an object —
	// the two areas do not overlap today, but a layout change should not be able
	// to turn one click into two actions.
	var _pick = seq_palette_at(mouse_x, mouse_y);
	if (_pick >= 0 && mouse_check_button_pressed(mb_left)) selected = _pick;

	// The randomiser, which sits in the same row and is locked out the same way.
	var _dice = seq_dice_at(mouse_x, mouse_y);
	if (_dice && mouse_check_button_pressed(mb_left)) {
		seq_randomise(slots, notes);
		dice_face = irandom_range(1, 6);
		dirty = true;
	}

	// The lantern is locked out the same way, though it hangs at the roof line
	// and the ledges are down at the railing. The two cannot overlap today —
	// but that was true of the picker and the ledges as well, and the rule here
	// is that a layout change must not be able to turn one click into two.
	var _free = (_pick < 0 && !_dice && !lantern_at(mouse_x, mouse_y));
	var _cell = _free ? seq_cell_at(mouse_x, mouse_y) : { track: -1, step: -1 };
	if (_cell.track >= 0) {
		var _row = slots[_cell.track];
		if (mouse_check_button_pressed(mb_left)) {
			if (_row[_cell.step] != selected) {
				_row[_cell.step] = selected;

				// One note per phase and half, rolled once, here. The object then
				// follows the day on its own: when the track hands over it already
				// knows what it should be playing in the new key, so the pattern the
				// player built survives into the next piece instead of going sour the
				// moment the music changes.
				notes[_cell.track][_cell.step] = music_roll_notes();

				dirty = true;
			} else {
				// Clicking a cell that already holds what you are carrying tunes it
				// rather than replacing it: one degree up the scale, wrapping at the
				// top. That is the note block rule, and it is why placing and tuning
				// can share a button — you cannot ask for the instrument that is
				// already standing there, so the only thing the click can mean is
				// "that again, higher". Reaching for a different one still paints
				// over, which is the behaviour anyone who has used the board expects.
				//
				// It sounds as it turns, at the pitch it just landed on. There is no
				// keyboard on screen and the number underneath is a scale degree, so
				// hearing it is the only way to know where the tuning got to; a
				// silent one would have to be discovered on the next pass of the
				// playhead, by which point the player has clicked four more times.
				var _trk  = global.tracks[_cell.track];
				var _sx   = track_slot_x(_cell.track, _cell.step);
				var _semi = music_note_bump(notes[_cell.track][_cell.step]);

				instrument_play(_row[_cell.step], _sx, _trk.y - _trk.size * 0.5, _trk.z,
					_semi);

				// Struck, as though the playhead had hit it, so the object lifts and
				// pales under the note leaving it — and throws the same note the
				// playhead would have thrown, through the same call, because a tuned
				// note and a played note are the same event seen from two places.
				flash[_cell.track][_cell.step] = 1;
				seq_throw_note(_cell.track, _cell.step, _semi);
			}
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

		// Read once and handed to both: the sound and the note drawn above it
		// have to be the same pitch, and calling music_note_now twice would let
		// them disagree across a phase boundary landing between the two lines.
		var _k    = global.tracks[_t];
		var _semi = music_note_now(notes[_t][playhead]);

		instrument_play(_ins, track_slot_x(_t, playhead), _k.y - _k.size * 0.5, _k.z, _semi);
		flash[_t][playhead] = 1;

		// Every strike shows its note, not just the ones the player asked for by
		// clicking. A pattern left running then reads back as colour: the same
		// degree is the same hue every time round, so a phrase has a shape you
		// can see as well as hear, and a note that moved at the handover says so
		// by coming up a different colour.
		seq_throw_note(_t, playhead, _semi);
	}
}

for (var _t = 0; _t < SEQ_TRACKS; _t++) {
	for (var _i = 0; _i < SEQ_STEPS; _i++) {
		flash[_t][_i] = max(0, flash[_t][_i] - 0.06);
	}
}

notepuff_step();
