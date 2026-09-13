/// The trees on the near bank.
///
/// A table rather than room instances. Each tree is a sprite and four numbers,
/// and the scene draws them in the same event that draws the bank they stand
/// on — so the composition is decided in one readable place, and they sort
/// against the water and the grass without a depth anyone has to maintain.
///
/// Placed by depth, like everything else in this scene: `z` is the only
/// position an entry is given, and the screen row, the size and the draw order
/// all come off it through scr_perspective.

/// The visible art inside a tree sprite.
///
/// Tree sprites are a box with empty padding above the canopy, and sizes in
/// the table below are given as a crown height rather than as a sprite scale:
/// a scale multiplier scales the *box*, so asking for 200 gets a tree about
/// 150 tall and every number in the table reads a quarter too big. Composing
/// against the thing you can actually see is worth the one division in
/// trees_draw.
///
/// It is per entry rather than one constant because the project now holds two
/// families of tree with different padding — the originals carry 168 pixels of
/// art in a 220 box, the pines 188 in a 245. One number for both would render
/// whichever family it was not measured against about a tenth off, and it
/// would do it silently, because a tree being slightly the wrong size looks
/// like a composition choice rather than a bug.
///
/// Measured off the sprites' own alpha, not read off a design document. If a
/// sprite is re-exported with different padding this is the number to take
/// again, and nothing else here needs to change.
#macro TREE_ART_H 168

/// How wide a canopy is against its height, for the shadow it throws.
///
/// Measured off the sprites like TREE_ART_H: the pines are 130 by 188. If a
/// rounder tree comes back this wants taking again, or moving into the table
/// beside `art`.
#macro TREE_ASPECT 0.7

function trees_init() {
	// Sorted far to near. Drawing in this order puts nearer trees over farther
	// ones for free, which is the whole of the sorting this scene needs.
	//
	// `crown` is the height of the visible canopy in pixels at the near plane,
	// so on screen it comes out as crown * persp_scale(z). Depth has to stay
	// spread: at close to one depth the projection scales every tree the same,
	// their bases land on one row and their tops on another, and the stand
	// reads as a hedge cut out and pasted along the waterline.
	global.trees = [
		// A stand of pines, and the positions moved with the sprites.
		//
		// A pine is 130 wide to 188 tall where the old round trees were square
		// — barely two thirds the width at the same crown height. The spacing
		// that had the old pair overlapping left these two with a hundred
		// pixels of clear air between them, and the near one all but slid off
		// the left edge. Swapping art is never only swapping art: the previous
		// x values were chosen against a silhouette that no longer exists.
		//
		// `art` is how many pixels of the sprite's box are actually tree. The
		// pines carry 188 in a 245 box; the originals carried 168 in 220.
		//
		// Three on the right rather than two, which is what pines want. They
		// grow in stands and read wrongly as isolated specimens, and the fourth
		// sprite was going spare. Each overlaps the next by twenty or thirty
		// pixels: one tree passing behind another is the strongest depth cue
		// available here, stronger than size, because it cannot be read as the
		// tree simply being a smaller tree.
		{ spr: sprTreepine4, art: 188, x:  980, z: 2.85, crown: 750, rate: 0.58, phase: 0.22 },
		{ spr: sprTreepine2, art: 188, x: 1090, z: 2.56, crown: 825, rate: 0.62, phase: 0.87 },

		// The nearest of the three, and the one the porch post cuts across, so
		// the view is closed on the right as well as the left.
		{ spr: sprTreepine3, art: 188, x: 1240, z: 2.30, crown: 938, rate: 0.55, phase: 0.61 },

		// The near tree, and the reason the list is ordered at all. It frames
		// the view and gives the eye something at arm length to read the
		// distance of everything else against — a job that matters more now
		// than it did with five trees, because with the middle cleared it is
		// the only thing holding the left side of the frame at all.
		//
		// Moved in from -80 to 30. At the old x a pine this narrow reached
		// barely thirty pixels onto the screen and framed nothing; at 30 it
		// still runs off the left edge but arrives far enough in to read as a
		// mass. Further in than this and it starts covering the dock.
		//
		// Its z is nearer than z_near, which nothing else in the scene is. That
		// is deliberate. Its base lands below the bottom of the screen and the
		// porch draws over it, so none of the projection is on show; pulling it
		// back to a legal depth costs the framing and buys nothing.
		{ spr: sprTreepine1, art: 188, x:   30, z: 1.15, crown: 470, rate: 0.34, phase: 0.13 },
	];

	global.trees_time = 0;
}

