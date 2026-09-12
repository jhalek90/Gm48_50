var _wood_dark = make_colour_rgb(34, 26, 24);
var _wood      = make_colour_rgb(58, 42, 34);
var _wood_lit  = make_colour_rgb(82, 60, 46);

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

// The railing. Its top edge is the surface the rain is told about in obj_rain,
// so this rectangle and that number have to agree — 448.
draw_set_colour(_wood_lit);
draw_rectangle(0, 448, room_width, 470, false);
draw_set_colour(_wood);
draw_rectangle(0, 470, room_width, 492, false);

// Balusters below the top rail.
draw_set_colour(_wood_dark);
for (var _x = 60; _x < room_width; _x += 78) {
	draw_rectangle(_x, 492, _x + 16, 596, false);
}
draw_set_colour(_wood);
draw_rectangle(0, 596, room_width, 618, false);

// Porch floor in the immediate foreground.
draw_set_colour(make_colour_rgb(42, 32, 28));
draw_rectangle(0, 660, room_width, room_height, false);
