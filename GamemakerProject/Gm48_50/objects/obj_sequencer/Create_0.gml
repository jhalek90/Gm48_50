/// The step sequencer: objects stood on the railing, struck by a playhead.
///
/// Drawn in front of the porch (-100) and the porch splashes (-110), because
/// the objects sit on top of the railing rather than behind it.
depth = -120;

instruments_init();

selected = 0;
slots = array_create(SEQ_STEPS, -1);
flash = array_create(SEQ_STEPS, 0);

// Start one step before zero so the first tick lands on step 0, not step 1.
playhead = SEQ_STEPS - 1;
acc = 0;

// Set whenever the pattern changes, so the rain surfaces are rebuilt once per
// change instead of every frame.
dirty = true;
