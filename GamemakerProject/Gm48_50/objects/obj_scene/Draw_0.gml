var _h = global.persp_horizon;

// Every colour here comes from the day/night palette, which obj_daylight
// blends once per step. Nothing in this event decides what hour it is — it
// draws the same shapes at every time of day and is handed the paint.
var _c_top   = global.pal.sky_top;
var _c_mid   = global.pal.sky_mid;
var _c_warm  = global.pal.sky_warm;
var _c_water = global.pal.water;
var _c_near  = global.pal.water_near;

// Sky, split into two gradients so the warm band sits just above the horizon
// rather than washing the whole sky orange.
draw_rectangle_colour(0, 0, room_width, _h * 0.55, _c_top, _c_top, _c_mid, _c_mid, false);
draw_rectangle_colour(0, _h * 0.55, room_width, _h, _c_mid, _c_mid, _c_warm, _c_warm, false);

// Far shore, sitting on the horizon line.
draw_set_colour(global.pal.shore);
draw_triangle(120, _h, 430, _h - 96, 760, _h, false);
draw_triangle(640, _h, 980, _h - 132, 1320, _h, false);

// The lake, darkening as it comes toward the porch.
draw_rectangle_colour(0, _h, room_width, room_height, _c_water, _c_water, _c_near, _c_near, false);

// A band of bank at the near edge of the water, where the closest rain lands.
draw_set_colour(global.pal.bank);
draw_rectangle(0, ground_y(2.6), room_width, room_height, false);
