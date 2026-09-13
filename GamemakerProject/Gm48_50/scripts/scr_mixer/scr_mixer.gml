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

#macro MIX_MASTER  0
#macro MIX_MUSIC   1
#macro MIX_RAIN    2
#macro MIX_SFX     3
#macro MIX_COUNT   4

/// Where the faders sit. Shared by the hit test and the drawing, so the fader
/// you can grab is always the fader you can see — the same arrangement the day
/// scrubber uses, and for the same reason.
#macro MIX_X1    980
#macro MIX_X2   1268
#macro MIX_Y    624
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
function mixer_row_at(_mx, _my) {
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
