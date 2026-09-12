/// Where the sequencer's steps sit in the scene.
///
/// Three tracks, laid out by depth rather than stacked flat. The railing runs
/// across the view so time reads as horizontal distance, and the further tracks
/// are ledges further out in the rain: higher up the screen, drawn smaller, and
/// heard from further away through the same audio space the rain uses. One
/// playhead sweeps all three, so a step can fire up to three objects at once.
///
/// Laying the extra tracks out flat would have been less work and would have
/// thrown away the projection the rest of the scene already agrees on.

#macro SEQ_STEPS 16
#macro SEQ_TRACKS 3

/// The tracks, front to back.
///
/// Authored in screen space for the same reason the rain surfaces are: the
/// painting decides where a ledge is and the sequencer is told, rather than
/// deriving a position from a simulated world and hoping it lands on the art.
/// `z` is the depth the audio and the rain use; `size` is how big an object
/// standing there reads, which shrinks with distance.
function tracks_init() {
	// The y values are spaced so no row's objects reach into the ledge above
	// it. A row is `size` tall and stands on its own y, so each gap is the
	// next y minus this one minus that row's size — keep a few pixels in hand
	// or the rows read as one cluttered band instead of three distances.
	global.tracks = [
		{ z: RAIL_Z, y: RAIL_Y, x1: 132, x2: 1234, size: 46 },
		{ z: 2.7,    y: 398,    x1: 196, x2: 1170, size: 34 },
		{ z: 3.9,    y: 356,    x1: 248, x2: 1118, size: 25 },
	];
}

/// Centre of a step on a track, in screen x.
function track_slot_x(_t, _i) {
	var _k = global.tracks[_t];
	return _k.x1 + (_k.x2 - _k.x1) / SEQ_STEPS * (_i + 0.5);
}

/// Which step a screen x falls in on a track, or -1 outside it.
function track_slot_at(_t, _x) {
	var _k = global.tracks[_t];
	if (_x < _k.x1 || _x > _k.x2) return -1;
	return clamp(floor((_x - _k.x1) / ((_k.x2 - _k.x1) / SEQ_STEPS)), 0, SEQ_STEPS - 1);
}

/// The cell under a screen position, as { track, step }, or track -1 for none.
///
/// Searched front to back so that where two tracks overlap on screen the
/// nearest one wins, which is the one the player is reaching for.
function seq_cell_at(_mx, _my) {
	for (var _t = 0; _t < SEQ_TRACKS; _t++) {
		var _k = global.tracks[_t];
		if (_my < _k.y - _k.size || _my > _k.y) continue;
		var _s = track_slot_at(_t, _mx);
		if (_s >= 0) return { track: _t, step: _s };
	}
	return { track: -1, step: -1 };
}

/// Re-register everything the rain can land on.
///
/// Rebuilt whole rather than patched: the list is tiny, and a patch has to get
/// removal right as well as addition. Placed objects become rain surfaces with
/// no change to the rain — which is what the surface registry was built for, so
/// an object standing out there is struck by the weather as well as the
/// playhead. Each track registers at its own depth, so rain lands on the near
/// ledge and the far one at the right times and sizes.
function seq_rebuild_surfaces(_slots) {
	global.persp_surfaces = [];
	surface_add(RAIL_Z_NEAR, RAIL_Z_FAR, -140, room_width + 140, RAIL_Y, "wood");

	for (var _t = 0; _t < SEQ_TRACKS; _t++) {
		var _k = global.tracks[_t];
		var _half = _k.size * 0.5;
		var _band = _k.z * 0.14;

		for (var _i = 0; _i < SEQ_STEPS; _i++) {
			if (_slots[_t][_i] < 0) continue;
			var _x = track_slot_x(_t, _i);
			surface_add(
				_k.z - _band, _k.z + _band,
				_x - _half, _x + _half,
				_k.y - _k.size, "wood"
			);
		}
	}
}
