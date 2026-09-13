if (!game_playing()) exit;

// The fitting first, then the light over it. Drawing the glow last lets it
// wash over the lantern's own metal and glass, which is what stops the body
// reading as a dark cut-out sitting in the middle of its own halo.
lantern_draw_body();
lantern_draw_glow();

// The chime, on the other end of the roof. After the lantern's glow, so a
// chime close enough to catch it would be washed by it rather than cut out of
// it — they are far apart today, but the glow is a tunable and the day
// somebody widens it this should not need finding.
chime_draw();
