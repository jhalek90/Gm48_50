/// Where the sequencer's steps sit in the scene.
///
/// One track: the porch railing, running across the view so time reads as
/// horizontal distance. It is a real surface the scene already has — the rain
/// lands on it and obj_porch draws it — rather than a strip of interface laid
/// over the picture.
///
/// Everything below is written for any number of tracks, and was three of them
/// at ledges further out in the rain. That is a table edit away if it comes
/// back: the loops, the hit tests and the rain registration never assumed one.

/// The tempo of the whole game, in one place.
///
/// 120 because that is what the rhythm tracks were recorded at. At this tempo
/// SEQ_STEPS sixteenths come to exactly 2 seconds, which is one bar of the
/// music, so the pattern the player builds and the track underneath it share
/// their downbeats instead of drifting apart after the first one.
///
/// Changing this changes where the music can hand over — see music_bar_secs.
#macro SEQ_BPM 120

/// The instrument picker along the bottom of the screen.
///
/// Shared by the hit test and the drawing, so the button you can click is
/// always the button you can see — the same arrangement the day scrubber and
/// the volume faders use, and the reason none of the three can drift.
#macro PICK_X      40
#macro PICK_PITCH  84
#macro PICK_SIZE   62
#macro PICK_Y      (room_height - 104)

/// How far in front of the scene a strike effect is drawn.
///
/// In front of everything the game draws: the porch at -100, the objects at
/// -120, the lantern at -140, the mixer at -150 and the day scrubber at -200.
/// Only the title card at -300 is nearer, and that is never up while the
/// playhead is running.
#macro SEQ_VFX_DEPTH -250

/// How big a strike effect is drawn, against its sprite.
#macro SEQ_VFX_SCALE 2

/// How many steps a loop has, and how they divide the beat.
///
/// Eight eighth-notes, so a loop comes to exactly one bar of the music at
/// SEQ_BPM. That relationship is what the music handover depends on — see
/// music_bar_secs — so the two move together: halving the steps without
/// halving the division would make a loop half a bar, and every track would
/// hand over on an offbeat.
///
/// It was sixteen sixteenths, which came to the same two seconds.
#macro SEQ_STEPS 8
#macro SEQ_DIV   2
/// Must match the length of the table in tracks_init below. The two are kept
/// apart because a macro is what the arrays and loops are sized from, and a
/// table is what a person edits.
#macro SEQ_TRACKS 1

