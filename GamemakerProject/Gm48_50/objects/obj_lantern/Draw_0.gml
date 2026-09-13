if (!game_playing()) exit;

// The fitting first, then the light over it. Drawing the glow last lets it
// wash over the lantern's own metal and glass, which is what stops the body
// reading as a dark cut-out sitting in the middle of its own halo.
lantern_draw_body();
lantern_draw_glow();
