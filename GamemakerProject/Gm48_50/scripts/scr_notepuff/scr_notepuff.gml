/// The note that comes off an object you have just tuned.
///
/// Feedback and nothing else. A puff carries no state the music reads — the
/// list could be emptied mid-flight and nothing would be lost but the picture
/// — so it is kept beside the sequencer rather than inside its pattern.
///
/// Built out of snapped blocks rather than a sprite, like everything else in
/// the scene. The glyph lands on the same four pixel grid the shaders
/// posterise onto, so it reads as part of the painting instead of as an icon
/// laid over the top of it.

/// How long one lives, in seconds, and how far it climbs in that time.
///
/// Under a second on purpose. The puff is there to be caught out of the corner
/// of the eye while the note it belongs to is still sounding; any longer and a
/// player tuning through a scale ends up looking at a stack of old notes.
///
/// Both are tunables rather than plain numbers because they are timing you
/// judge by watching, not by reading — and because a puff that only exists for
/// nine tenths of a second cannot be looked at properly unless it can be
/// slowed down from outside the running game.
#macro PUFF_SECS  0.9
#macro PUFF_RISE  46

/// The block the glyph is drawn on, matching the scene's posterise grid.
#macro PUFF_BLOCK 4

function notepuff_init() {
	global.notepuffs = [];
}

/// Throw one off a point on screen.
function notepuff_add(_x, _y, _colour, _label) {
	// The same guard the mixer and the bar counter carry: this can be called
	// from any object's Step, and nothing here decides which Create event the
	// room runs first.
	if (!variable_global_exists("notepuffs")) notepuff_init();

	array_push(global.notepuffs, {
		x: _x, y: _y, colour: _colour, label: _label,
		life: 1,

		// A little sideways drift, different every time, so a player tuning one
		// object with a run of clicks gets a spray of notes leaving it rather
		// than one note redrawn in place eight times.
		drift: random_range(-11, 11),
	});
}

function notepuff_step() {
	if (!variable_global_exists("notepuffs")) notepuff_init();

	var _l = global.notepuffs;
	var _d = (delta_time / 1000000) / max(0.05, gmlmcp_tunable("note_secs", PUFF_SECS));

	// Walked backwards, so removing one does not step over the next.
	for (var _i = array_length(_l) - 1; _i >= 0; _i--) {
		_l[_i].life -= _d;
		if (_l[_i].life <= 0) array_delete(_l, _i, 1);
	}
}

function notepuff_draw() {
	if (!variable_global_exists("notepuffs")) return;

	var _l = global.notepuffs;
	if (array_length(_l) == 0) return;

	draw_set_halign(fa_center);

	for (var _i = 0; _i < array_length(_l); _i++) {
		var _p = _l[_i];
		var _t = 1 - _p.life;   // 0 at birth, 1 at the end

		// Quick off the mark and easing out, which is how a thing that was
		// knocked loose moves. Rising at a constant rate reads as a balloon.
		var _x = _p.x + _p.drift * _t;
		var _y = _p.y - gmlmcp_tunable("note_rise", PUFF_RISE) * (1 - (1 - _t) * (1 - _t));

		// Held at full opacity for the first third, then faded. Starting the
		// fade at birth means the note is half gone before the ear has placed
		// the pitch it is standing in for.
		var _a = min(1, _p.life * 1.5);

		// A dark copy, one block down and across, first. The sky behind this is
		// the brightest thing in the scene at noon and the near nothing at
		// midnight, so the glyph has to carry its own edge to survive both.
		notepuff_glyph(_x + PUFF_BLOCK, _y + PUFF_BLOCK, c_black, _a * 0.45);
		notepuff_glyph(_x, _y, _p.colour, _a);

		// The name, above the note rather than below it. Below puts it across
		// the top of the very object the note came off, which is the one place
		// on screen it cannot be read — and the colour is the quick answer
		// here, so the letter only has to be there for the player who wants to
		// know exactly where the tuning got to.
		var _ly = _y - PUFF_BLOCK * 7 - 18;

		draw_set_colour(c_black);
		draw_set_alpha(_a * 0.5);
		draw_text(_x + 2, _ly + 2, _p.label);

		draw_set_colour(UI_INK);
		draw_set_alpha(_a * 0.9);
		draw_text(_x, _ly, _p.label);
	}

	draw_set_halign(fa_left);
	draw_set_alpha(1);
}

/// One quaver, in blocks, centred on x with its head sitting on y.
///
/// Everything below is a multiple of PUFF_BLOCK off a snapped origin, so the
/// whole glyph is made of whole blocks wherever it happens to be standing —
/// which is what keeps it from shimmering as it drifts.
function notepuff_glyph(_x, _y, _colour, _alpha) {
	var _b  = PUFF_BLOCK;
	var _px = floor(_x / _b) * _b;
	var _py = floor(_y / _b) * _b;

	// Capped: a scale degree that came up yellow sits at about 0.85 luminance
	// and would throw a beam every time that note played.
	draw_set_colour(ray_safe(_colour));
	draw_set_alpha(_alpha);

	// The head, as three bars stepping up to the right. That slant is what
	// says quaver rather than lollipop, and it is as round as anything gets on
	// a four pixel grid.
	draw_rectangle(_px - _b * 3, _py,          _px - _b,     _py + _b,     false);
	draw_rectangle(_px - _b * 3, _py - _b,     _px,          _py,          false);
	draw_rectangle(_px - _b * 2, _py - _b * 2, _px,          _py - _b,     false);

	// Stem, off the right shoulder.
	draw_rectangle(_px, _py - _b * 7, _px + _b, _py - _b, false);

	// And the flag, falling away from the top of it.
	draw_rectangle(_px + _b,     _py - _b * 7, _px + _b * 2, _py - _b * 5, false);
	draw_rectangle(_px + _b * 2, _py - _b * 6, _px + _b * 3, _py - _b * 4, false);
}
