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

void main()
{
	vec4 c = texture2D(gm_BaseTexture, v_vTexcoord);

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
