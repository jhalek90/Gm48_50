/// The volume mixer.
///
/// Three faders, and every one of them is applied in a different place because
/// the three things they control reach the speakers by different routes:
///
///   Master goes through audio_master_gain, so it catches everything at once.
///   Music scales the gain of the playing track, live, so moving the fader is
///   heard straight away rather than at the next handover.
///   Rain multiplies the bed and the individual drops, which are two separate
///   gains that have to move together or the storm changes character as you
///   pull it down rather than just getting quieter.
///   Objects multiplies the instrument gains, which are already balanced
///   against each other by RMS — so this scales the whole balanced set and
///   never disturbs the balance inside it.
///
/// Kept as one script so the three cannot drift into being applied at four
/// places with two of them forgotten.
///
/// --- Why it is behind a button now ---------------------------------------
///
/// The faders used to lie open on the porch floor beside the picker, which put
/// four labelled sliders and four numbers permanently over the deck of a game
/// about watching it rain. They are worth setting once and then not looking at
/// again, and a control like that earns its place on screen only while somebody
/// is using it.
///
/// So: a speaker in the top right, and a panel that opens under it. The button
/// keeps the readout the faders used to give for free -- the arcs on it count
/// up with the master gain -- so the one thing worth knowing at a glance is
/// still legible without opening anything.

#macro MIX_MASTER  0
#macro MIX_MUSIC   1
#macro MIX_RAIN    2
#macro MIX_SFX     3
#macro MIX_COUNT   4

/// The second button of the top-right row, in from the fullscreen toggle.
#macro MIX_BTN_SIZE  UI_BTN_SIZE
#macro MIX_BTN_X     ui_btn_x(1)
#macro MIX_BTN_Y     UI_BTN_Y

/// The panel, hung under the button and squared off against the same right
/// edge. Narrow enough to clear the title wordmark, which is centred and about
/// 560 wide: the volume is worth reaching for before the game starts, so this
/// opens on the title card too and must not land on the name.
#macro MIX_PAD       14
#macro MIX_PANEL_X2  (FS_X + FS_SIZE)
#macro MIX_PANEL_X1  (MIX_PANEL_X2 - 360)
#macro MIX_PANEL_Y1  (MIX_BTN_Y + MIX_BTN_SIZE + 10)
#macro MIX_PANEL_Y2  (mixer_row_y(MIX_COUNT - 1) + MIX_H + MIX_PAD)

/// Where the faders sit inside it. Shared by the hit test and the drawing, so
/// the fader you can grab is always the fader you can see — the same
/// arrangement the day scrubber uses, and for the same reason.
#macro MIX_X1   (MIX_PANEL_X1 + MIX_PAD + 92)
#macro MIX_X2   (MIX_PANEL_X2 - MIX_PAD - 40)
#macro MIX_Y    (MIX_PANEL_Y1 + 22)
#macro MIX_DY   34
#macro MIX_H    12

function mixer_init() {
	// The mix the game opens on, not a neutral one.
	//
	// Unity everywhere was where the faders started, but it is not the balance
	// the scene wants: the rain is a wall of sound covering the whole frame and
	// the objects are what the player is actually listening for, and at equal
	// gain the rain wins. Pulled back to a quarter it becomes the room the
	// instruments are standing in, which is what it is for. The objects come
	// down a little as well, so there is headroom above them on the fader for
	// a player who wants them loud.
	//
	// These are starting positions, not limits. Anything here is a judgement
	// about the first thirty seconds; the faders are what the rest of it is
	// for.
	global.mix = array_create(MIX_COUNT, 1.0);

	global.mix[MIX_RAIN] = 0.25;
	global.mix[MIX_SFX]  = 0.80;

	global.mix_names = ["Master", "Music", "Rain", "Objects"];

	// Shut. The panel is a thing you go and get, not a thing you dismiss.
	global.mix_open = false;
}

/// Make sure the mix exists before anything reads it.
///
/// obj_mixer owns the faders, but obj_rain starts its bed in its own Create
/// event and the room decides which of the two runs first — it happens to be
/// the rain, so the first thing to ask for a volume asks before the mixer has
/// been built. Guarding here rather than relying on instance order is the same
/// arrangement the sequencer puts on its surfaces and the music puts on the
/// bar count, and for the same reason: creation order is not a contract.
function mixer_ensure() {
	if (!variable_global_exists("mix")) mixer_init();
}

function mix_master() { mixer_ensure(); return global.mix[MIX_MASTER]; }
function mix_music()  { mixer_ensure(); return global.mix[MIX_MUSIC];  }
function mix_rain()   { mixer_ensure(); return global.mix[MIX_RAIN];   }
function mix_sfx()    { mixer_ensure(); return global.mix[MIX_SFX];    }

