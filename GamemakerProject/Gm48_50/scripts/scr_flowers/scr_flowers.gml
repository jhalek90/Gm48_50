/// A few flowers in the bank grass.
///
/// Deliberately few. The bank is only ever seen in slices between the
/// balusters, and the grass shader already has a lot going on in those slices;
/// a meadow would turn them to noise. Seven is enough that you notice one, and
/// few enough that noticing one still feels like finding it.
///
/// Placed by depth like everything else on the bank, so a flower nearer the
/// water is smaller and paler than one at your feet without either number
/// being written down twice.

function flowers_init() {
	// Every one of them stands in a gap between the balusters.
	//
	// obj_porch sets a baluster every 78 pixels from x 60, sixteen wide, so the
	// gaps run 76+78k to 138+78k and their centres are at 107+78k. Placed
	// without regard for that, three of the first seven landed squarely behind
	// a post and were simply never seen — and a flower nobody can see is not
	// worth the pixels, however honestly placed.
	//
	// This is a coupling worth being aware of: change the railing's spacing and
	// these want re-picking. It is the right trade anyway, because the only
	// view of the bank there has ever been is through those gaps.
	//
	// Depths are spread across the bank so they are not all the same size, and
	// the columns avoid the trees, for the same reason the rocks do: a flower
	// has no business arguing with a trunk about which of them is in front.
	global.flowers = [
		{ x:  185, z: 2.16, tone: 0 },   // gap 1
		{ x:  419, z: 2.47, tone: 1 },   // gap 4 — gap 3 is under the dock now
		{ x: 1043, z: 2.09, tone: 2 },   // gap 12 — gap 5 is under the dock now
		{ x:  653, z: 2.35, tone: 0 },   // gap 7
		{ x:  809, z: 2.13, tone: 3 },   // gap 9
		{ x:  965, z: 2.41, tone: 1 },   // gap 11
		{ x: 1199, z: 2.25, tone: 2 },   // gap 14
	];

	// Muted on purpose, and every one of them under the god ray threshold in
	// shd_post. A white flower would be over it, and seven little emitters
	// dragging streaks toward the sun is not the effect anybody wants.
	global.flower_tones = [
		make_colour_rgb(206, 206, 196),   // white
		make_colour_rgb(214, 202, 138),   // pale yellow
		make_colour_rgb(196, 146, 156),   // dusty pink
		make_colour_rgb(170, 166, 204),   // faded violet
	];
}

function flowers_draw() {
	var _px   = 2;
	var _list = global.flowers;

	// Leaning on the one gust, like the grass they are standing in. A flower
	// that held still while the blades around it bent would be the thing that
	// gave away that the grass is a shader.
	var _lean = global.wind * 2.2;

	for (var _i = 0; _i < array_length(_list); _i++) {
		var _f = _list[_i];
		var _s = persp_scale(_f.z);

		var _y  = ground_y(_f.z);
		var _hz = aerial_fade(_f.z, 0.35);

		// Stem height and blossom size off the projection, floored so a far
		// flower is still a whole pixel rather than a smear.
		var _sh = max(_px * 2, round(16 * _s / _px) * _px);
		var _bw = max(_px * 2, round( 9 * _s / _px) * _px);

		var _x  = floor(_f.x / _px) * _px;
		var _by = floor((_y - _sh) / _px) * _px;
		var _lx = floor((_f.x + _lean * _s) / _px) * _px;

		// Stem, from the ground up, leaning into the wind at the top only —
		// which is what a stem does, since the bottom of it is in the soil.
		draw_set_alpha(1 - _hz * 0.5);
		draw_set_colour(merge_colour(pal_lit(make_colour_rgb(66, 84, 52)),
			global.pal.grass, _hz));
		draw_rectangle(_x, floor(_y / _px) * _px, _x + _px, _by + _px, false);
		draw_rectangle(min(_x, _lx), _by, max(_x, _lx) + _px, _by + _px, false);

		// The blossom, on the leaning end.
		draw_set_colour(merge_colour(pal_lit(global.flower_tones[_f.tone]),
			global.pal.grass, _hz));
		draw_rectangle(_lx - _bw * 0.5, _by - _bw, _lx + _bw * 0.5, _by, false);
	}

	draw_set_alpha(1);
}
