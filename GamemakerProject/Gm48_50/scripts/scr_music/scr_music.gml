/// The background rhythm: one track per phase of the day.
///
/// These tracks are the spine the player plays over, so the handover between
/// them has to land where the player's own pattern lands. Two rules do that,
/// and both matter:
///
/// The fade starts BEFORE the phase boundary rather than at it, so the outgoing
/// track is already silent when the next one is due. Fading at the boundary and
/// then waiting for the sequencer to come round would leave a hole the length
/// of a whole loop, every time.
///
/// The incoming track waits for the top of the sequencer's loop. A track that
/// starts a third of a bar late never recovers, and everything the player lays
/// over it is wrong from then on.

/// How many sections a phase is divided into, for notes.
///
/// Two, because each phase's lead is written as two halves. At 32 bars a phase
/// that is sixteen bars each.
#macro MUSIC_SECTIONS 2

/// The notes a player can be handed, in semitones from D.
///
/// Every sample was recorded at D, so a note is nothing more than how far that
/// recording gets shifted. Octaves are folded to whichever instance of the
/// pitch class sits nearest D rather than taken as written: past about five
/// semitones a struck vessel stops sounding like the same object and starts
/// sounding like tape running at the wrong speed.
function music_scales_init() {
	var _d_major = [-5, -3, -1, 0, 2, 4, 5];   // A  B  C#  D  E  F#  G
	var _a_major = [-5, -3, -1, 0, 2, 4, 6];   // A  B  C#  D  E  F#  G#

	// Lead pools, by phase and then by half.
	//
	// Both halves of every phase hold the same seven pitch classes. The parts
	// are written from a different starting note in each half, but as a set of
	// available notes they are identical — so the halving re-rolls a note
	// rather than re-keying it. Stored as two anyway, because that is how the
	// music is written and because the day they diverge this table is already
	// the right shape.
	//
	// The change that matters is across phases: night is A major where morning
	// and afternoon are D major. One note, G against G#, and it is the whole
	// harmonic difference between the scene at noon and the scene at midnight.
	global.music_scales = [
		[_d_major, _d_major],   // Morning
		[_d_major, _d_major],   // Afternoon
		[_a_major, _a_major],   // Night
	];

	// The harmony underneath, in semitones from D, four bars to a group.
	//
	// Nothing reads this yet — every placed object is a lead. It lives here
	// because it is what the lead pools were chosen against, and because the
	// day an object plays a root rather than a scale note, this is the table it
	// will be asking. All three come to 32 bars, which is what says the
	// afternoon recording is twice the length it should be.
	global.music_rhythm = [
		[[0, -5, 0, 2], [2, 5, 0, 2]],                                 // D A D E  |  E G D E
		[[0, -5, 0, 2], [0, -5, -2, 4], [5, 0, 5, -3], [-2, 5, -4, 1]],// DADE DACF# GDGB CGBbEb
		[[0, -5, 0, 4], [4, -1, 4, -5]],                               // D A D F# |  F# C# F# A
	];
}

/// Which half of the current phase the clock is in.
function music_section() {
	return min(MUSIC_SECTIONS - 1, floor(day_phase_progress() * MUSIC_SECTIONS));
}

/// The pool for one phase and half.
function music_scale(_phase, _section) {
	return global.music_scales[_phase mod DAY_PHASES][_section mod MUSIC_SECTIONS];
}

/// Roll a note for every phase and every section at once.
///
/// Six numbers, decided when the object is placed and never again. That is what
/// lets a placed object follow the day: when the track hands over, the object
/// already knows what it should be playing in the new key, so a pattern the
/// player built survives into the next piece instead of going sour the moment
/// the music changes. Re-rolling at the handover would keep it in key too, but
/// it would quietly rewrite what they made while they were listening to it.
function music_roll_notes() {
	var _out = array_create(DAY_PHASES * MUSIC_SECTIONS, 0);

	for (var _p = 0; _p < DAY_PHASES; _p++) {
		for (var _s = 0; _s < MUSIC_SECTIONS; _s++) {
			var _pool = music_scale(_p, _s);
			_out[_p * MUSIC_SECTIONS + _s] = _pool[irandom(array_length(_pool) - 1)];
		}
	}
	return _out;
}

/// Which of those six an object should be sounding right now.
function music_note_now(_notes) {
	if (!is_array(_notes)) return 0;

	var _i = day_phase_index() * MUSIC_SECTIONS + music_section();
	return (_i >= 0 && _i < array_length(_notes)) ? _notes[_i] : 0;
}

