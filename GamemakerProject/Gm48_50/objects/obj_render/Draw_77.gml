/// Blit the scene through the post chain.
///
/// Post Draw, not Draw End. Draw End still runs inside the application
/// surface, so drawing the surface from there would be drawing it into
/// itself; Post Draw is the first event that happens after it has been
/// resolved and is the one place this blit can legally live.
///
/// Stretched to the GUI size rather than the room size so the pass keeps
/// working the day the window stops being exactly one room across.
shader_set(shd_post);
shader_set_uniform_f(u_levels, gmlmcp_tunable("post_levels", 0));

draw_surface_stretched(
	application_surface, 0, 0,
	display_get_gui_width(), display_get_gui_height()
);

shader_reset();