/// Screen row of a fader.
function mixer_row_y(_i) {
	return MIX_Y + _i * MIX_DY;
}

/// Which fader a screen position is on, or -1.
///
/// The grab area is taller than the drawn bar, as on the day scrubber: a 12px
/// target is a fiddly thing to hit with a mouse, and this is a volume control,
/// not a test of aim.
///
/// Nothing at all while the panel is shut. A fader you cannot see is not a
/// fader you can grab — the same rule T already applies to the picker, and the
/// reason it is enforced here instead of at the call site is that there is now
/// more than one caller.
function mixer_row_at(_mx, _my) {
	if (!mixer_open()) return -1;
	if (_mx < MIX_X1 - 10 || _mx > MIX_X2 + 10) return -1;

	for (var _i = 0; _i < MIX_COUNT; _i++) {
		var _y = mixer_row_y(_i);
		if (_my >= _y - 11 && _my <= _y + MIX_H + 11) return _i;
	}
	return -1;
}

/// The value a screen x corresponds to.
function mixer_value_at(_mx) {
	return clamp((_mx - MIX_X1) / (MIX_X2 - MIX_X1), 0, 1);
}

/// The screen x a value sits at.
function mixer_value_x(_v) {
	return MIX_X1 + (MIX_X2 - MIX_X1) * clamp(_v, 0, 1);
}

// --- The panel -----------------------------------------------------------

function mixer_open() {
	mixer_ensure();
	return global.mix_open;
}

function mixer_toggle() {
	mixer_ensure();
	global.mix_open = !global.mix_open;
}

function mixer_close() {
	mixer_ensure();
	global.mix_open = false;
}

/// Is this screen position on the speaker button?
function mixer_btn_at(_mx, _my) {
	return (_mx >= MIX_BTN_X && _mx <= MIX_BTN_X + MIX_BTN_SIZE &&
	        _my >= MIX_BTN_Y && _my <= MIX_BTN_Y + MIX_BTN_SIZE);
}

/// Is this screen position on the open panel?
function mixer_panel_at(_mx, _my) {
	if (!mixer_open()) return false;

	return (_mx >= MIX_PANEL_X1 && _mx <= MIX_PANEL_X2 &&
	        _my >= MIX_PANEL_Y1 && _my <= MIX_PANEL_Y2);
}

/// Does the mixer own a click here?
///
/// The one question everything else asks, in place of each object naming the
/// mixer's rectangles itself. There are four things in this scene that act on
/// a click — the title card, the board, the lantern and the fullscreen button
/// — and the existing rule is that they lock each other out by hit-testing
/// their neighbours. That was fine while every control was a 34px square; a
/// panel that covers a fifth of the screen would have meant four copies of the
/// same two rectangles, and the copies drift.
///
/// True everywhere while the panel is open, not just over the panel. That is
/// the whole of what modal means, and it is what makes the click that dismisses
/// the panel do only that: without it, closing the thing would also drop an
/// instrument on whatever ledge the pointer happened to be over, which is
/// exactly the one-click-two-actions rule the board already refuses.
function mixer_claims(_mx, _my) {
	if (!ui_shown()) return false;
	return mixer_open() || mixer_btn_at(_mx, _my);
}

/// The speaker.
///
/// The arcs count up with the master gain, and go out at nothing in favour of
/// a slash. This is the one piece of state the faders used to show for free by
/// lying open on the deck, and it is the one worth keeping: "is the sound on,
/// and roughly how far up" is a glance, where the exact number is an errand.
function mixer_btn_draw() {
	var _hot = mixer_btn_at(mouse_x, mouse_y);
	var _v   = mix_master();

	// The same panel treatment the fullscreen button uses, because they sit
	// side by side and anything else would read as two interfaces.
	draw_set_alpha(1);
	draw_set_colour(merge_colour(c_black, global.pal.water, 0.18));
	draw_rectangle(MIX_BTN_X, MIX_BTN_Y, MIX_BTN_X + MIX_BTN_SIZE, MIX_BTN_Y + MIX_BTN_SIZE, false);

	draw_set_colour((_hot || mixer_open()) ? UI_INK : c_black);
	draw_set_alpha(_hot ? 0.7 : 0.45);
	draw_rectangle(MIX_BTN_X, MIX_BTN_Y, MIX_BTN_X + MIX_BTN_SIZE, MIX_BTN_Y + MIX_BTN_SIZE, true);

	// Held under the god ray threshold like the rest of the interface: shd_post
	// smears anything brighter than 0.83 luminance toward the sun, and this sits
	// against the roof where a streak would be obvious.
	draw_set_colour(UI_INK);
	draw_set_alpha(_hot ? 0.95 : 0.6);

	var _cx = MIX_BTN_X + MIX_BTN_SIZE * 0.5;
	var _cy = MIX_BTN_Y + MIX_BTN_SIZE * 0.5;

	// The box and the cone. Two shapes rather than one outline, so it stays
	// readable at this size in the same flat blocks as everything else.
	draw_rectangle(_cx - 11, _cy - 3, _cx - 5, _cy + 3, false);
	draw_triangle(_cx + 1, _cy - 9, _cx + 1, _cy + 9, _cx - 6, _cy, false);

	if (_v <= 0.01) {
		// Muted. A slash rather than a missing arc: absence of arcs is also
		// what quiet looks like, and the two have to be told apart.
		draw_line_width(_cx + 4, _cy - 8, _cx + 13, _cy + 7, 2);
	} else {
		// Two arcs, as upright bars. A curve here would be the only anti-aliased
		// thing on the screen.
		if (_v > 0.30) draw_rectangle(_cx + 4, _cy - 5, _cx + 6,  _cy + 5, false);
		if (_v > 0.66) draw_rectangle(_cx + 9, _cy - 9, _cx + 11, _cy + 9, false);
	}

	draw_set_alpha(1);
}

