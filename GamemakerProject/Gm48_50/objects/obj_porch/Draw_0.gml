/// The porch, in timber.
///
/// Wood from the day/night palette: the porch is lit by the same sky the lake
/// is, so it has to darken with it or the scene comes apart at dusk. The flat
/// rectangles this event used to draw are now shd_wood, which is handed the
/// same three tones and puts grain, plank seams and a lit edge on them.
///
/// Every piece is one call between wood_begin and wood_end, so the whole porch
/// is a single shader state change however many balusters there turn out to be.
var _wood_dark = global.pal.wood_dark;
var _wood      = global.pal.wood;
var _wood_lit  = global.pal.wood_lit;

wood_begin();

// Roof overhang. The rain is drawn beneath this, so the underside of the roof
// cuts the top off the falling field the way a real porch roof would.
//
// Boarded across rather than left as one slab: the underside of a roof is the
// one place where you see the decking itself, and the seams are what say the
// roof is built rather than poured.
wood_piece(0, 0, room_width, 96, _wood_dark, GRAIN_ALONG_X, 32, 11);

// The fascia along its front edge. A single board, and the lightest thing up
// there, because it is the one face of the roof turned toward the sky.
wood_piece(0, 96, room_width, 112, _wood, GRAIN_ALONG_X, 16, 23);

// Posts holding it up. One board each, grain running their length, and each
// given its own seed so the two of them are not identical timber.
wood_piece(24, 112, 96, room_height, _wood_dark, GRAIN_ALONG_Y, 72, 41);
wood_piece(room_width - 96, 112, room_width - 24, room_height, _wood_dark, GRAIN_ALONG_Y, 72, 57);

// The railing. Its top edge is the surface the rain lands on and the shelf the
// sequencer stands objects on, so it is drawn from the shared RAIL_Y.
//
// Both courses are single boards the width of the porch, which is what a rail
// is. Dividing them into planks would read as a fence panel, not a handrail.
wood_piece(0, RAIL_Y, room_width, RAIL_Y + 22, _wood_lit, GRAIN_ALONG_X, 22, 71);
wood_piece(0, RAIL_Y + 22, room_width, RAIL_Y + 44, _wood, GRAIN_ALONG_X, 22, 83);

// Balusters below the top rail. The seed is stepped per baluster so seventeen
// copies of one board do not march across the screen.
var _b = 0;
for (var _x = 60; _x < room_width; _x += 78) {
	wood_piece(_x, RAIL_Y + 44, _x + 16, 596, _wood_dark, GRAIN_ALONG_Y, 16, 101 + _b * 7);
	_b++;
}

wood_piece(0, 596, room_width, 618, _wood, GRAIN_ALONG_X, 22, 149);

// Porch floor in the immediate foreground. Mixed from the two wood tones
// rather than given a palette entry of its own — it is a shade between them at
// every hour, so deriving it keeps one less colour in step by hand.
//
// Boarded, unlike the rails: this is decking, and the seams running across it
// are most of what makes it read as a floor you could stand on.
wood_piece(0, 660, room_width, room_height, merge_colour(_wood_dark, _wood, 0.35),
	GRAIN_ALONG_X, 24, 167);

wood_end();
