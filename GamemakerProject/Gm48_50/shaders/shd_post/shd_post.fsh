// The full-screen pass.
//
// The scene renders to the application surface exactly as it always did, and
// obj_render draws that surface once through here. This is the hook every
// later screen effect hangs off — a LUT, a colour grade, grain, a vignette,
// a scanline — and none of them will need the game to change how it draws.
//
// Posterisation is wired up now because the water wanted it, and because a
// pipeline with nothing in it is a pipeline nobody can tell is working.
// Anything added later is a uniform and a few lines in this file.

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Levels below 2 disable the quantisation and leave the pass a straight blit,
// which is the default: the pipeline should be provably neutral until someone
// asks it for something.
uniform float u_levels;

// Light shafts.
//
// Deliberately NOT built on a depth buffer. Shafts need to know which pixels
// are sky the light comes through and which are blocking it, and that is an
// occlusion question, not a depth one. The scene already answers it: the sky
// is the brightest thing in frame and every occluder — porch, trees, water,
// mountains — is darker, so a luminance threshold separates them for free.
// A depth target would cost a second pass over every surface and a standing
// rule that anything drawn from now on has to write depth or the lighting
// silently breaks.
uniform vec2  u_light;       // the key light, in texture coordinates
uniform float u_ray;         // overall strength; zero skips the whole pass
uniform float u_ray_density; // how far along the ray the samples reach
uniform float u_ray_decay;   // falloff per step
uniform float u_ray_weight;
uniform float u_ray_thresh;  // luminance above which a pixel counts as sky

const int RAY_STEPS = 24;

// What a pixel contributes as a light source.
vec3 emitter(vec2 uv)
{
	vec3 s = texture2D(gm_BaseTexture, uv).rgb;
	float l = dot(s, vec3(0.2126, 0.7152, 0.0722));
	return s * smoothstep(u_ray_thresh, u_ray_thresh + 0.14, l);
}

// March from this pixel toward the light, gathering what is bright along the
// way and fading with distance. Where the path crosses a baluster, a post or a
// tree the emitter term drops to nothing, and the gap in the gathered light is
// the shadow in the beam.
vec3 shafts(vec2 uv)
{
	vec2  delta = (uv - u_light) * (u_ray_density / float(RAY_STEPS));
	vec2  coord = uv;
	float illum = 1.0;
	vec3  acc   = vec3(0.0);

	for (int i = 0; i < RAY_STEPS; i++)
	{
		coord -= delta;
		acc   += emitter(clamp(coord, 0.0, 1.0)) * illum * u_ray_weight;
		illum *= u_ray_decay;
	}

	return acc / float(RAY_STEPS);
}

void main()
{
	vec4 c = texture2D(gm_BaseTexture, v_vTexcoord);

	// Added before the posterise, not after, so the shafts land on the same
	// tone steps as everything else instead of being the one smooth thing in a
	// banded picture.
	if (u_ray > 0.001)
	{
		c.rgb += shafts(v_vTexcoord) * u_ray;
	}

	if (u_levels >= 2.0)
	{
		// Quantised per channel on the finished image rather than per object,
		// so everything in the frame lands on the same set of tones. That
		// shared palette is what makes a posterised picture hold together
		// instead of looking like several separately banded layers.
		c.rgb = floor(c.rgb * u_levels + 0.5) / u_levels;
	}

	gl_FragColor = c * v_vColour;
}
