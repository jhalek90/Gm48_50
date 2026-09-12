// Painterly, posterised sky: two lights and a ceiling of cloud.
//
// The clouds sit on the ceiling plane the rain already falls out of. A
// fragment's screen y is turned back into a depth with `cloud_k / (horizon -
// y)` — the same inverse shd_water uses on the ground plane, mirrored — so the
// cloud deck and the lake are two halves of one projection. Overhead cloud is
// near and drifts fast, cloud near the horizon is far and crawls, and none of
// that is tuned: it falls out of the 1/z the rest of the scene is built on. A
// flat scrolling noise would have cost a tenth of this and would have read as
// a moving ceiling texture, because nothing about it would agree with the
// perspective it hangs over.
//
// "Volumetric" here means the cloud is lit by marching toward the light and
// asking how much cloud is in the way, rather than by shading a flat mask.
// That is what puts bright rims on the sunward side of each bank and leaves
// the undersides heavy, which is the thing that makes cloud read as bulk
// instead of as fog.

varying vec2 v_vRoom;
varying vec4 v_vColour;

uniform float u_time;

// The projection, handed over from scr_perspective rather than restated here,
// so there is one model of where the sky is instead of two that drift.
uniform float u_horizon;
uniform float u_cloud_k;
uniform float u_z_far;
uniform float u_centre;

// Palette, from the day/night table.
uniform vec3 u_top;
uniform vec3 u_mid;
uniform vec3 u_warm;
uniform vec3 u_cloud;
uniform vec3 u_cloud_lit;

// The two bodies. xy is screen position, z is visibility in [0,1], faded by
// GML as they cross the horizon — so nothing in here has to know the hour.
uniform vec3 u_sun;
uniform vec3 u_moon;
uniform vec3 u_sun_col;
uniform vec3 u_moon_col;
uniform float u_sun_r;
uniform float u_moon_r;
uniform float u_glow;

// Where the light comes from, already resolved by GML to whichever body is up.
// One position, so the shader never has to decide which light wins.
uniform vec2 u_light;

uniform float u_pixel;     // block size in screen pixels
uniform float u_levels;    // posterisation bands in the cloud
uniform float u_sky_bands; // posterisation bands in the sky gradient
uniform float u_scale;     // cloud size
uniform float u_speed;     // drift speed
uniform float u_stretch;   // how far banks elongate across the view
uniform float u_cover;     // how much of the sky is cloud
uniform float u_soft;      // edge softness before posterising
uniform float u_march;     // shadow march step, in screen pixels