/// The faders, inside the panel.
///
/// `_dragging` is the row obj_mixer currently has hold of, or -1. Passed in
/// rather than read from a global because it is the state of that instance's
/// pointer, not of the mix — the same split the day scrubber keeps.
function mixer_panel_draw(_dragging) {
	if (!mixer_open()) return;

	var _x1 = MIX_X1;
	var _x2 = MIX_X2;

	// Solid, where the old strip on the deck was a tint.
	//
	// That one lay over flat wood and could afford to let it through. This one
	// sits over the roof line, the lantern's chain and a wall of pine needles,
	// and translucency loses to the dark: at 0.88 the chain still came through
	// the middle of the panel, because twelve percent of bright metal is 24 out
	// of 255 and 24 against black is not faint, it is a line.
	//
	// Tinted toward the water rather than pure black, so it belongs to the hour
	// like the sequencer's ledges do instead of being a hole cut in the scene.
	draw_set_colour(merge_colour(c_black, global.pal.water, 0.18));
	draw_set_alpha(1);
	draw_rectangle(MIX_PANEL_X1, MIX_PANEL_Y1, MIX_PANEL_X2, MIX_PANEL_Y2, false);

	draw_set_colour(UI_INK);
	draw_set_alpha(0.30);
	draw_rectangle(MIX_PANEL_X1, MIX_PANEL_Y1, MIX_PANEL_X2, MIX_PANEL_Y2, true);

	for (var _i = 0; _i < MIX_COUNT; _i++) {
		var _y  = mixer_row_y(_i);
		var _v  = global.mix[_i];
		var _on = (_dragging == _i) || (mixer_row_at(mouse_x, mouse_y) == _i);

		draw_set_halign(fa_left);
		draw_set_colour(UI_INK);
		draw_set_alpha(_on ? 0.95 : 0.65);
		draw_text(MIX_PANEL_X1 + MIX_PAD, _y - 4, global.mix_names[_i]);

		// The trough, then the filled part. Filled rather than a bare handle on a
		// line: at a glance you want the amount, and a bar reads as an amount where
		// a handle only reads as a position.
		//
		// Lifted off the panel rather than sunk into it. The trough used to be
		// black on wood and now it would be black on near-black, which loses the
		// empty half of the bar entirely — a fader at 25 has to show the 75 it
		// is not using or the number is the only thing saying so.
		draw_set_colour(UI_INK);
		draw_set_alpha(0.12);
		draw_rectangle(_x1, _y, _x2, _y + MIX_H, false);

		draw_set_colour(UI_INK);
		draw_set_alpha(_on ? 0.8 : 0.55);
		draw_rectangle(_x1, _y, mixer_value_x(_v), _y + MIX_H, false);

		// The handle, so there is something obvious to grab even at zero where the
		// filled part has nothing left to show.
		var _hx = mixer_value_x(_v);
		draw_set_colour(c_black);
		draw_set_alpha(0.7);
		draw_rectangle(_hx - 4, _y - 5, _hx + 4, _y + MIX_H + 5, false);
		draw_set_colour(UI_INK);
		draw_set_alpha(_on ? 1 : 0.85);
		draw_rectangle(_hx - 3, _y - 4, _hx + 3, _y + MIX_H + 4, false);

		// The number, so a player can set two machines the same. Right aligned
		// against the panel edge rather than run off the end of the trough,
		// which is where it used to sit when there was no edge to run off.
		draw_set_halign(fa_right);
		draw_set_alpha(_on ? 0.9 : 0.5);
		draw_text(MIX_PANEL_X2 - MIX_PAD, _y - 4, string(round(_v * 100)));
	}

	draw_set_halign(fa_left);
	draw_set_alpha(1);
}
