// Painterly, posterised timber.
//
// One pass serves every piece of the porch. A member is described by its
// rectangle, its palette tone, and which way the grain runs; everything else —
// the plank divisions, the streaks, the seams, the lit edge — is derived from
// those. That is what keeps a roof, a post, a rail and a baluster looking like
// they were cut from the same wood, which they would not if each were given
// its own hand-tuned numbers.
//
// Unlike the lake, the sky and the bank, this pass does NOT work through
// scr_perspective. The porch is all within arms reach and sits at effectively
// one depth, so grain that shrank with distance would be inventing a depth
// cue the geometry does not have. Everything here is in plain screen space.

varying vec2 v_vRoom;
varying vec4 v_vColour;

// The member being drawn: x1, y1, x2, y2.
uniform vec4 u_rect;

// Its tone, from the day/night palette, so the porch darkens with the hour.
uniform vec3 u_base;

uniform float u_dir;    // 0 grain runs along x, 1 grain runs along y
uniform float u_plank;  // plank width across the grain, in pixels
uniform float u_seed;   // so two members of the same size are not twins

uniform float u_pixel;  // block size in screen pixels
uniform float u_levels; // posterisation bands
uniform float u_grain;  // streak strength
uniform float u_relief; // lit edge strength

// The scene key light, in room space, and how directional it is. Shared with
// the cloud shading, the shadows and the light shafts through sky_light().
uniform vec2  u_light;
uniform float u_key;

// How wet the timber is. Water fills the grain so less light scatters back out
// of the body of the board, and what does come back reflects off the surface
// film in a narrow band instead of across the whole face. Darker and sharper,
// not brighter.
uniform float u_wet;

float hash(vec2 p)
{
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(hash(i),                 hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p)
{
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++)
	{
		v += a * vnoise(p);
		p *= 2.02;
		a *= 0.5;
	}
	return v;
}

void main()
{
	// Snap to the same screen grid as the water, sky and grass, so a whole
	// block resolves to one flat colour.
	vec2 sp = (floor(v_vRoom / u_pixel) + 0.5) * u_pixel;

	// Work in grain-local axes: a runs along the grain, b across it. Writing it
	// this way means one set of arithmetic serves a horizontal rail and a
	// vertical post, instead of two near-copies that drift apart.
	float a  = mix(sp.x, sp.y, u_dir);
	float b  = mix(sp.y, sp.x, u_dir);
	float b0 = mix(u_rect.y, u_rect.x, u_dir);
	float b1 = mix(u_rect.w, u_rect.z, u_dir);

	// Which plank, and where across it.
	float span   = max(b1 - b0, 1.0);
	float plank  = floor((b - b0) / u_plank);
	float within = fract((b - b0) / u_plank);
	float pr     = hash(vec2(plank, u_seed));

	// The streaks. Sampled at a very low frequency along the grain and a high
	// one across it, which is the whole trick: noise stretched that far reads
	// as fibre running the length of the board. Equal frequencies would give
	// blotches, which is what stone looks like, not timber.
	//
	// Each plank is offset into a different part of the noise field so no two
	// boards carry the same figure.
	float g = fbm(vec2(a * 0.018 + pr * 37.0, b * 0.62));

	// Posterised before it is used, not after, so the streaks come out as flat
	// bands with hard edges rather than as a soft gradient that has been
	// stepped on afterwards.
	float bands = max(u_levels, 2.0);
	float q = floor(g * bands) / (bands - 1.0);

	// Plank to plank variation, around a mean that lands on the palette tone
	// rather than under it. Real boards are cut from different parts of the
	// tree and never match, so a wall of identical planks reads as wallpaper —
	// but the table in scr_daylight is what decides how bright the porch is at
	// a given hour, and a texture pass has no business quietly darkening it.
	float tone = 0.97 + (pr - 0.5) * 0.14;

	tone += u_grain * (q - 0.5);

	// The seam between boards. Dark right at the joint and nowhere else.
	float seam = smoothstep(0.0, 0.055, within) * smoothstep(1.0, 0.945, within);
	tone -= (1.0 - seam) * 0.18;

	// The lit edge of the member, falling off fast, on whichever side actually
	// faces the light. The light arrives in room space and is folded into the
	// same grain-local b axis as everything else, so one line serves a rail lit
	// from above and a post lit from whichever side the sun happens to be on.
	//
	// A horizontal member always resolves to lit-from-above, because the sun is
	// never below the porch. A vertical one flips as the light crosses it, and
	// that is the point: the posts are lit on their left at dawn and on their
	// right by evening, and the porch turns with the day without being told to.
	float lb       = mix(u_light.y, u_light.x, u_dir);
	float centre   = (b0 + b1) * 0.5;
	float from_lit = (lb < centre) ? (b - b0) : (b1 - b);

	float edge = pow(1.0 - clamp(from_lit / span, 0.0, 1.0), 2.5);
	tone += u_relief * u_key * (edge - 0.22);

	// Rain only reaches the upward faces. A post catches a fraction of what the
	// top of a rail does, which is the difference between wet timber and timber
	// that merely happens to be standing in the rain.
	float wet = u_wet * (1.0 - u_dir * 0.6);

	tone *= 1.0 - 0.10 * wet;
	tone += wet * 0.45 * pow(edge, 6.0) * u_key;

	// Quantise the finished tone too, so the shading lands on the same handful
	// of steps as the grain instead of sliding smoothly underneath it.
	// Rounded, not floored. Flooring throws away up to a whole band from every
	// pixel, which is a systematic darkening of half a band on average and was
	// costing the rails a quarter of their brightness.
	tone = floor(clamp(tone, 0.0, 1.6) * bands + 0.5) / bands;

	gl_FragColor = vec4(u_base * tone, 1.0) * v_vColour;
}