/// The tracks, front to back.
///
/// Authored in screen space for the same reason the rain surfaces are: the
/// painting decides where a ledge is and the sequencer is told, rather than
/// deriving a position from a simulated world and hoping it lands on the art.
/// `z` is the depth the audio and the rain use; `size` is how big an object
/// standing there reads, which shrinks with distance.
function tracks_init() {
	// Drawn from the shared RAIL_Y and RAIL_Z, so the row the player puts
	// objects on is the same railing the rain is told to land on and the porch
	// is told to draw. Three numbers agreeing by accident is a bug that looks
	// like an art problem.
	//
	// If more rows come back, they go here: y values spaced so no row's objects
	// reach into the one above it, since a row is `size` tall and stands on its
	// own y. The pair that used to sit here were { z: 2.7, y: 398, size: 34 }
	// and { z: 3.9, y: 356, size: 25 }.
	global.tracks = [
		{ z: RAIL_Z, y: RAIL_Y, x1: 132, x2: 1234, size: 46 },
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

/// Which picker button a screen position is over, or -1.
function seq_palette_at(_mx, _my) {
	if (_my < PICK_Y || _my > PICK_Y + PICK_SIZE) return -1;

	for (var _p = 0; _p < instrument_count(); _p++) {
		var _bx = PICK_X + _p * PICK_PITCH;
		if (_mx >= _bx && _mx <= _bx + PICK_SIZE) return _p;
	}
	return -1;
}

/// The left edge of the randomiser, one pitch past the last instrument.
///
/// Derived rather than written down, so the button follows the palette along
/// when an instrument is added instead of ending up underneath one.
function seq_dice_x() {
	return PICK_X + instrument_count() * PICK_PITCH;
}

/// Is this screen position on the randomiser?
function seq_dice_at(_mx, _my) {
	var _bx = seq_dice_x();
	return (_mx >= _bx && _mx <= _bx + PICK_SIZE &&
	        _my >= PICK_Y && _my <= PICK_Y + PICK_SIZE);
}

/// Throw the whole board away and deal a new one.
///
/// Every step is rolled on its own: an instrument, or nothing. The gaps are
/// what make it a pattern rather than a wall — a board where every step sounds
/// has no rhythm in it, only tempo — so the fill chance is well under one and
/// is a tunable, because how busy is right is a thing you judge by listening.
///
/// Notes are rolled for everything it places, exactly as placing by hand does,
/// so a dealt board follows the day round the same way a built one does.
///
/// Mutates the arrays it is handed, which are the sequencer's own.
function seq_randomise(_slots, _notes) {
	var _n    = instrument_count();
	var _fill = clamp(gmlmcp_tunable("dice_fill", 0.5), 0, 1);
	var _any  = false;

	for (var _t = 0; _t < SEQ_TRACKS; _t++) {
		for (var _i = 0; _i < SEQ_STEPS; _i++) {
			if (random(1) < _fill) {
				_slots[_t][_i] = irandom(_n - 1);
				_notes[_t][_i] = music_roll_notes();
				_any = true;
			} else {
				_slots[_t][_i] = -1;
			}
		}
	}

	// An all-misses deal is rare and reads as a broken button rather than as
	// bad luck, so one step is always given something.
	if (!_any) {
		var _t = irandom(SEQ_TRACKS - 1);
		var _i = irandom(SEQ_STEPS - 1);
		_slots[_t][_i] = irandom(_n - 1);
		_notes[_t][_i] = music_roll_notes();
	}
}

/// Deal a fresh board, from anywhere.
///
/// seq_randomise works on the arrays it is handed, and those arrays belong to
/// obj_sequencer — so this is the one place that knows where they live, and
/// everything else only has to say "deal". Without it the title card would
/// need to reach into the sequencer's instance variables to start a game,
/// which is the sort of coupling that is fine once and unpickable by the
/// fourth time.
///
/// Guarded on the instance existing, because the caller may be running before
/// the room has finished building itself.
function seq_deal() {
	if (!instance_exists(obj_sequencer)) return;

	with (obj_sequencer) {
		seq_randomise(slots, notes);
		dice_face = irandom_range(1, 6);
		dirty     = true;
	}
}

/// A die, in blocks.
///
/// Drawn rather than given a sprite, for the same reason the instruments are:
/// it has to sit in a row with eight things made of snapped bars and share
/// their grid, and a die is six pips and a square.
function dice_draw(_cx, _cy, _size, _face, _colour, _pip, _alpha) {
	var _half   = _size * 0.5;
	var _corner = max(2, round(_size / 8));

	draw_set_alpha(_alpha);
	draw_set_colour(_colour);

	// Two overlapping rectangles, each inset on one axis. That is a square
	// with its corners knocked off, which is as round as the rest of this
	// scene ever gets.
	draw_rectangle(_cx - _half, _cy - _half + _corner,
	               _cx + _half, _cy + _half - _corner, false);
	draw_rectangle(_cx - _half + _corner, _cy - _half,
	               _cx + _half - _corner, _cy + _half, false);

	// Pip positions as thirds of the face, so one table serves every size.
	var _faces = [
		[[0, 0]],
		[[-1, -1], [1, 1]],
		[[-1, -1], [0, 0], [1, 1]],
		[[-1, -1], [1, -1], [-1, 1], [1, 1]],
		[[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]],
		[[-1, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [1, 1]],
	];

	// Spaced and sized against the six, which is the crowded face. Pips any
	// bigger or any closer together and its two columns of three close up into
	// two bars, and the die stops reading as a die.
	var _list = _faces[clamp(_face, 1, 6) - 1];
	var _off  = round(_size * 0.28);
	var _r    = max(1, round(_size / 14));

	draw_set_colour(_pip);
	for (var _i = 0; _i < array_length(_list); _i++) {
		var _px = _cx + _list[_i][0] * _off;
		var _py = _cy + _list[_i][1] * _off;
		draw_rectangle(_px - _r, _py - _r, _px + _r, _py + _r, false);
	}
}

/// The splash the playhead leaves where it landed.
///
/// Thrown on every step the playhead passes, whether or not anything is
/// standing there. That is the point of it: the playhead is a pale bar behind
/// the objects and easy to lose, and a board with two things on it said
/// nothing at all about where the other six steps were. Marking the empty
/// ones turns the beat into something you can see coming, so a player can
/// place an object *on* time rather than discovering afterwards where the
/// time was.
///
/// It is deliberately not tied to the note: a sounding slot also throws a
/// coloured quaver, and keeping the two apart is what lets the splash say
/// "here, now" while the note says "this pitch".
///
/// The sprite is the caller's, because the two cases want to look different.
/// A step that struck something splatters; an empty one is only a marker, and
/// wants to be quieter than the thing it is hinting at — if the hint were as
/// loud as the hit, a bare board would look as busy as a full one and the
/// marker would stop being information.
///
/// objVfxFnf destroys itself when its animation ends, so this creates and
/// forgets — nothing holds a reference or counts them.
function seq_splash(_t, _i, _sprite) {
	var _k = global.tracks[_t];

	var _fx = instance_create_depth(track_slot_x(_t, _i), _k.y, SEQ_VFX_DEPTH, objVfxFnf);
	_fx.sprite_index = _sprite;

	// Scaled from here rather than by giving objVfxFnf a Create event, so the
	// object stays exactly as it was authored and the sequencer owns how big
	// its own playhead marker is.
	_fx.image_xscale = SEQ_VFX_SCALE;
	_fx.image_yscale = SEQ_VFX_SCALE;
}

/// Throw the note a slot is sounding up off the object standing in it.
///
/// Lives here rather than in the sequencer's Step because it is this table
/// that knows where the top of an object on a given ledge is, and both callers
/// — the playhead striking a slot and a click tuning one — need the same
/// answer. Two copies of this arithmetic would drift the moment a ledge moved.
function seq_throw_note(_t, _i, _semi) {
	var _k    = global.tracks[_t];
	var _look = music_note_look(_semi);

	// Started a little clear of the object rather than on its top edge, so the
	// note reads as having come off it instead of growing out of it.
	notepuff_add(track_slot_x(_t, _i), _k.y - _k.size - 14, _look.colour, _look.label);
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
