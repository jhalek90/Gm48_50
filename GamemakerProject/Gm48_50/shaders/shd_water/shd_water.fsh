// Painterly, posterised lake water.
//
// The wave field is sampled on the ground plane, not on the screen. A
// fragment's screen y is turned back into a depth with the same 1/z projection
// the rain and the sequencer use, and the noise is read at that depth. Waves
// then compress toward the horizon on their own, with no per-distance special
// case anywhere, and the water belongs to the same space as the rain falling
// into it. Scrolling a flat noise texture across the screen would have been a
// tenth of the work and would have looked like a moving wallpaper, because
// nothing about it would agree with the perspective of the scene it sits in.

varying vec2 v_vRoom;
varying vec4 v_vColour;

uniform float u_time;

// The projection, handed over from scr_perspective rather than restated here,
// so there is one model of where the ground is instead of two that drift.
uniform float u_horizon;
uniform float u_ground_k;
uniform float u_z_far;
uniform float u_bottom;
uniform float u_centre;

// Palette, from the day/night table. The lake retints with the hour like
// everything else rather than being a fixed blue with waves drawn on it.
uniform vec3 u_far;
uniform vec3 u_near;
uniform vec3 u_glint;

uniform float u_pixel;   // block size in screen pixels
uniform float u_levels;  // posterisation bands
uniform float u_scale;   // wave size
uniform float u_speed;   // roll speed
uniform float u_stretch; // how far waves elongate across the view

float hash(vec2 p)
{
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);

	// Smoothstep weights rather than linear: linear interpolation between
	// lattice points leaves visible creases along the grid, and on water that
	// reads as a mesh rather than as a surface.
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(hash(i),                 hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p)
{
	float v = 0.0;
	float a = 0.5;

	// Four octaves. The lacunarity is 2.02 rather than 2.0 so successive
	// octaves do not share lattice lines and reinforce each other into a
	// visible grid.
	for (int i = 0; i < 4; i++)
	{
		v += a * vnoise(p);
		p *= 2.02;
		a *= 0.5;
	}
	return v;
}

void main()
{
	// Snap to a screen grid before anything else. Every value below is derived
	// from the block centre, so a whole block resolves to one flat colour —
	// that is the pixel in pixel art. Quantising at the end instead would only
	// posterise a smooth gradient and leave soft edges inside each block.
	vec2 sp = (floor(v_vRoom / u_pixel) + 0.5) * u_pixel;

	// Screen y back to depth, guarded away from the horizon where 1/z runs off
	// to infinity and the wave field would alias into static.
	float dy = max(sp.y - u_horizon, 1.0);
	float z  = min(u_ground_k / dy, u_z_far);

	// The plane itself. x spreads with depth, because a fixed span of screen
	// covers more water the further out it is; the depth axis scrolls toward
	// the viewer, so waves roll in at a constant speed through the world and
	// therefore appear to slow as they recede. Both fall out of the projection
	// rather than being tuned to look right.
	//
	// The ratio between these two coefficients is the entire character of the
	// surface, and it is not a free choice. Crests are lines of constant depth,
	// so the noise has to vary faster along depth than across the view; wind
	// the x term up instead and the features elongate along depth and the lake
	// turns into a starburst of streaks pointing at the vanishing point.
	vec2 w = vec2((sp.x - u_centre) * z * 0.00225 * u_scale * u_stretch,
	              z * 3.0 * u_scale - u_time * u_speed);

	float n = fbm(w);

	// Detail fades into the distance. Partly because far water genuinely reads
	// as flat haze, and partly because at this compression the noise out past
	// the middle distance puts several cycles inside one block, which boils
	// instead of rippling.
	float detail = smoothstep(u_z_far, 5.0, z);
	n = mix(0.5, n, detail);

	// Posterise. This is the whole look: a few flat tones with hard edges
	// between them, the way a painter blocks water in, rather than a smooth
	// gradient that reads as plastic.
	float bands = max(u_levels, 2.0);
	float q = clamp(floor(n * bands) / (bands - 1.0), 0.0, 1.0);

	// The base gradient is the one the scene already had: far water up at the
	// horizon, near water down at your feet.
	float g = clamp((sp.y - u_horizon) / max(u_bottom - u_horizon, 1.0), 0.0, 1.0);
	vec3 base = mix(u_far, u_near, g);

	// The bands become tone steps either side of that base colour.
	vec3 col = base * (0.74 + 0.52 * q);

	// The brightest band catches the sky. Reflecting the sky colour instead of
	// a fixed white is what keeps the glints warm at dawn and nearly gone at
	// night, with no second set of numbers to keep in step by hand.
	float crest = step(1.0 - 0.5 / (bands - 1.0), q);
	col = mix(col, u_glint, crest * 0.38 * detail);

	gl_FragColor = vec4(col, 1.0) * v_vColour;
}
