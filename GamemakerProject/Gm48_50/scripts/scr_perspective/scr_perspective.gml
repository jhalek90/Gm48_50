/// Perspective model for the first-person porch view.
///
/// Everything in the scene is placed by a depth `z` — distance from the person
/// sitting on the porch, in arbitrary units where the railing sits at about 1.7
/// and the far shore at 36. One projection serves the rain, the trees and the
/// instruments, so they never disagree about where the ground is.
///
/// The ground at depth z is drawn at `horizon + ground_k / z`. That 1/z is the
/// whole illusion: distant rain compresses into a thin band just under the
/// horizon while near rain sweeps the full height of the screen. Drops fall
/// from `horizon - cloud_k / z`, the same curve mirrored, so a far drop's
/// entire life is a short crawl near the horizon and a near drop's is a long
/// fast streak — without any per-distance special casing.

/// The railing, shared by everything that has to agree about where it is.
///
/// The rain is told to land on RAIL_Y, the porch draws its top edge there and
/// the sequencer stands its objects on it. Three files disagreeing about one
/// number is a bug that looks like an art problem, so the number lives once.
/// Where the near bank meets the water. The grass is rooted no further out
/// than this and the trees stand between it and the railing, so the waterline
/// is one number rather than three that drift.
#macro BANK_Z 2.6

#macro RAIL_Y 448
#macro RAIL_Z 1.9
#macro RAIL_Z_NEAR 1.7
#macro RAIL_Z_FAR 2.25

/// Screen y of the ground plane at depth z.
function ground_y(_z) {
	return global.persp_horizon + global.persp_ground_k / _z;
}

/// Screen y the rain falls from at depth z.
function cloud_y(_z) {
	return global.persp_horizon - global.persp_cloud_k / _z;
}

/// How far a thing at depth _z has washed out into the air in front of it.
///
/// One curve, shared. The ledges, the trees and anything added later have to
/// agree about what distance does to a colour, or the scene ends up holding
/// several different opinions about how far away the far shore is.
///
/// Measured from the railing rather than from the near plane, because the rail
/// is the depth the viewer is sitting at and so the thing that reads as having
/// no air in front of it at all.
function aerial_fade(_z, _max) {
	return clamp((_z - RAIL_Z) / 2.5, 0, _max);
}

/// Apparent size of anything at depth z. 1.0 at the railing, smaller beyond.
function persp_scale(_z) {
	return global.persp_z_near / _z;
}

/// Register a surface that catches rain.
///
/// Surfaces are authored in screen space on purpose. The scene is hand-painted,
/// so the painting decides where the railing edge falls and the rain is told
/// about it, rather than the rain guessing from a simulated world.
function surface_add(_z1, _z2, _x1, _x2, _y, _kind) {
	array_push(global.persp_surfaces, {
		z1: _z1, z2: _z2, x1: _x1, x2: _x2, y: _y, kind: _kind,
	});
}

/// Where a drop falling down the column at screen x, depth z comes to rest.
///
/// Returns the highest surface it meets — the first thing it would hit on the
/// way down — falling back to the open ground beyond the porch. The same call
/// will answer for placed instruments once buckets become surfaces.
function landing_at(_x, _z) {
	var _y = ground_y(_z);
	var _kind = "ground";
	var _list = global.persp_surfaces;
	for (var _i = 0; _i < array_length(_list); _i++) {
		var _s = _list[_i];
		if (_z < _s.z1 || _z > _s.z2) continue;
		if (_x < _s.x1 || _x > _s.x2) continue;
		if (_s.y < _y) {
			_y = _s.y;
			_kind = _s.kind;
		}
	}
	return { y: _y, kind: _kind };
}
