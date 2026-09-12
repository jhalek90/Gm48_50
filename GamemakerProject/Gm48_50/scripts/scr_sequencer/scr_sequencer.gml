/// Where the sequencer's steps sit on the railing.
///
/// The railing runs across the view, so the pattern is laid out along it and
/// the playhead sweeps left to right. Time reads as horizontal distance, which
/// is the one spatial mapping a player already understands from every other
/// sequencer, and it costs no interface — the railing is the track.

#macro SEQ_STEPS 16
#macro SEQ_X1 132
#macro SEQ_X2 1234
#macro SEQ_SIZE 46

/// Centre of a step, in screen x.
function seq_slot_x(_i) {
	var _span = (SEQ_X2 - SEQ_X1) / SEQ_STEPS;
	return SEQ_X1 + _span * (_i + 0.5);
}

/// Which step a screen x falls in, or -1 outside the track.
function seq_slot_at(_x) {
	if (_x < SEQ_X1 || _x > SEQ_X2) return -1;
	var _span = (SEQ_X2 - SEQ_X1) / SEQ_STEPS;
	return clamp(floor((_x - SEQ_X1) / _span), 0, SEQ_STEPS - 1);
}

/// Re-register everything the rain can land on.
///
/// Rebuilt whole rather than patched: the list is tiny, and a patch has to get
/// removal right as well as addition. Placed objects become rain surfaces with
/// no change to the rain — which is what the surface registry was built for, so
/// a bucket standing on the railing is struck by the weather as well as by the
/// playhead.
function seq_rebuild_surfaces(_slots) {
	global.persp_surfaces = [];
	surface_add(RAIL_Z_NEAR, RAIL_Z_FAR, -140, room_width + 140, RAIL_Y, "wood");

	var _half = SEQ_SIZE * 0.5;
	for (var _i = 0; _i < array_length(_slots); _i++) {
		if (_slots[_i] < 0) continue;
		var _x = seq_slot_x(_i);
		surface_add(
			RAIL_Z_NEAR, RAIL_Z_FAR,
			_x - _half, _x + _half,
			RAIL_Y - SEQ_SIZE, "wood"
		);
	}
}
