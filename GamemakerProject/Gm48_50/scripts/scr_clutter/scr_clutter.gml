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
/// Not everything here is set down. The plate is nailed up under the roof,
/// which is the same idea from the other direction — a porch is lived on
/// because of what has been left on it *and* what has been fixed to it and
/// forgotten about.
///
/// Drawn from obj_porch, after the timber, because it all sits on it.

/// The block these are drawn on, matching the scene's posterise grid.
#macro CLUTTER_BLOCK 4

/// Where they sit, on the rail's top surface.
#macro CLUTTER_Y     RAIL_Y

/// The left return and the right return.
#macro ROPE_X  70
#macro JAR_X  1302

/// And the plate, nailed to the roof's underside.
///
/// Right of centre on purpose: the day scrubber covers the left half of the
/// soffit while it is up, the chime's cord comes down at 190 and the lantern's
/// chain at 1204, so the clear stretch is the middle right. It is the one
/// piece of the scene that says what the game is called for, and it should not
/// spend development hidden behind a debug panel.
#macro PLATE_X   880
#macro PLATE_Y    62

/// Half its size, in pixels. A plate is twice as wide as it is tall.
#macro PLATE_HW  100
#macro PLATE_HH   50

/// The rug on the deck boards.
///
/// Most of it is under the picker and the faders while the interface is up, so
/// it is very nearly a clean-view object — which is not a reason to skip it.
/// The view with T pressed is the one that gets screenshotted, and the deck
/// was the last large empty surface in the frame.
/// Y2 is past the bottom of the room on purpose. The near edge of a rug you
/// are standing at is not in the picture — it is under you — and a mat that
/// stops short with a strip of deck below it reads as a sample laid out for
/// inspection rather than as something on the floor of the place you are in.
/// The cat, asleep on the deck.
///
/// Bottom left, which is the one part of the floor nothing else wants: the rug
/// starts at 356, the picker row at 316, and the left post ends at 96. It also
/// puts the one living thing on this side of the railing in the corner your eye
/// lands on last, which is where a sleeping animal should be found rather than
/// presented.
///
/// CAT_Y is the deck line it lies on, not the top of it.
/// Twice the block the rest of the clutter is drawn on. The cat is the nearest
/// thing in the scene and the only one at the viewer's feet, so it is the one
/// prop that would look like a miniature at the shared size.
#macro CAT_X      150
#macro CAT_Y      744
#macro CAT_BLOCK    8

/// How near it sounds. The nearest thing in the scene: it is at your feet,
/// inside the railing, closer than anything hanging from the roof.
#macro CAT_Z      1.1

#macro RUG_X1  356
#macro RUG_X2 1004
#macro RUG_Y1  676
#macro RUG_Y2  804

function clutter_draw() {
	clutter_rug();
	clutter_cat(CAT_X, CAT_Y);
	clutter_rope(ROPE_X, CLUTTER_Y);
	clutter_jar(JAR_X,  CLUTTER_Y);
	clutter_plate(PLATE_X, PLATE_Y);
}

