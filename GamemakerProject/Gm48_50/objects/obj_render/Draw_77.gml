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

// Light shafts, thrown from the same key the porch and the shadows use. The
// position is handed over in texture coordinates because this pass works on
// the application surface rather than in room space.
//
// Strength is scaled by how strong the key is, so the shafts fade out through
// dusk on their own and the moon throws only a trace of them. When the sun is
// behind a thick bank of cloud the threshold finds nothing bright to gather
// and the effect disappears by itself, which is the behaviour you would want
// anyway and costs nothing to arrange.
var _l = global.light;
shader_set_uniform_f_array(u_light, [_l.x / room_width, _l.y / room_height]);
shader_set_uniform_f(u_ray, gmlmcp_tunable("ray_strength", 1.6) * _l.strength);
shader_set_uniform_f(u_ray_density, gmlmcp_tunable("ray_density", 1.0));
shader_set_uniform_f(u_ray_decay,   gmlmcp_tunable("ray_decay",   0.96));
shader_set_uniform_f(u_ray_weight,  gmlmcp_tunable("ray_weight",  0.90));
// The threshold is the effect. It has to sit above the lit cloud tone, or
// every cloud in the sky emits and the shafts come out as a flat bloom over
// the whole frame rather than as beams from one bright break. Lit cloud runs
// about 0.83 luminance at the brightest hour, which is where this is set.
shader_set_uniform_f(u_ray_thresh,  gmlmcp_tunable("ray_thresh",  0.83));

draw_surface_stretched(
	application_surface, 0, 0,
	display_get_gui_width(), display_get_gui_height()
);

shader_reset();
