/// The day/night cycle, and the debug scrubber that drives it.
///
/// Drawn in front of everything else (-200). The sequencer sits at -120 and the
/// porch roof at -100, and a development tool the roof can cover is not much
/// of a tool.
depth = -200;

daylight_init();

dragging = false;
show_ui  = true;
paused   = false;

// The value this object last pushed into the tunable registry. Anything else
// sitting there means the time was set from outside — see the Step event.
sent = undefined;