/// A woven rug, laid on the boards.
///
/// Drawn before the railing's shadows, so the bars of light through the
/// balusters fall across it rather than stopping at its edge. That is the
/// whole reason it is here in obj_porch's event rather than in an object of
/// its own: a rug the shadows do not touch is a rug lying on top of the
/// picture instead of on the floor.
///
/// Warm, against a scene that is otherwise entirely cool — grey rain, grey
/// lake, grey timber, green bank. It is the only red in the frame, and one
/// warm note in a cold picture does more for the temperature of the whole
/// thing than another cool one ever could.
function clutter_rug() {
	var _b = CLUTTER_BLOCK;

	var _x1 = floor(RUG_X1 / _b) * _b;
	var _x2 = floor(RUG_X2 / _b) * _b;
	var _y1 = floor(RUG_Y1 / _b) * _b;
	var _y2 = floor(RUG_Y2 / _b) * _b;

	var _wool  = pal_lit(make_colour_rgb(142,  84,  64));
	var _dark  = pal_lit(make_colour_rgb( 94,  54,  42));
	var _light = pal_lit(make_colour_rgb(186, 148, 116));
	var _thread= pal_lit(make_colour_rgb(172, 156, 132));

	draw_set_alpha(1);

	// The fringe, at both ends, drawn first so the rug's own edge lies over the
	// knots. A rug without one reads as a painted rectangle.
	draw_set_colour(_thread);
	for (var _y = _y1 + _b; _y < _y2 - _b; _y += _b * 2) {
		draw_rectangle(_x1 - _b * 2, _y, _x1, _y + _b, false);
		draw_rectangle(_x2, _y, _x2 + _b * 2, _y + _b, false);
	}

	// Body, then the border pressed inside it.
	draw_set_colour(_dark);
	draw_rectangle(_x1, _y1, _x2, _y2, false);

	draw_set_colour(_wool);
	draw_rectangle(_x1 + _b * 2, _y1 + _b * 2, _x2 - _b * 2, _y2 - _b * 2, false);

	draw_set_colour(_dark);
	draw_rectangle(_x1 + _b * 3, _y1 + _b * 3, _x2 - _b * 3, _y1 + _b * 4, false);
	draw_rectangle(_x1 + _b * 3, _y2 - _b * 4, _x2 - _b * 3, _y2 - _b * 3, false);

	// A row of diamonds. Stacked bars of 1, 3, 5, 3, 1 blocks, which is the
	// smallest lozenge that still reads as woven-in rather than as a smudge,
	// and spaced so a whole number of them fits the length.
	//
	// Placed off the far edge rather than at the rug's centre, because the
	// centre is now off the bottom of the screen and the motif would have gone
	// with it. Measuring from the edge you can actually see is the only thing
	// that survives the rug running out of frame.
	var _cy    = _y1 + _b * 11;
	var _rows  = [1, 3, 5, 3, 1];
	var _inner = (_x2 - _b * 4) - (_x1 + _b * 4);
	var _n     = max(1, round(_inner / (_b * 14)));
	var _step  = _inner / _n;

	draw_set_colour(_light);

	for (var _i = 0; _i < _n; _i++) {
		var _dx = _x1 + _b * 4 + _step * (_i + 0.5);
		_dx = floor(_dx / _b) * _b;

		for (var _r = 0; _r < array_length(_rows); _r++) {
			var _hw = _rows[_r] * _b * 0.5;
			var _dy = _cy + (_r - 2) * _b;
			draw_rectangle(_dx - _hw, _dy, _dx + _hw, _dy + _b, false);
		}
	}
}

/// One rectangle of the plate, given in plate space and rotated onto the wall.
///
/// Everything about the plate goes through here, which is why the plate can be
/// hung at an angle at all. draw_rectangle only makes axis-aligned boxes, so a
/// tilted plate has to be quads — and since they are quads anyway they may as
/// well all go into one primitive batch rather than fifty draw calls. The rain
/// field is built the same way and for the same reason.
///
/// Coordinates are relative to the plate's centre, so the layout below reads
/// as a drawing rather than as arithmetic about where the plate happens to be.
function plate_rect(_cx, _cy, _c, _s, _x1, _y1, _x2, _y2, _col, _a) {
	var _ax = _cx + _x1 * _c - _y1 * _s;   var _ay = _cy + _x1 * _s + _y1 * _c;
	var _bx = _cx + _x2 * _c - _y1 * _s;   var _by = _cy + _x2 * _s + _y1 * _c;
	var _dx = _cx + _x2 * _c - _y2 * _s;   var _dy = _cy + _x2 * _s + _y2 * _c;
	var _ex = _cx + _x1 * _c - _y2 * _s;   var _ey = _cy + _x1 * _s + _y2 * _c;

	draw_vertex_colour(_ax, _ay, _col, _a);
	draw_vertex_colour(_bx, _by, _col, _a);
	draw_vertex_colour(_dx, _dy, _col, _a);

	draw_vertex_colour(_ax, _ay, _col, _a);
	draw_vertex_colour(_dx, _dy, _col, _a);
	draw_vertex_colour(_ex, _ey, _col, _a);
}

