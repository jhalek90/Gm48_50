// Painterly, posterised grass, blade by blade.
//
// Blades are not a texture here, they are solved for. A blade of fixed world
// height rooted at depth zr has its base on the ground curve
// `horizon + ground_k/zr` and its tip on `horizon + (ground_k - k)/zr` — which
// is another curve of the same 1/z family. So the question "which blades can
// reach this pixel" has a closed form: exactly those rooted between the
// pixel depth and a fixed fraction nearer. No search, no depth buffer, and the
// grass belongs to the same projection as the lake it runs down to.
//
// Rows of blades are spaced geometrically rather than evenly, for the same
// reason: a constant ratio in `q = y - horizon` is a constant number of rows
// inside that reach at every distance. Rows crowd together toward the water
// and open out toward the porch on their own, and the shader checks a fixed
// three of them per pixel wherever it looks.
//
// The wind only bends blades; it never moves them. Grass is rooted, and the
// scrolling trick the water and the cloud both use would read here as the
// whole bank sliding sideways.

varying vec2 v_vRoom;
varying vec4 v_vColour;

uniform float u_time;

// The projection, handed over from scr_perspective rather than restated here.
uniform float u_horizon;
uniform float u_ground_k;
uniform float u_z_near;
uniform float u_centre;

// Screen row where the bank meets the water. Above it there is no soil, only
// whatever blades reach up from below, so the waterline comes out ragged
// instead of being a ruled edge.
uniform float u_edge;

// Palette, from the day/night table.
uniform vec3 u_bank;
uniform vec3 u_grass;
uniform vec3 u_grass_lit;

uniform float u_pixel;    // block size in screen pixels
uniform float u_levels;   // posterisation bands
uniform float u_blade_w;  // blade width at the near plane, screen px
uniform float u_blade_len;// blade height at the near plane, screen px
uniform float u_rstep;    // ratio between adjacent blade rows
uniform float u_wind_amp; // lean, as a fraction of blade spacing
uniform float u_wind_freq;// gust wavelength across the field
uniform float u_wind_speed;

float hash(vec2 p)
{
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main()
{
	// Snap to a screen grid first, exactly as the water and the sky do: every
	// value below is derived from the block centre, so a whole block resolves
	// to one flat colour. That is the pixel in pixel art.
	vec2 sp = (floor(v_vRoom / u_pixel) + 0.5) * u_pixel;

	// This pixel, as a distance below the horizon. Everything downstream works
	// in q rather than in depth: q is linear in screen space, which is what
	// makes the row spacing below a plain geometric series.
	float q = max(sp.y - u_horizon, 1.0);

	// The row whose base sits just below this pixel. Rows above it are farther
	// away and cannot reach up this high, so the search starts here.
	float lq  = log(q) / log(u_rstep);
	float r0  = floor(lq);

	// The waterline, in the same units as the rows. u_edge arrives as an
	// absolute screen row and q is measured down from the horizon, so the two
	// are only comparable after this.
	float edge_q = max(u_edge - u_horizon, 1.0);

	// Nearest hit wins. Tracked by base offset rather than by loop order: a
	// blade rooted lower on the screen is nearer the viewer and draws over one
	// rooted higher, whichever order the rows happen to come out in.
	float best_q = -1.0;
	float best_t = 0.0;
	float best_r = 0.0;

	for (int i = 0; i < 3; i++)
	{
		float row = r0 + float(i);
		float qr  = pow(u_rstep, row + 0.5);

		// Skip rows whose base is above this pixel, and rows out on the water
		// where nothing is rooted.
		if (qr >= q && qr >= edge_q)
		{
			// Size at this row. sc is the perspective scale written in terms of
			// q, since zr = ground_k / qr — one division saved on a line that
			// runs nine times a pixel.
			float sc     = u_z_near * qr / u_ground_k;
			float base_y = u_horizon + qr;
			float colw   = max(u_blade_w * sc, 1.0);
			float halfc  = colw * 0.5;

			// Every column a leaning blade could have come from. The lean is
			// clamped to 1.5 columns below, so this span is exactly wide
				// enough and no wider: each extra column costs a hash on every
				// pixel of the bank.
			for (int c = -2; c <= 2; c++)
			{
				float cell = floor(sp.x / colw) + float(c);
				float rnd  = hash(vec2(cell, row));
				float rnd2 = hash(vec2(cell, row) + 31.7);

				// A wide spread of heights. A narrow one gives the field a flat
				// top, which reads as a clipped hedge rather than as grass.
				float h = u_blade_len * sc * (0.4 + 1.15 * rnd);
				float t = (base_y - sp.y) / h;

				if (t >= 0.0 && t <= 1.0)
				{
					// Gust phase in world x, not screen x, so a gust crosses the
					// field at one speed instead of appearing to accelerate as
					// it comes toward the viewer.
					// Roots jittered off the cell centre. On a perfect grid the
					// blades line up into stripes, which is the single thing that
					// stops a field of them reading as grass at all.
					float root_x = (cell + 0.5 + (rnd2 - 0.5) * 0.75) * colw;
					float world_x = (root_x - u_centre) / max(sc, 0.0001);

					// Two scales of wind: a fast ripple that gives each blade its
					// own motion, inside a slow envelope that sends the whole
					// bank over together. One alone reads as either static or as
					// a shiver.
					float gust = sin(world_x * u_wind_freq - u_time * u_wind_speed + rnd * 6.283);
					float env  = 0.55 + 0.45 * sin(world_x * u_wind_freq * 0.17
					                               - u_time * u_wind_speed * 0.38);

					// Lean measured in column widths. A fraction of a column reads as
					// a shiver rather than as wind, and this number is what the
					// column span above has to be kept in step with.
					float lean = clamp(gust * env * u_wind_amp, -1.5, 1.5) * colw;

					// Quadratic in t: a blade is stiff at the root and gives at
					// the tip, which is the difference between grass bending and
					// grass toppling.
					float cx    = root_x + lean * t * t;
					// Narrow enough that soil shows between the blades. Near full
					// cell width the field tiles solid and goes back to being the
					// painted rectangle this replaced.
					float halfw = halfc * 0.5 * (1.0 - 0.65 * t);

					if (abs(sp.x - cx) < halfw && qr > best_q)
					{
						best_q = qr;
						best_t = t;
						best_r = rnd2;
					}
				}
			}
		}
	}

	float bands = max(u_levels, 2.0);

	// The soil the blades stand in. Above the waterline there is none, so the
	// pass leaves those pixels alone and the lake shows through.
	vec3  col = u_bank;
	float a   = (sp.y >= u_edge) ? 1.0 : 0.0;

	if (best_q > 0.0)
	{
		// Tips catch the light and roots sit in shadow, with a per-blade offset
		// so neighbours do not all shade identically. Posterised into the same
		// handful of tones as everything else in the scene.
		// Weighted toward the per-blade value rather than toward height,
		// so neighbours separate by tone. Grading purely by height makes
		// every blade in the field the same blade at a different length.
		float shade = clamp(best_t * 0.42 + best_r * 0.6, 0.0, 1.0);
		shade = clamp(floor(shade * bands) / (bands - 1.0), 0.0, 1.0);

		col = mix(u_grass, u_grass_lit, shade);
		a   = 1.0;
	}

	gl_FragColor = vec4(col, a) * v_vColour;
}
