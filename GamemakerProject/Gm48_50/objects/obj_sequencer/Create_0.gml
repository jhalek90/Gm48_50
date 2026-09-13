/// The step sequencer: objects stood on three ledges, struck by one playhead.
///
/// Drawn in front of the porch (-100), because the objects sit on top of the
/// ledges rather than behind them.
depth = -120;

// Bars completed since the room started. The music controller watches this to
// know when the pattern is back at the top of its loop, which is the only
// moment a new track can start without landing off the beat.
global.seq_bar = 0;

instruments_init();
tracks_init();
notepuff_init();

selected = 0;

// The face the randomiser is showing. Rolled again on every deal, so the
// button answers the click even on the deal that comes back looking like the
// board you already had.
dice_face = irandom_range(1, 6);

// One row of steps per track. Nested rather than flat so a row can be read,
// cleared or reasoned about on its own.
slots = array_create(SEQ_TRACKS);
flash = array_create(SEQ_TRACKS);

// The notes each slot was handed when its object was placed: one for every
// phase of the day and every half of it, in semitones from D. Kept beside the
// pattern rather than inside it, so a slot stays a plain instrument index and
// clearing the board cannot strand notes on nothing.
notes = array_create(SEQ_TRACKS);

for (var _t = 0; _t < SEQ_TRACKS; _t++) {
	slots[_t] = array_create(SEQ_STEPS, -1);
	flash[_t] = array_create(SEQ_STEPS, 0);
	notes[_t] = array_create(SEQ_STEPS);

	// Filled with a full set rather than left empty, so every slot holds the
	// same shape whether anything has been placed in it or not.
	for (var _i = 0; _i < SEQ_STEPS; _i++) {
		notes[_t][_i] = array_create(DAY_PHASES * MUSIC_SECTIONS, 0);
	}
}

// One playhead. It sweeps however many tracks there are, so a step fires all
// of their objects on the same tick rather than each row keeping its own clock
// — which is what would let rows drift against each other if more come back.
playhead = SEQ_STEPS - 1;
acc = 0;

// Set whenever the pattern changes, so the rain surfaces are rebuilt once per
// change instead of every frame.
dirty = true;