/// A licence plate screwed to the soffit, hung very slightly off true.
///
/// The angle is what stops it reading as a name plate. A sign centred and
/// square is signage; the same sign a few degrees out is something a person
/// put up. Nothing else about it changed as much as that did.
///
/// The letters are blocks rather than fntPixels. The font is a handwriting
/// face and a plate is stamped metal — the one thing its lettering must not
/// look like is handwriting. Four wide and five tall is the smallest grid that
/// gives an N its diagonal, and that diagonal is the only thing separating an
/// N from an H at this size.
function clutter_plate(_cx, _cy) {
	var _ang = degtorad(gmlmcp_tunable("plate_angle", -4.5));
	var _c   = cos(_ang);
	var _s   = sin(_ang);

	// Weathered enamel, kept under the god ray threshold like everything else
	// that catches light — a bright plate on a dark soffit would be the one
	// thing in the roof emitting shafts.
	var _face = pal_lit(make_colour_rgb(198, 192, 174));
	// The rim takes the number's colour rather than a neutral grey. A plate is
	// printed in one ink — border, legend and characters all come off the same
	// press — and a grey surround read as a picture frame somebody had put a
	// green sign inside. Lighter and a shade more saturated than the ink, so it
	// still reads as behind the characters rather than competing with them.
	var _rim  = pal_lit(make_colour_rgb( 58, 102,  92));
	var _ink  = pal_lit(make_colour_rgb( 44,  74,  66));
	var _emb  = pal_lit(make_colour_rgb(150, 146, 132));
	var _bolt = pal_lit(make_colour_rgb( 68,  64,  58));

	var _hw = PLATE_HW;
	var _hh = PLATE_HH;
	var _r  = 10;   // corner knock-off

	draw_primitive_begin(pr_trianglelist);

	// Sitting off the boards. Offset down and across rather than drawn around
	// the edge, which is what says it stands proud rather than being painted.
	plate_rect(_cx + 5, _cy + 6, _c, _s, -_hw, -_hh + _r, _hw, _hh - _r, c_black, 0.34);
	plate_rect(_cx + 5, _cy + 6, _c, _s, -_hw + _r, -_hh, _hw - _r, _hh, c_black, 0.34);

	// The rim, and the face pressed inside it. Both have their corners knocked
	// off — a plate is a stamping with a radius on it, and square corners are
	// most of what made the first attempt read as a name plate.
	plate_rect(_cx, _cy, _c, _s, -_hw, -_hh + _r, _hw, _hh - _r, _rim, 1);
	plate_rect(_cx, _cy, _c, _s, -_hw + _r, -_hh, _hw - _r, _hh, _rim, 1);

	var _fw = _hw - 7;
	var _fh = _hh - 7;
	plate_rect(_cx, _cy, _c, _s, -_fw, -_fh + _r, _fw, _fh - _r, _face, 1);
	plate_rect(_cx, _cy, _c, _s, -_fw + _r, -_fh, _fw - _r, _fh, _face, 1);

	// The legend across the top — the little line of state text every plate
	// carries and nobody reads. At this size it is dashes, which is exactly
	// what small type looks like once it is too small to be type.
	var _dash = [13, 7, 9, 5, 11, 7, 6, 10];
	var _dw   = 0;
	for (var _i = 0; _i < array_length(_dash); _i++) _dw += _dash[_i] + 5;

	var _lx = -(_dw - 5) * 0.5;
	for (var _i = 0; _i < array_length(_dash); _i++) {
		plate_rect(_cx, _cy, _c, _s, _lx, -_fh + 7, _lx + _dash[_i], -_fh + 13, _rim, 0.85);
		_lx += _dash[_i] + 5;
	}

	// Two screws, up where a plate is actually fixed.
	plate_rect(_cx, _cy, _c, _s, -_fw + 6, -_fh + 5, -_fw + 14, -_fh + 13, _bolt, 1);
	plate_rect(_cx, _cy, _c, _s,  _fw - 14, -_fh + 5,  _fw - 6, -_fh + 13, _bolt, 1);

	// The number, as row bitmasks four wide. Bit 3 is the leftmost column, so
	// the literals read the way the character looks written out.
	//
	// Six glyphs and one space where there used to be three big letters, so
	// the block came down from ten pixels — the old size would have run off
	// both ends. Smaller is also more plate-like for its own sake: a real one
	// carries a string long enough that the characters are nowhere near the
	// height of the face.
	//
	// Closing "24 7" up into "247" bought back a space's worth of width, which
	// is where the block went from five back up to six. The gaps came in to
	// pay for the rest of it — characters on a plate are set tight, and it is
	// the gaps that should give way before the glyphs do.
	var _font = {};
	_font[$ "Z"] = [15,  1,  2,  4, 15];
	_font[$ "E"] = [15,  8, 14,  8, 15];
	_font[$ "N"] = [ 9, 13, 11,  9,  9];
	_font[$ "2"] = [15,  1,  6,  8, 15];
	_font[$ "4"] = [ 9,  9, 15,  1,  1];
	_font[$ "7"] = [15,  1,  2,  2,  2];

	var _text = "ZEN 247";
	var _blk  = 6;
	var _gw   = _blk * 4;     // a glyph is four blocks wide
	var _gap  = _blk * 0.45;  // between characters of a group
	var _spc  = _blk * 1.5;   // and the wider gap a space makes

	// Measured first, then drawn, so the string can be centred without the
	// width being written down anywhere and kept in step by hand.
	var _len = string_length(_text);
	var _w   = 0;

	for (var _i = 1; _i <= _len; _i++) {
		var _ch = string_char_at(_text, _i);
		_w += (_ch == " ") ? _spc : _gw;
		if (_i < _len) _w += _gap;
	}

	var _px0 = -_w * 0.5;
	var _py0 = -_blk * 2.5 + 4;

	for (var _i = 1; _i <= _len; _i++) {
		var _ch = string_char_at(_text, _i);

		if (_ch == " ") {
			_px0 += _spc + _gap;
			continue;
		}

		var _rows = _font[$ _ch];

		for (var _row = 0; _row < array_length(_rows); _row++) {
			for (var _col = 0; _col < 4; _col++) {
				if ((_rows[_row] & (1 << (3 - _col))) == 0) continue;

				var _bx = _px0 + _col * _blk;
				var _by = _py0 + _row * _blk;

				// Raised, not printed. A shade of the face below and right of
				// each block reads as a character stamped up out of the metal,
				// which is the difference between a plate and a sticker.
				plate_rect(_cx, _cy, _c, _s, _bx + 2, _by + 2,
					_bx + _blk + 2, _by + _blk + 2, _emb, 1);

				plate_rect(_cx, _cy, _c, _s, _bx, _by,
					_bx + _blk, _by + _blk, _ink, 1);
			}
		}

		_px0 += _gw + _gap;
	}

	draw_primitive_end();
}

