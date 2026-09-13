/// The weather.
///
/// This object no longer draws anything. The field is a particle system —
/// see scr_rain_particles — which carries its own depth of 30, between
/// obj_scene at 60 and the porch at -100, and below the room's Background
/// layer at 100 which paints opaque black over anything further back.
///
/// What is left here is everything the particles cannot hold: the live
/// projection, the surface registry the rain lands on, and the audio.

// --- Projection -----------------------------------------------------------
// Defaults live here and are re-read from the live tunables every step, so the
// game starts correct and can still be re-tuned while it runs.
global.persp_surfaces  = [];
global.persp_horizon   = 300;
global.persp_ground_k  = 520;
global.persp_cloud_k   = 900;
global.persp_z_near    = 1.7;
global.persp_z_far     = 36;
global.rain_depth_bias = 1.0;

// --- Audio ----------------------------------------------------------------
global.rain_audio_gain  = 0.55;
global.rain_audio_pan   = 0.55;
global.rain_audio_depth = 34;
global.rain_audio_reach = 1.4;
global.rain_bed_gain    = 0.45;
global.rain_bed_track   = 0;
rain_audio_init();
rain_bed_start();

// --- Surfaces that catch rain --------------------------------------------
// The railing occupies a thin slice of depth, so only the drops inside that
// slice strike it. That is what puts a line of ticking along the top rail
// while the rain on either side of it carries on down to the ground.
surface_add(RAIL_Z_NEAR, RAIL_Z_FAR, -140, room_width + 140, RAIL_Y, "wood");

rain_particles_init();