/// How much of a tree sprite's box is actually tree.
///
/// Falls back to the old family's height, so an entry written without an `art`
/// still behaves as it always did rather than collapsing to nothing.
function tree_art_h(_t) {
	return variable_struct_exists(_t, "art") ? _t.art : TREE_ART_H;
}

/// The shadows the stand drops on the bank.
///
/// Drawn after the grass and before the trees themselves, so a tree stands in
/// its own shadow rather than on top of it.
function trees_shadows() {
	// Darkened grass rather than black. A shadow is the ground with less light
	// on it, and painting it neutral is what makes shadows read as holes.
	var _col  = merge_colour(global.pal.grass, c_black, 0.62);
	var _size = gmlmcp_tunable("tree_scale", 1.0);
	var _list = global.trees;

	for (var _i = 0; _i < array_length(_list); _i++) {
		var _t = _list[_i];

		// The crown is a height, and a pine is narrower than it is tall — 130
		// to 188, about seven tenths. The old round trees were square, so the
		// crown could double as the width with no second number to keep in
		// step; these need the aspect or every tree stands in a puddle half
		// again as wide as itself.
		shadow_cast(_t.x, ground_y(_t.z),
			_t.crown * TREE_ASPECT * persp_scale(_t.z) * _size, _col, 1);
	}
}

/// Is this tree nearer to the viewer than any rain in the scene?
///
/// The field starts at z_near, so a tree in front of that plane has nothing
/// falling between it and the viewer at all — every drop belongs behind it.
/// The near tree is the only thing in the scene like this, which is exactly
/// why it was the one that looked wrong: drawn with the others it had the
/// whole field raining over it.
function tree_in_front_of_rain(_t) {
	return (_t.z < global.persp_z_near);
}

/// Draw the stand.
///
/// `_near` picks which half: false for the trees standing in the rain, true
/// for the one standing in front of all of it. Two passes at two depths with
/// the near rain between them, which is the only way the field can have trees
/// inside it rather than behind it.
function trees_draw(_near) {
	// Real elapsed time, like every other clock here, so the sway does not
	// speed up or slow down with the frame rate.
	global.trees_time += delta_time / 1000000;

	// The trees are painted art, not palette-driven shapes, so they are
	// multiplied through the ambient light instead of being recoloured. One
	// sprite then serves every hour of the day.
	var _tint = global.pal.light;

	// What the trees are standing against, and so what distance washes them
	// toward. The lake, because that is what is behind every one of them.
	var _fog  = global.pal.water;

	var _sway = gmlmcp_tunable("tree_sway",  8) * (0.6 + 0.7 * wind_strength());
	var _size = gmlmcp_tunable("tree_scale", 1.0);
	var _list = global.trees;

	for (var _i = 0; _i < array_length(_list); _i++) {
		var _t = _list[_i];
		if (tree_in_front_of_rain(_t) != _near) continue;

		var _n = sprite_get_number(_t.spr);

		// Each tree runs its own clock, at its own rate and from its own offset
		// in the loop. Copies of one sway in lockstep is the thing that makes a
		// row of trees read as wallpaper.
		var _f = (global.trees_time * _sway * _t.rate + _t.phase * _n) mod _n;

		// Crown height to sprite scale. The canopy lands at crown * persp_scale
		// pixels tall whatever the padding around it happens to be.
		var _s = _t.crown * persp_scale(_t.z) * _size / tree_art_h(_t);

		// The sprites are all bottom-centre origin, so the ground row from the
		// projection is the draw position with no offset to remember.
		var _y = ground_y(_t.z);
		draw_sprite_ext(_t.spr, _f, _t.x, _y, _s, _s, 0, _tint, 1);

		// Then the air in front of it: the same sprite and frame, filled flat
		// with the colour of the lake behind, at the strength its depth calls
		// for. Until now the trees were the one thing in the scene not taking
		// part in aerial perspective, so a tree at 2.5 and one at 1.15 were
		// separated by size alone.
		//
		// It needs shd_flat rather than a blend colour because a blend colour
		// multiplies: it can only darken a distant tree, and haze washes things
		// toward the background rather than dimming them.
		var _fade = aerial_fade(_t.z, 0.45) * gmlmcp_tunable("tree_haze", 1.0);
		if (_fade > 0.01) {
			shader_set(shd_flat);
			draw_sprite_ext(_t.spr, _f, _t.x, _y, _s, _s, 0, _fog, _fade);
			shader_reset();
		}
	}
}
