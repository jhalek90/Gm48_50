/// The porch lantern.
///
/// Drawn in front of the porch (-100) and the sequencer's objects (-120),
/// because the light it throws has to land on both — the timber it hangs from
/// and whatever is standing on the railing under it. It stays behind the
/// mixer (-150) and the scrubber (-200), which are interface and belong over
/// everything.
depth = -140;

lantern_init();

// The chime hangs from the same roof at the same depth, and is the same kind
// of thing — something dangling in the one wind — so it rides along here
// rather than earning an object of its own.
chime_init();
