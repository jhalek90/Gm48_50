/// The volume faders.
///
/// Drawn in front of the sequencer (-120) so the faders sit over the porch
/// floor rather than under the objects standing on it, and behind the day
/// scrubber (-200) which is a development tool and has to stay on top of
/// everything while it exists.
depth = -150;

mixer_ensure();

// Which fader is being dragged, or -1. Held here rather than in the script
// because it is the state of this instance, not of the mix.
dragging = -1;
