/// Rain, drawn between the distant scene and the porch you are sitting under.
///
/// Depth sits between obj_scene (60) and obj_porch (-100), and below the room's
/// Background layer at depth 100, which paints opaque black over anything
/// further back than itself.
depth = 30;

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
global.rain_splashes   = [];

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
// slice strike it. That is what produces the line of splashes running along
// the top rail while the rain on either side of it carries on to the ground.
surface_add(RAIL_Z_NEAR, RAIL_Z_FAR, -140, room_width + 140, RAIL_Y, "wood");

drops = [];