function music_init() {
	music_scales_init();

	// The sequencer owns the bar count, but the music must not depend on which
	// object's Create event the room happens to run first — the same guard the
	// sequencer puts on its own surfaces.
	if (!variable_global_exists("seq_bar")) global.seq_bar = 0;

	global.music_tracks = [snd_music_morning, snd_music_afternoon, snd_music_night];

	// The day is built around the music rather than the music squeezed into the
	// day. A phase lasts exactly as long as the longest track, so a handover
	// falls at the end of a piece instead of somewhere in its middle — and if
	// the tracks are ever replaced with longer ones, the cycle follows on its
	// own rather than needing a number edited here.
	var _longest = 0;
	for (var _i = 0; _i < array_length(global.music_tracks); _i++) {
		_longest = max(_longest, audio_sound_length(global.music_tracks[_i]));
	}

	// Falls back if the runtime will not report a length for an asset.
	if (_longest <= 1) _longest = 64;

	// Rounded to a whole number of sequencer loops. This is what makes the
	// handover free: if a phase is an exact multiple of the pattern length,
	// every phase boundary already falls on a downbeat and the incoming track
	// never has to wait for one. The quantise in music_step then stops being
	// the mechanism and becomes the safety net, for when the clock is scrubbed
	// or the tempo is changed out from under it.
	//
	// Measured against the tempo at startup. Change bpm later and the two drift
	// apart again — the wait comes back, but nothing breaks.
	var _bar  = music_bar_secs();
	var _bars = max(1, round(_longest / _bar));
	global.music_phase_secs = _bars * _bar;

	global.music_inst   = -1;   // the playing instance, or -1
	global.music_index  = -1;   // which track that is
	global.music_want   = -1;   // which track is waiting for a downbeat
	global.music_bar    = -1;   // the sequencer bar we last saw
	global.music_fading = false;
}

/// How long one turn of the sequencer pattern takes, in seconds.
///
/// SEQ_STEPS sixteenths at the current tempo. This is the unit the music has to
/// agree with, because it is the unit the player hears their own pattern in.
function music_bar_secs() {
	return SEQ_STEPS * 60 / (max(20, gmlmcp_tunable("bpm", SEQ_BPM)) * 4);
}

/// How long a full day should be for the music to fit it exactly.
function music_cycle_secs() {
	return global.music_phase_secs * DAY_PHASES;
}

function music_play(_index, _gain) {
	if (global.music_inst >= 0) audio_stop_sound(global.music_inst);

	// Looped, even though a phase is the length of one play. The loop is the
	// safety net: if the clock is scrubbed or the day is slowed down, the track
	// carries on rather than leaving the scene dry.
	global.music_inst   = audio_play_sound(global.music_tracks[_index], 10, true);
	global.music_index  = _index;
	global.music_want   = -1;
	global.music_fading = false;

	audio_sound_gain(global.music_inst, _gain, 0);
}

/// Called once per step by obj_daylight, after the clock has advanced.
function music_step() {
	var _gain = gmlmcp_tunable("music_gain", 0.5) * mix_music();
	var _fade = max(0.1, gmlmcp_tunable("music_fade", 1.6));

	var _cycle = max(1, gmlmcp_tunable("day_secs", music_cycle_secs()));
	var _left  = (1 - day_phase_progress()) * (_cycle / DAY_PHASES);

	// Follow the fader live. Skipped while a fade is running: the fade owns the
	// gain until it lands, and writing over it here would cancel it mid-way and
	// leave the outgoing track playing under the incoming one.
	if (global.music_inst >= 0 && !global.music_fading) {
		audio_sound_gain(global.music_inst, _gain, 0);
	}

	// --- Fade the outgoing track out, early ------------------------------
	if (global.music_inst >= 0 && !global.music_fading && _left <= _fade) {
		audio_sound_gain(global.music_inst, 0, _fade * 1000);
		global.music_fading = true;
	}

	// --- Queue the incoming one ------------------------------------------
	var _phase = day_phase_index();
	if (_phase != global.music_index) global.music_want = _phase;

	// --- And start it on a downbeat --------------------------------------
	// obj_sequencer counts a bar every time its playhead comes back round to
	// the top. Waiting for that count to change is what puts the first beat of
	// the track on the first step of the pattern.
	//
	// At startup music_bar is -1 and the count is already 0, so the first track
	// begins immediately rather than making the scene wait a bar in silence.
	if (global.music_want >= 0 && global.seq_bar != global.music_bar) {
		music_play(global.music_want, _gain);
	}

	global.music_bar = global.seq_bar;
}
