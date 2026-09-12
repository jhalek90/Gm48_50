// Wood from the day/night palette: the porch is lit by the same sky the lake
// is, so it has to darken with it or the scene comes apart at dusk.
var _wood_dark = global.pal.wood_dark;
var _wood      = global.pal.wood;
var _wood_lit  = global.pal.wood_lit;

// Roof overhang. The rain is drawn beneath this, so the underside of the roof
// cuts the top off the falling field the way a real porch roof would.
draw_set_colour(_wood_dark);
draw_rectangle(0, 0, room_width, 96, false);
draw_set_colour(_wood);
draw_rectangle(0, 96, room_width, 112, false);

// Posts holding it up.
draw_set_colour(_wood_dark);
draw_rectangle(24, 112, 96, room_height, false);
draw_rectangle(room_width - 96, 112, room_width - 24, room_height, false);

// The railing. Its top edge is the surface the rain lands on and the shelf the
// sequencer stands objects on, so it is drawn from the shared RAIL_Y.
draw_set_colour(_wood_lit);
draw_rectangle(0, RAIL_Y, room_width, RAIL_Y + 22, false);
draw_set_colour(_wood);
draw_rectangle(0, RAIL_Y + 22, room_width, RAIL_Y + 44, false);

// Balusters below the top rail.
draw_set_colour(_wood_dark);
for (var _x = 60; _x < room_width; _x += 78) {
	draw_rectangle(_x, RAIL_Y + 44, _x + 16, 596, false);
}
draw_set_colour(_wood);
draw_rectangle(0, 596, room_width, 618, false);

// Porch floor in the immediate foreground. Mixed from the two wood tones
// rather than given a palette entry of its own — it is a shade between them at
// every hour, so deriving it keeps one less colour in step by hand.
draw_set_colour(merge_colour(_wood_dark, _wood, 0.35));
draw_rectangle(0, 660, room_width, room_height, false);
