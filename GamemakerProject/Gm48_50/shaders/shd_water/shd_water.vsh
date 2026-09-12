attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

varying vec2 v_vRoom;
varying vec4 v_vColour;

void main()
{
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
	v_vColour   = in_Colour;

	// Room coordinates, straight off the vertex. The lake is a plain untextured
	// rectangle, so there is no meaningful texcoord to navigate by — and room
	// space is the space scr_perspective works in, which is what lets the
	// fragment shader use the game's own projection instead of inventing one.
	v_vRoom     = in_Position.xy;
}
