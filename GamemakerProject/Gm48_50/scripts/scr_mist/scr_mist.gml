/// Mist lying on the lake at dawn and dusk.
///
/// Drawn over both the far range and the water rather than into either. The
/// band that reads as morning mist sits exactly on the join between them — it
/// veils the foot of the mountains and the far half of the lake at once — and
/// neither shd_water nor the mountain sprite can reach across that line. So it
/// is its own pass, laid over both after they are drawn.
///
/// --- Why it comes and goes -----------------------------------------------
///
/// Strongest when the sun is near the horizon and gone by the middle of the
/// day, which is when mist actually burns off. That comes straight off the
/// sun's altitude, so it arrives twice a cycle without a schedule: once as the
/// morning track starts and once as the night one does. The scene already had
/// three phases of colour; this gives the two boundaries between them
/// something of their own.

/// How far above and below the horizon the band reaches.
#macro MIST_RISE 26
#macro MIST_FALL 104

/// How many drifting patches make up each row.
#macro MIST_PATCHES 4

/// How thick the mist is right now, 0 to 1.
///
/// Peaks with the sun on the horizon and falls away either side of it, so it
/// is thickest at dawn and dusk and absent at noon and midnight. Taken from
/// altitude rather than from the phase index for the same reason the fireflies
/// are: phases change on a hard boundary and this has to arrive gradually.
function mist_strength() {
	var _alt = sky_sun().alt;
	return clamp(1 - abs(_alt) * 1.7, 0, 1) * gmlmcp_tunable("mist", 1.0);
}

function mist_draw() {
	var _k = mist_strength();
	if (_k <= 0.01) return;

	var _px = 4;
	var _h  = global.persp_horizon;

	// Pale, and taken from the sky rather than fixed white — mist is lit air,
	// so at dawn it should be the colour of the dawn and not a grey sheet laid
	// over it. Kept under the god ray threshold like everything else that
	// catches light here.
	var _col = merge_colour(global.pal.sky_mid, c_white, 0.35);

	// Two drifts at unrelated rates, so the band does not slide as one piece.
	var _t = global.water_time;

	draw_set_colour(_col);

	for (var _y = _h - MIST_RISE; _y < _h + MIST_FALL; _y += _px) {
		// A soft band centred a little below the horizon. Mist sits *on* the
		// water, so the thickest part belongs just the near side of the join
		// rather than on it — centred exactly on the horizon it reads as a
		// stripe drawn across the picture.
		var _d = (_y - (_h + 16)) / 58;
		var _band = exp(-_d * _d);

		if (_band < 0.02) continue;

		for (var _i = 0; _i < MIST_PATCHES; _i++) {
			// Each patch has its own width, its own starting place and its own
			// speed. Identical patches on one speed is a moving wallpaper, and
			// that is the failure this whole project keeps having to avoid.
			var _seed = _y * 0.37 + _i * 97;
			var _w    = 220 + rock_hash(_seed) * 420;
			var _spd  = 4 + rock_hash(_seed + 11) * 9;

			// Wrapped over a span wider than the room, so a patch slides in
			// from off screen rather than appearing at the edge.
			var _span = room_width + 700;
			var _x = ((rock_hash(_seed + 23) * _span + _t * _spd) mod _span) - 350;

			// Found by eye at three times the first guess. Four overlapping
			// patches at a tenth each came to almost nothing once the
			// posterise had rounded them off — a wash this faint is a wash
			// that quantises away.
			draw_set_alpha(_band * _k * 0.33);
			draw_rectangle(floor(_x / _px) * _px, _y,
			               floor((_x + _w) / _px) * _px, _y + _px, false);
		}
	}

	draw_set_alpha(1);
}