float hash(vec2 p)
{
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);

	// Smoothstep weights rather than linear, for the reason shd_water uses
	// them: linear interpolation leaves visible creases along the lattice, and
	// on cloud that reads as a mesh rather than as a surface.
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(hash(i),                 hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Four octaves, for the shape you actually look at.
float fbm(vec2 p)
{
	float v = 0.0;
	float a = 0.5;

	// Lacunarity 2.02 rather than 2.0 so successive octaves do not share
	// lattice lines and reinforce each other into a visible grid.
	for (int i = 0; i < 4; i++)
	{
		v += a * vnoise(p);
		p *= 2.02;
		a *= 0.5;
	}
	return v;
}

// Two octaves, for the shadow march only. The march costs four more noise
// lookups per pixel on top of the ones above, and fine detail inside a shadow
// that is about to be quantised into a handful of tones is detail nobody will
// ever see.
float fbm2(vec2 p)
{
	return 0.5 * vnoise(p) + 0.25 * vnoise(p * 2.02);
}

// Screen position to a point on the cloud plane. Used by the main sample and
// by every step of the march, so the march cannot wander off the plane the
// cloud is actually on.
vec2 cloud_plane(vec2 sp)
{
	// Guarded away from the horizon, where 1/z runs off to infinity and the
	// field would alias into static.
	float dy = max(u_horizon - sp.y, 1.0);
	float z  = min(u_cloud_k / dy, u_z_far);

	// x spreads with depth, because a fixed span of screen covers more sky the
	// further out it is; the depth axis scrolls toward the viewer, so banks
	// drift overhead at a constant speed through the world and appear to slow
	// as they recede. Both fall out of the projection rather than being tuned.
	return vec2((sp.x - u_centre) * z * 0.0018 * u_scale * u_stretch,
	            z * 0.45 * u_scale - u_time * u_speed);
}

void main()
{
	// Snap to a screen grid first, exactly as the water does: every value below
	// is derived from the block centre, so a whole block resolves to one flat
	// colour. That is the pixel in pixel art. Quantising at the end instead
	// would only posterise a smooth gradient and leave soft edges inside each
	// block.
	vec2 sp = (floor(v_vRoom / u_pixel) + 0.5) * u_pixel;

	// --- The sky behind everything ---------------------------------------
	// The same two-segment gradient the scene drew as a pair of rectangles:
	// top to mid over the upper 55%, mid to the warm band down to the horizon.
	// Keeping the split is what stops the warm band from washing the whole sky.
	float g = clamp(sp.y / max(u_horizon, 1.0), 0.0, 1.0);
	vec3 sky = (g < 0.55)
		? mix(u_top, u_mid,  g / 0.55)
		: mix(u_mid, u_warm, (g - 0.55) / 0.45);

	// Banded separately from the cloud, and more finely. This gradient runs the
	// full height of the screen, so at cloud band counts it would stripe the
	// sky like a test card.
	float sb = max(u_sky_bands, 2.0);
	sky = floor(sky * sb + 0.5) / sb;

	// --- The two bodies ---------------------------------------------------
	// Drawn before the cloud and composited under it, so a bank crossing the
	// sun genuinely hides it rather than merely being tinted by it.
	float d_sun  = distance(sp, u_sun.xy);
	float d_moon = distance(sp, u_moon.xy);

	// Glow first. Quantised like everything else, which turns what would be a
	// smooth falloff into concentric rings — the way a pixel artist draws a
	// light source, and the reason it is posterised here rather than left to
	// the post pass.
	float gb = max(u_levels, 2.0);
	float halo_sun  = pow(max(0.0, 1.0 - d_sun  / (u_sun_r  * u_glow)), 2.5) * u_sun.z;
	float halo_moon = pow(max(0.0, 1.0 - d_moon / (u_moon_r * u_glow)), 2.5) * u_moon.z;
	halo_sun  = floor(halo_sun  * gb) / gb;
	halo_moon = floor(halo_moon * gb) / gb;

	sky = mix(sky, u_sun_col,  halo_sun  * 0.55);
	sky = mix(sky, u_moon_col, halo_moon * 0.45);

	// Then the discs. A hard step rather than a smoothstep: an antialiased edge
	// inside a block that is meant to be one flat colour is the one thing that
	// would give the pixel grid away.
	float disc_sun  = (1.0 - step(u_sun_r,  d_sun))  * u_sun.z;
	float disc_moon = (1.0 - step(u_moon_r, d_moon)) * u_moon.z;

	sky = mix(sky, u_sun_col,  disc_sun);
	sky = mix(sky, u_moon_col, disc_moon);

	// --- The cloud deck ---------------------------------------------------
	float density = fbm(cloud_plane(sp));

	// Cover is a threshold on the noise rather than a multiplier on the result,
	// so raising it grows the existing banks outward instead of fading a full
	// sky of cloud up from nothing. The weather gets thicker; it does not
	// simply get more opaque.
	float edge  = 1.0 - u_cover;
	float alpha = smoothstep(edge - u_soft, edge + u_soft, density);

	// March toward the light, accumulating what is in the way. Four steps is
	// enough to separate a sunward face from a shaded one, which is all the
	// depth cue a posterised cloud can carry anyway.
	float shade = 0.0;
	vec2 dir = normalize(u_light - sp + vec2(0.0001, 0.0001));
	for (int i = 0; i < 4; i++)
	{
		shade += fbm2(cloud_plane(sp + dir * float(i + 1) * u_march));
	}
	shade *= 0.25;

	// Into a lit term, then posterised. The bands are the whole look: a few
	// flat tones with hard edges, the way cloud gets blocked in by hand.
	float cb = max(u_levels, 2.0);
	float lit = clamp((0.62 - shade) * 2.6, 0.0, 1.0);
	lit = clamp(floor(lit * cb) / (cb - 1.0), 0.0, 1.0);

	vec3 cloud_col = mix(u_cloud, u_cloud_lit, lit);

	// Distant cloud settles toward the sky colour. Partly because far cloud
	// genuinely reads as haze, and partly because at this compression the noise
	// down near the horizon puts several cycles inside one block, which boils
	// instead of drifting.
	float dy   = max(u_horizon - sp.y, 1.0);
	float z    = min(u_cloud_k / dy, u_z_far);
	float haze = smoothstep(u_z_far, 6.0, z);

	cloud_col = mix(sky, cloud_col, 0.35 + 0.65 * haze);
	alpha    *= haze;

	// Quantise the coverage too, so cloud edges land on the block grid instead
	// of feathering across it.
	alpha = floor(clamp(alpha, 0.0, 1.0) * cb + 0.5) / cb;

	vec3 col = mix(sky, cloud_col, alpha);

	gl_FragColor = vec4(col, 1.0) * v_vColour;
}
