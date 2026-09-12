attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

varying vec2 v_vRoom;
varying vec4 v_vColour;

void main()
{
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
	v_vColour   = in_Colour;

	// Room coordinates, as in every other pass here. The porch is not placed by
	// the projection the way the lake and the bank are, but the grain still has
	// to sit on the same pixel grid as everything else.
	v_vRoom     = in_Position.xy;
}
