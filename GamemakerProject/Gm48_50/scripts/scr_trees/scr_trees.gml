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
/// All five sprites are a 220px box holding 168px of tree, with 52px of empty
/// padding above the canopy. That padding is why sizes are given below as a
/// crown height rather than as a sprite scale: a scale multiplier scales the
/// box, so asking for 200 gets a tree about 150 tall and every number in the
/// table reads a quarter too big. Composing against the thing you can actually
/// see is worth the one division in trees_draw.
///
/// If the sprites are ever re-exported with different padding, this is the
/// number to re-measure — nothing else here needs to change.
#macro TREE_ART_H 168

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
		// Three of them, all pushed to the edges. There were five, and the two
		// that went were the two nearest the middle of the frame — which is
		// also the only part of the view worth keeping clear, since it is where
		// the lake, the far range and anything moving on the water are. A stand
		// that runs evenly across the opening is a hedge; one that holds the
		// two sides and leaves the centre open is a window.
		//
		// The far pair. The smaller sits behind and above, the larger in front
		// of it and cutting across. One tree passing behind another is the
		// strongest depth cue available here, stronger than size, because it
		// cannot be read as the tree simply being a smaller tree — which is why
		// these two are the pair that stayed.
		{ spr: sprTree4504, x: 1020, z: 2.56, crown: 330, rate: 0.62, phase: 0.87 },

		// The right edge, cut by the porch post and running off the frame, so
		// the view is closed on both sides rather than only on the left.
		{ spr: sprTree3512, x: 1288, z: 2.30, crown: 375, rate: 0.55, phase: 0.61 },

		// The near tree, and the reason the list is ordered at all. Most of it
		// is off the left edge on purpose: it frames the view and gives the eye
		// something at arm length to read the distance of everything else
		// against. That job matters more now than it did with five, because
		// with the middle cleared it is the only thing left holding the left
		// side of the frame at all.
		//
		// What stays on screen has to be big enough to read as one mass,
		// because the porch post cuts across it — smaller, and the post breaks
		// the canopy into slivers and it stops looking like a tree.
		//
		// Its z is nearer than z_near, which nothing else in the scene is. That
		// is deliberate. Its base lands below the bottom of the screen and the
		// porch draws over it, so none of the projection is on show; pulling it
		// back to a legal depth costs the framing and buys nothing.
		{ spr: sprTree7766, x:  -80, z: 1.15, crown: 470, rate: 0.34, phase: 0.13 },
	];

	global.trees_time = 0;
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

		// These canopies are about as wide as they are tall, so the crown
		// doubles as the width and there is no second number to keep in step.
		shadow_cast(_t.x, ground_y(_t.z), _t.crown * persp_scale(_t.z) * _size, _col, 1);
	}
}

/// Draw the stand.
function trees_draw() {
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
		var _n = sprite_get_number(_t.spr);

		// Each tree runs its own clock, at its own rate and from its own offset
		// in the loop. Copies of one sway in lockstep is the thing that makes a
		// row of trees read as wallpaper.
		var _f = (global.trees_time * _sway * _t.rate + _t.phase * _n) mod _n;

		// Crown height to sprite scale. The canopy lands at crown * persp_scale
		// pixels tall whatever the padding around it happens to be.
		var _s = _t.crown * persp_scale(_t.z) * _size / TREE_ART_H;

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
