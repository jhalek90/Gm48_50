attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

varying vec2 v_vRoom;
varying vec4 v_vColour;

void main()
{
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
	v_vColour   = in_Colour;

	// Room coordinates, as in shd_water and for the same reason: room space is
	// the space scr_perspective works in, so the fragment shader can use the
	// game's own projection rather than inventing a second one that drifts.
	v_vRoom     = in_Position.xy;
}
