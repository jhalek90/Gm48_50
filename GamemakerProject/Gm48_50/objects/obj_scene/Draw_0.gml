var _h = global.persp_horizon;

// Every colour in this event comes from the day/night palette, which
// obj_daylight blends once per step. Nothing here decides what hour it is — it
// draws the same shapes at every time of day and is handed the paint.

// Sky, cloud deck and the two bodies, in one pass. The two-rectangle gradient
// this event used to draw now lives inside shd_sky, which is handed the same
// three palette colours and paints the weather over them — so the sun can go
// behind a cloud, which a gradient underneath a sprite could never do.
sky_draw(0, _h);

// Far shore, sitting on the horizon line.
draw_set_colour(global.pal.shore);
draw_triangle(120, _h, 430, _h - 96, 760, _h, false);
draw_triangle(640, _h, 980, _h - 132, 1320, _h, false);

// The lake. The gradient that used to be a two-colour rectangle now lives
// inside shd_water, which paints it and the wave field in one pass — the
// shader is handed the same two palette colours this event would have used.
water_draw(_h, room_height);

// The near bank, where the closest rain lands. The flat rectangle this used to
// be is now shd_grass: the rectangle is still under there as soil, with blades
// standing up out of it. They are allowed to reach above the waterline, which
// is what makes the bank meet the lake as a ragged edge rather than a ruled one.
grass_draw(BANK_Z);

// The trees on that bank. After the grass so they stand in it rather than
// behind it, and inside this event so the rain object still falls in front.
trees_draw();
