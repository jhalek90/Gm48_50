/// Blit the scene through the post chain.
///
/// Post Draw, not Draw End. Draw End still runs inside the application
/// surface, so drawing the surface from there would be drawing it into
/// itself; Post Draw is the first event that happens after it has been
/// resolved and is the one place this blit can legally live.
///
/// --- Where the surface goes -------------------------------------------
///
/// Asked for, not computed. It used to be stretched across the whole GUI,
/// which is right only while the window happens to share the room's aspect.
/// Go fullscreen on an ultrawide and the GUI is 2560x1080 against a 1366x768
/// room, and the picture came out stretched a third wider than it should be.
///
/// application_get_position answers with the rectangle GameMaker itself would
/// have drawn the surface into, letterboxing included. Using it rather than
/// deriving the same thing by hand matters for more than tidiness: that is the
/// rectangle GameMaker maps mouse_x and mouse_y through, so the picker, the
/// faders and the board all stay clickable in fullscreen. Work the letterbox
/// out independently and the interface would be off by the size of the bars.
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

// And where the sky stops. In texture coordinates, because this pass works on
// the surface rather than in room space — the same reason the light position
// is handed over that way.
//
// Defaulted to the horizon itself, which is the line the scene is built around.
// Push it down to let the lake glitter throw shafts again; push it up to keep
// even the far bank out of the effect.
shader_set_uniform_f(u_ray_floor,
	gmlmcp_tunable("ray_floor", global.persp_horizon / room_height));

var _at = application_get_position();

// The bars either side. Cleared every frame because nothing else draws there,
// and without it the letterbox holds whatever the back buffer had in it last.
draw_clear(c_black);

draw_surface_stretched(
	application_surface,
	_at[0], _at[1],
	_at[2] - _at[0], _at[3] - _at[1]
);

shader_reset();
