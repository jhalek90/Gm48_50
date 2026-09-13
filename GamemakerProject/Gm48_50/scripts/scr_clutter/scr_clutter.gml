/// The things left on the porch that are not instruments.
///
/// A porch reads as lived on because of what has been put down on it and not
/// picked up again. The railing has eight objects on it, but every one of them
/// is placed by the player and makes a noise — so the porch is a machine, not
/// a place somebody sits.
///
/// --- Where these can go, and why it is not anywhere ----------------------
///
/// The railing between the sequencer's x1 and x2 IS the board. Anything set
/// down there reads as placeable and teaches the wrong thing, so clutter lives
/// strictly outside that span, on the returns at either end where the rail
/// runs over the porch posts. track_slot_at already answers -1 out there, so
/// nothing here can be clicked by accident — but the rule is worth stating,
/// because the tempting empty rail is exactly the part that is spoken for.
///
/// Drawn from obj_porch, after the timber, because they sit on it.

/// The block these are drawn on, matching the scene's posterise grid.
#macro CLUTTER_BLOCK 4

/// Where they sit, on the rail's top surface.
#macro CLUTTER_Y     RAIL_Y

/// The left return and the right return.
#macro ROPE_X  70
#macro JAR_X  1302

function clutter_draw() {
	clutter_rope(ROPE_X, CLUTTER_Y);
	clutter_jar(JAR_X,  CLUTTER_Y);
}

/// A coil of rope, flaked down on the rail.
///
/// Drawn as a ring with a hole in it, not as a stack of turns. The stack was
/// the first attempt and it read as a wedge of cheese: three bars of slightly
/// different widths with thin dark lines between them is a taper, and the eye
/// has no reason to call a taper rope.
///
/// What says coil at forty pixels is the hole. A coil flaked on a flat surface
/// and seen from slightly above is a squashed ring — near side, far side, and
/// a dark gap between them where you are looking down into the middle of it.
/// Get that gap in and everything else can be two flat colours.
function clutter_rope(_cx, _by) {
	var _b = CLUTTER_BLOCK;
	var _x = floor(_cx / _b) * _b;
	var _y = floor(_by / _b) * _b;

	var _hemp = pal_lit(make_colour_rgb(150, 126,  86));
	var _dark = pal_lit(make_colour_rgb( 74,  60,  40));
	var _lit  = pal_lit(make_colour_rgb(182, 160, 118));

	draw_set_alpha(1);

	// The whole ring, as one mass.
	draw_set_colour(_hemp);
	draw_rectangle(_x - _b * 6, _y - _b * 3.5, _x + _b * 6, _y, false);

	// The far side of it, catching what light there is from above.
	draw_set_colour(_lit);
	draw_rectangle(_x - _b * 5.5, _y - _b * 3.5, _x + _b * 5.5, _y - _b * 2.5, false);

	// And the hole — looking down into the middle of the coil. This is the
	// whole trick; without it the rest is a bar of soap.
	draw_set_colour(_dark);
	draw_rectangle(_x - _b * 3, _y - _b * 2.5, _x + _b * 3, _y - _b * 1, false);

	// A loose end, run out over the rail and hanging. A coil with both ends
	// tucked in is a doughnut, and this is the only part that says rope rather
	// than ring.
	draw_set_colour(_hemp);
	draw_rectangle(_x + _b * 5, _y - _b * 1.5, _x + _b * 8, _y - _b * 0.5, false);
	draw_rectangle(_x + _b * 7, _y - _b * 0.5, _x + _b * 8, _y + _b * 2.5, false);
}

/// A stoneware jar with a lid, stood on the rail.
function clutter_jar(_cx, _by) {
	var _b = CLUTTER_BLOCK;
	var _x = floor(_cx / _b) * _b;
	var _y = floor(_by / _b) * _b;

	var _body = pal_lit(make_colour_rgb(126, 110,  96));
	var _lit  = pal_lit(make_colour_rgb(154, 138, 120));
	var _dark = pal_lit(make_colour_rgb( 78,  66,  56));

	draw_set_alpha(1);

	// Body, with a shoulder pulled in at the top — the one line that makes it
	// a jar rather than a tin.
	draw_set_colour(_body);
	draw_rectangle(_x - _b * 3, _y - _b * 6, _x + _b * 3, _y, false);
	draw_rectangle(_x - _b * 2.5, _y - _b * 7.5, _x + _b * 2.5, _y - _b * 6, false);

	// The side turned toward the light, taken from the scene key like the
	// porch timber is, so the jar is lit by the same sun the posts are.
	var _side = (global.light.x < _x) ? -1 : 1;
	draw_set_colour(_lit);
	draw_rectangle(_x + _side * _b * 2, _y - _b * 6, _x + _side * _b * 3, _y, false);

	// Neck and lid.
	draw_set_colour(_dark);
	draw_rectangle(_x - _b * 1.5, _y - _b * 8.5, _x + _b * 1.5, _y - _b * 7.5, false);
	draw_set_colour(_lit);
	draw_rectangle(_x - _b * 2, _y - _b * 9.5, _x + _b * 2, _y - _b * 8.5, false);
}