/// A coil of rope, flaked down on the rail.
///
/// Drawn as a ring with a hole in it, not as a stack of turns. The stack was
/// the first attempt and it read as a wedge of cheese: three bars of slightly
/// different widths with thin dark lines between them is a taper, and the eye
/// has no reason to call a taper rope.
///
/// What says coil at forty pixels is the hole. A coil flaked on a flat surface
/// and seen from slightly above is a squashed ring â€” near side, far side, and
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

	// And the hole â€” looking down into the middle of the coil. This is the
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

	// Body, with a shoulder pulled in at the top â€” the one line that makes it
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

/// A cat, curled up and breathing.
///
/// Drawn as a stack of rows rather than an outline, the same way the jar and
/// the rug are: a curve on this grid is a stack of rectangles, and drawing one
/// any other way puts the only smooth edge in the picture on a cat.
///
/// The head sits mostly outside the body rather than inside it. That was the
/// first attempt and it failed for a reason worth writing down: a head tucked
/// within the silhouette is not a head, it is nothing, because a shape only
/// reads where it breaks the outline of what is behind it. It laps the
/// shoulder by two blocks, which is what says tucked.
///
/// It breathes. Everything else alive on this porch moves, and a cat holding
/// perfectly still reads as an ornament of a cat. The upper rows lift by one
/// block and settle again, which at this size is the smallest change the grid
/// can show.
///
/// Not clickable. The duck answers, the chime answers, the lantern answers.
/// Something asleep that does nothing when you poke it is the joke.
function clutter_cat(_cx, _by) {
	var _b = CAT_BLOCK;
	var _x = floor(_cx / _b) * _b;
	var _y = floor(_by / _b) * _b;

	// Slower than a real cat. A real rate looks like panting at this size.
	// Read off the shared scene clock rather than a private one.
	//
	// The step is 3 pixels, not one block. Tying it to the block meant the
	// whole chest jumped 8 pixels at once at this size, which is a mouth
	// opening rather than a breath. It is also spread over four rows instead of
	// landing on one boundary, so the stretch is two small steps up the flank
	// and not a seam across the middle of the animal.
	var _lift = round(0.5 + 0.5 * sin(global.wind_time * 0.8)) * 3;

	// Calico: three colours in hard patches, not a tabby's stripes.
	//
	// The patches are the point. A single fur colour left the whole animal as
	// one silhouette to be read, and the silhouette is the part this grid
	// cannot get right. Three patches with ragged edges give the eye something
	// to read instead of the outline, and a white cat with a ginger back and a
	// black face is a specific enough animal that it does not have to be a
	// perfect one.
	var _fur  = pal_lit(make_colour_rgb(222, 214, 200));   // white, the ground
	var _gng  = pal_lit(make_colour_rgb(188, 118,  58));   // ginger
	var _blk  = pal_lit(make_colour_rgb( 56,  48,  44));   // black
	var _lit  = pal_lit(make_colour_rgb(244, 240, 230));
	var _dark = pal_lit(make_colour_rgb( 40,  34,  32));
	var _pink = pal_lit(make_colour_rgb(196, 142, 138));

	draw_set_alpha(1);

	// Which end the head is at. Away from the light, so the lit flank is the
	// long curve of the back rather than the face.
	var _face = (global.light.x < _x) ? 1 : -1;

	// The body, bottom row up: how far it reaches toward the head, how far
	// toward the tail, then how far it lifts with the breath.
	//
	// Two widths, not one. A symmetric mound put the head on a ramp and the
	// whole animal read as a single hill with lumps on it, at every size and
	// with any ears. A cat asleep is low at the head and high at the rump, so
	// the front falls away and the back keeps its width to the top. That
	// asymmetry is the shape; the ears only confirm it.
	// front, back, lift, where the black ends, where the ginger begins.
	//
	// The last two are measured along the animal, negative toward the head, and
	// they are deliberately uneven row to row. Even edges would give three
	// stripes; uneven ones give patches.
	var _rows = [
		[ 9.0, 9.5, 0, -5.0,  5.0],
		[ 9.0, 9.5, 0, -4.0,  4.5],
		[ 8.5, 9.5, 0, -5.0,  3.5],
		[ 8.0, 9.5, 0, -3.5,  3.0],
		[ 7.0, 9.0, 0, -4.5,  2.0],
		[ 5.5, 8.5, 1, -2.0,  1.0],
		[ 4.0, 8.0, 1, -3.0,  0.0],
		[ 2.5, 6.5, 2,  0.0, -1.0],
		[ 1.0, 4.5, 2,  1.0, -2.0],
	];

	// Each row's bottom edge takes the row below's lift, not its own, so the
	// stack stays joined. Lifting a row by its own offset at both edges opens a
	// gap under it, and the gap is deck: the first attempt drew a dark bar
	// straight across the cat every time it breathed in.
	// Position along the animal, in blocks: negative toward the head.
	var _p = function(_x, _face, _b, _v) { return _x - _face * _v * _b; };

	for (var _i = 0; _i < array_length(_rows); _i++) {
		var _f    = _rows[_i][0];
		var _r    = _rows[_i][1];
		var _top  = _rows[_i][2] * _lift;
		var _base = (_i > 0) ? _rows[_i - 1][2] * _lift : 0;

		var _y1 = _y - (_i + 1) * _b - _top;
		var _y2 = _y -  _i      * _b - _base;

		// White first, the whole row, then the two patches over it.
		draw_set_colour(_i < 1 ? _dark : _fur);
		draw_rectangle(_p(_x, _face, _b, -_f), _y1, _p(_x, _face, _b, _r), _y2, false);

		if (_i >= 1) {
			var _bk = min(_rows[_i][3],  _r);
			var _gn = max(_rows[_i][4], -_f);

			if (_bk > -_f) {
				draw_set_colour(_blk);
				draw_rectangle(_p(_x, _face, _b, -_f), _y1, _p(_x, _face, _b, _bk), _y2, false);
			}
			if (_gn < _r) {
				draw_set_colour(_gng);
				draw_rectangle(_p(_x, _face, _b, _gn), _y1, _p(_x, _face, _b, _r), _y2, false);
			}
		}
	}

	// The lit curve of the back, down the flank away from the face.
	draw_set_colour(pal_lit(make_colour_rgb(222, 156, 92)));
	draw_rectangle(_x - _face * _b * 1.5, _y - _b * 9 - _lift * 2,
	               _x - _face * _b * 4.0, _y - _b * 8 - _lift * 2, false);
	draw_rectangle(_x - _face * _b * 3.5, _y - _b * 8 - _lift * 2,
	               _x - _face * _b * 6.0, _y - _b * 7 - _lift * 2, false);

	// The head, at the front and low, lapping the shoulder by two blocks.
	// Pushed out far enough to break the body's outline. At 8 blocks it sat
	// almost entirely inside a body 9.5 wide and the whole front end read as
	// one lump with two prongs on it.
	var _hx = _x + _face * _b * 9.5;
	var _ht = _y - _b * 4.5;

	draw_set_colour(_fur);
	draw_rectangle(_hx - _b * 3.0, _ht + _b * 0.5, _hx + _b * 3.0, _y, false);
	draw_rectangle(_hx - _b * 2.5, _ht,            _hx + _b * 2.5, _ht + _b * 0.5, false);

	// Three colours on the crown, and the face left white under them.
	//
	// Both earlier attempts swamped it. The face is six blocks across, so a
	// patch over half of it is not a marking, it is the head's colour, and the
	// head stopped being a head and became a dark hole with a chin. Each patch
	// is a quarter of the crown now: black one side, ginger the other, white
	// everywhere the eye actually looks.
	draw_set_colour(_blk);
	draw_rectangle(_hx - _face * _b * 0.5, _ht, _hx - _face * _b * 3.0, _ht + _b * 1.0, false);

	draw_set_colour(_gng);
	draw_rectangle(_hx + _face * _b * 0.5, _ht, _hx + _face * _b * 2.5, _ht + _b * 1.0, false);

	// Ears, stepped rather than square, and the largest single thing on the
	// head. At this distance the ears are most of what says cat: the body is a
	// mound, and a mound with a small round lump on the front is any sleeping
	// animal. Two steps is as close to a triangle as this grid allows, and it
	// is enough. They stay well under the line of the back, or the head stops
	// reading as a separate thing however far out it is moved.
	//
	// The gap between them matters as much as the shape. One block of fur
	// showing through is what stops the pair reading as a single crest.
	// Near ear, far ear, in blocks from head centre. Pulled in off the edges:
	// at 2.25 and 1.25 the far one sat exactly on the head's outline and read
	// as coming loose from it.
	var _ear = [-2.0, 0.5];

	for (var _e = 0; _e < 2; _e++) {
		var _ex = _hx + _face * _b * _ear[_e];

		// The near ear is black, the far one ginger. One of each is what a
		// calico's head looks like and it also tells the two ears apart.
		draw_set_colour(_e == 0 ? _blk : _gng);
		draw_rectangle(_ex, _ht - _b * 1.0, _ex + _face * _b * 1.75, _ht, false);
		draw_rectangle(_ex + _face * _b * 0.25, _ht - _b * 2.0,
		               _ex + _face * _b * 1.25, _ht - _b * 1.0, false);
	}

	// The inside of the near ear only. The far one is turned away.
	draw_set_colour(_pink);
	draw_rectangle(_hx - _face * _b * 1.5, _ht - _b * 1.0,
	               _hx - _face * _b * 0.75, _ht - _b * 0.25, false);

	// Muzzle and chin, at the far end of the head and a shade lighter.
	draw_set_colour(_lit);
	draw_rectangle(_hx + _face * _b * 1.5, _y - _b * 2.0, _hx + _face * _b * 3.0, _y - _b * 0.5, false);

	// The eye, closed. One line, and the single mark that says asleep rather
	// than facing away.
	draw_set_colour(_dark);
	draw_rectangle(_hx - _face * _b * 0.5, _y - _b * 3.0,
	               _hx + _face * _b * 1.0, _y - _b * 2.5, false);

	// The tail, brought round the back and laid along the deck. Stepped,
	// because a diagonal here is a stair and pretending otherwise costs the
	// only smooth edge in the frame. Ginger, carrying the rump's colour round.
	draw_set_colour(_gng);
	draw_rectangle(_x - _face * _b *  7, _y - _b * 1.5, _x - _face * _b * 10.5, _y - _b * 0.5, false);
	draw_rectangle(_x - _face * _b * 10, _y - _b * 3.0, _x - _face * _b * 11.5, _y - _b * 1.5, false);
	draw_rectangle(_x - _face * _b * 11, _y - _b * 4.5, _x - _face * _b * 12.5, _y - _b * 3.0, false);
}

