// A sprite as a flat silhouette.
//
// The sprite supplies only its shape; the colour comes entirely from the blend
// colour. That is the one thing a blend colour cannot do on its own, because it
// multiplies — so it can take light away but never wash a thing toward the
// colour behind it, which is exactly what distance does to a shape.
//
// Used to lay air in front of the trees: the same sprite, same frame, filled
// with the colour of the lake they stand against, at the strength their depth
// calls for. The silhouette masks it perfectly because it is the silhouette.

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
	gl_FragColor = vec4(v_vColour.rgb,
	                    v_vColour.a * texture2D(gm_BaseTexture, v_vTexcoord).a);
}
