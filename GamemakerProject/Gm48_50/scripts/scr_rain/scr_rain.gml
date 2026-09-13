/// A single drop of rain.
///
/// Depth is chosen first and everything else follows from it, so a drop never
/// needs to know whether it is "near" or "far" — the projection decides how
/// fast it falls, how long its streak is and where it stops.

/// A fresh drop at a random depth and column.
///
/// `_stagger` starts it partway through its fall. Used when seeding the field
/// so the first frame already has rain hanging in the air, instead of a curtain
/// of drops released in unison and marching down the screen in lockstep.
function rain_new_drop(_stagger) {
	// Biasing the depth sample pushes most of the drop count into the distance,
	// where drops are small and cheap, and keeps the big near streaks sparse.
	// Too many near streaks reads as static rather than rain.
	var _t = power(random(1), global.rain_depth_bias);
	var _z = lerp(global.persp_z_near, global.persp_z_far, _t);

	// Columns are picked in screen space, overshooting both edges so wind can
	// blow drops in from off-screen rather than having them appear at the edge.
	var _x = random_range(-140, room_width + 140);

	var _land = landing_at(_x, _z);
	var _top = cloud_y(_z);

	return {
		x: _x,
		y: _stagger ? lerp(_top, _land.y, random(1)) : _top,
		z: _z,
		land: _land.y,
		kind: _land.kind,
	};
}

/// Splashes used to live here, and were removed for cost.
///
/// Every drop that landed pushed a ring onto a list, and every frame drew the
/// live ones as outlined ellipses — up to the 320 the list was capped at, each
/// its own unbatched primitive, plus a vertical tick for the ones on wood.
/// That was the single most expensive thing the game drew, and against a field
/// of thousands of drops and a lake that is already moving, almost none of it
/// was visible.
///
/// If they come back they should come back cheaper: filled quads rather than
/// ellipse outlines, or written into the water shader, which already knows the
/// surface and the hour. The projection they needed is still here — a ring on
/// the ground plane is an ellipse flattened by the same persp_scale everything
/// else uses, and the drops still carry the `kind` that said which surface
/// they hit, because the audio reads it.