/// Is this screen position on the cat?
///
/// The whole animal as one box, body and head together, grown a little. This is
/// something you reach for once because you noticed it, not a target worth
/// being precise about, which is the same call the lantern's hit test makes.
function cat_at(_mx, _my) {
	var _b = CAT_BLOCK;
	var _x = floor(CAT_X / _b) * _b;
	var _y = floor(CAT_Y / _b) * _b;

	return (_mx >= _x - _b * 13 && _mx <= _x + _b * 13 &&
	        _my >= _y - _b * 10 && _my <= _y + _b);
}

/// Wake it, briefly.
///
/// In key, through the same roll the duck and the chime use, so the one thing
/// on this porch that is not an instrument still lands in the scale the music
/// is in. Positioned by the same three lines everything else here is, and it is
/// the nearest thing in the scene, so its z is the closest the porch has.
///
/// It does not stop sleeping. A cat that woke up and moved would need somewhere
/// to go and something to do when it got there, and the joke is that it stays
/// exactly where it is.
function cat_meow() {
	var _b = CAT_BLOCK;
	var _x = floor(CAT_X / _b) * _b;
	var _y = floor(CAT_Y / _b) * _b - _b * 4;

	var _semi = music_note_now(music_roll_notes());

	audio_play_sound_at(
		snd_cat,
		(_x - room_width * 0.5) * global.rain_audio_pan,
		(_y - global.persp_horizon) * 0.25,
		CAT_Z * global.rain_audio_depth,
		90, 1400, 1,
		false, 6,
		gmlmcp_tunable("cat_gain", 0.8) * mix_sfx(), undefined,
		power(2, (gmlmcp_tunable("cat_tune", 0) + _semi) / 12)
	);

	var _look = music_note_look(_semi);
	notepuff_add(_x, _y - _b * 6, _look.colour, _look.label);
}
