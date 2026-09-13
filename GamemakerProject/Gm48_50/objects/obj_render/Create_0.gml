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


// The interface font, set once.
//
// Unlike colour, alpha and alignment — which every draw event here sets for
// itself, because they change from line to line — the font barely changes:
// every piece of interface in the game wants this one, and setting it at each
// call site would be four copies of a decision nobody is going to make
// differently. The title card is the single exception, and it does what that
// earns — sets fntLogo where it is used and puts this back afterwards.
//
// It lives beside the render path rather than in a controller because both are
// the same kind of thing: how the game draws, said once, before anything
// draws.
draw_set_font(fntPixels);

// Looked up once, not per frame.
u_levels      = shader_get_uniform(shd_post, "u_levels");
u_light       = shader_get_uniform(shd_post, "u_light");
u_ray         = shader_get_uniform(shd_post, "u_ray");
u_ray_density = shader_get_uniform(shd_post, "u_ray_density");
u_ray_decay   = shader_get_uniform(shd_post, "u_ray_decay");
u_ray_weight  = shader_get_uniform(shd_post, "u_ray_weight");
u_ray_thresh  = shader_get_uniform(shd_post, "u_ray_thresh");
