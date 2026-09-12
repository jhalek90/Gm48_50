var _h = global.persp_horizon;

var _c_top   = make_colour_rgb(38, 42, 78);
var _c_mid   = make_colour_rgb(92, 84, 134);
var _c_warm  = make_colour_rgb(198, 126, 104);
var _c_water = make_colour_rgb(48, 60, 92);
var _c_near  = make_colour_rgb(28, 36, 54);

// Sky, split into two gradients so the warm band sits just above the horizon
// rather than washing the whole sky orange.
draw_rectangle_colour(0, 0, room_width, _h * 0.55, _c_top, _c_top, _c_mid, _c_mid, false);
draw_rectangle_colour(0, _h * 0.55, room_width, _h, _c_mid, _c_mid, _c_warm, _c_warm, false);

// Far shore, sitting on the horizon line.
draw_set_colour(make_colour_rgb(46, 54, 86));
draw_triangle(120, _h, 430, _h - 96, 760, _h, false);
draw_triangle(640, _h, 980, _h - 132, 1320, _h, false);

// The lake, darkening as it comes toward the porch.
draw_rectangle_colour(0, _h, room_width, room_height, _c_water, _c_water, _c_near, _c_near, false);

// A band of bank at the near edge of the water, where the closest rain lands.
draw_set_colour(make_colour_rgb(34, 44, 40));
draw_rectangle(0, ground_y(2.6), room_width, room_height, false);
