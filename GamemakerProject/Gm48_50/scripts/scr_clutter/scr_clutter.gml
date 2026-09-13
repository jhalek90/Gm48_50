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
#macro RUG_X1  356
#macro RUG_X2 1004
#macro RUG_Y1  676
#macro RUG_Y2  804

function clutter_draw() {
	clutter_rug();
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
