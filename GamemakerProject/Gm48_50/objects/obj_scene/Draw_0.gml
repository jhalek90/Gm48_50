var _h = global.persp_horizon;

// Every colour in this event comes from the day/night palette, which
// obj_daylight blends once per step. Nothing here decides what hour it is — it
// draws the same shapes at every time of day and is handed the paint.

// Sky, cloud deck and the two bodies, in one pass. The two-rectangle gradient
// this event used to draw now lives inside shd_sky, which is handed the same
// three palette colours and paints the weather over them — so the sun can go
// behind a cloud, which a gradient underneath a sprite could never do.
sky_draw(0, _h);

// The far range, standing on the horizon line. Bottom-left origin, so the
// horizon row is the draw position with no offset to remember.
//
// The sprite is tonal rather than coloured — white down through greys — and is
// multiplied by the palette here, so the shape comes from the art and the hour
// comes from the table. Baking colour into it would make the mountains the one
// thing in the scene that does not answer to the light.
draw_sprite_ext(spr_mountains, 0, 0, _h, 1, 1, 0, global.pal.shore, 1);

// Birds, after the range so they pass in front of it and before the lake so
// they can never be drawn over water they are nowhere near.
birds_draw();

// The lake. The gradient that used to be a two-colour rectangle now lives
// inside shd_water, which paints it and the wave field in one pass — the
// shader is handed the same two palette colours this event would have used.
water_draw(_h, room_height);

// The range, reflected. Drawn onto the lake rather than into it, so the wave
// bands the shader just laid down show through the image the way they would on
// real water.
water_reflect(spr_mountains, 0, _h,
	merge_colour(global.pal.shore, global.pal.water, 0.55),
	gmlmcp_tunable("reflect_alpha", 0.45));

// Mist on the water, over both the range and the lake — it lies on the join
// between them, and neither the sprite nor the water shader can reach across
// that line. Before the rocks and the duck, which stand in it.
mist_draw();

// The rocks standing in the shallows. Before the duck rather than after,
// because all of them sit further out than it does — depth order is the whole
// of the sorting here, and a rock drawn over the bird would put it underwater.
rocks_draw(true);

// The duck, on the lake: after the water and the reflections cast into it, and
// before the bank and the trees, so it floats on the surface and passes behind
// a trunk rather than across it.
duck_draw();

// The near bank, where the closest rain lands. The flat rectangle this used to
// be is now shd_grass: the rectangle is still under there as soil, with blades
// standing up out of it. They are allowed to reach above the waterline, which
// is what makes the bank meet the lake as a ragged edge rather than a ruled one.
grass_draw(BANK_Z);

// The dock. After the grass, because its near end runs up onto the bank and
// the grass would otherwise be painted straight over it — and after the duck,
// so that where the two cross the duck passes behind, which is what a duck
// near a jetty does.
//
// Before the bank rocks, the flowers and the trees: every one of those stands
// nearer than the dock's near end, so they are in front of it.
dock_draw();

// The rocks on the bank, after the grass so they sit in it rather than behind
// it. Only ever seen through the gaps between the balusters, which is the only
// way the bank is seen at all.
rocks_draw(false);

// The flowers in that grass, after the rocks so a blossom is never buried by
// a stone sitting further back than it.
flowers_draw();

// The trees are not drawn here any more. They stand *inside* the rain — some
// of the field in front of them, most of it behind — and depth order is the
// whole of the sorting, so they have to be their own objects at their own
// depths with the rain's two systems either side. See obj_trees.
