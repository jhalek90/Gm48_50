/// The render pipeline.
///
/// The scene draws to the application surface exactly as it did before. What
/// changes here is the last step: GameMaker's automatic blit of that surface
/// is turned off and this object does it instead, as one full-screen pass
/// through shd_post.
///
/// That single pass is the point. Every screen effect the game might want
/// later — a LUT, a colour grade, grain, a vignette, a scanline — hangs off
/// it, and none of them will need any other object to change how it draws.
/// Retrofitting this once the scene is full of objects is far more work than
/// putting it in while there are six.
application_surface_draw_enable(false);

// Looked up once, not per frame.
u_levels      = shader_get_uniform(shd_post, "u_levels");
u_light       = shader_get_uniform(shd_post, "u_light");
u_ray         = shader_get_uniform(shd_post, "u_ray");
u_ray_density = shader_get_uniform(shd_post, "u_ray_density");
u_ray_decay   = shader_get_uniform(shd_post, "u_ray_decay");
u_ray_weight  = shader_get_uniform(shd_post, "u_ray_weight");
u_ray_thresh  = shader_get_uniform(shd_post, "u_ray_thresh");
