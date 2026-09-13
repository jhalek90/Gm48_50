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

/// The chord root under this bar, in semitones from D.
///
/// music_rhythm is written as groups of four because that is how the piece is
/// written, but for this the grouping is not the interesting part — what is
/// wanted is "the bar the sequencer is on, what is underneath it". So the
/// groups are walked as one flat run of bars and indexed by the bar count,
/// which also means a group of some other length would work without this
/// needing to know.
///
/// Read from global.seq_bar, so it answers for the same bar the playhead is
/// on and the same one the chords would be struck on. Anything asking this is
/// trying to agree with the music, and the bar count is what the music agrees
/// with.
///
/// This is the first thing to read music_rhythm. The table has sat here since
/// the scales were written, described as what the lead pools were chosen
/// against; the wind chime is the first voice to ask it what the harmony
/// actually is.
function music_root_now() {
	var _groups = global.music_rhythm[day_phase_index() mod DAY_PHASES];

	var _total = 0;
	for (var _i = 0; _i < array_length(_groups); _i++) {
		_total += array_length(_groups[_i]);
	}
	if (_total <= 0) return 0;

	var _k = ((global.seq_bar mod _total) + _total) mod _total;

	for (var _i = 0; _i < array_length(_groups); _i++) {
		var _g = _groups[_i];
		if (_k < array_length(_g)) return _g[_k];
		_k -= array_length(_g);
	}

	return 0;
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

/// Which of the six an object is sounding right now, as an index into its set.
///
/// The clock answers this, not the object, so every placed thing is reading
/// the same position in the day — and a note being played and a click that
/// retunes it can never land on different entries of the same set.
function music_note_index() {
	return day_phase_index() * MUSIC_SECTIONS + music_section();
}

/// Which of those six an object should be sounding right now.
function music_note_now(_notes) {
	if (!is_array(_notes)) return 0;

	var _i = music_note_index();
	return (_i >= 0 && _i < array_length(_notes)) ? _notes[_i] : 0;
}

/// Where a semitone sits in a pool, as a scale degree, or -1 if it is not one.
function music_degree_of(_pool, _semi) {
	for (var _i = 0; _i < array_length(_pool); _i++) {
		if (_pool[_i] == _semi) return _i;
	}
	return -1;
}

/// Tune a placed object up one degree of the scale it is currently in.
///
/// The note block idiom: one click, one step up, wrapping off the top back to
/// the bottom. It walks the pool by degree rather than by semitone, because
/// the pool is a scale — stepping by semitone would hand out the notes between
/// its degrees, which is every note the key does not contain.
///
/// Only the entry for the current phase and half is touched, which is the one
/// the player can hear. The other five keep what they were rolled, so a tuning
/// made at noon does not silently rewrite the parts of the day nobody is
/// listening to — and so the note the player just landed on is theirs until
/// the track hands over, at which point the object returns to its own key.
///
/// Mutates the array it is handed. GML arrays are references and the caller
/// holds the object's own set, which is the point: there is nowhere else the
/// change would need to be written back to. Returns the semitone it landed on,
/// which is all a caller needs — what that note looks like is music_note_look.
function music_note_bump(_notes) {
	var _pool = music_scale(day_phase_index(), music_section());
	var _n    = array_length(_pool);
	var _i    = music_note_index();

	if (!is_array(_notes) || _i < 0 || _i >= array_length(_notes)) return _pool[0];

	// A note that is not in the pool means the key moved under it. Start the
	// walk at the bottom rather than guessing where it would have been.
	var _d    = music_degree_of(_pool, _notes[_i]);
	var _next = (_d < 0) ? 0 : (_d + 1) mod _n;

	_notes[_i] = _pool[_next];
	return _pool[_next];
}

/// The colour of a scale degree.
///
/// Hue walks the scale, so the seven degrees come out as seven readable
/// colours and a given degree is the same colour in every key. That is what
/// makes showing it worth anything: it says where in the scale the note landed
/// without the player having to count clicks from the bottom.
///
/// Stopped short of a full turn of the wheel — run the hue the whole way round
/// and the top degree comes back to the red the bottom one started on.
function music_degree_colour(_degree, _steps) {
	var _n = max(1, _steps);
	return make_colour_hsv((_degree / _n) * 200, 190, 255);
}

/// What a note looks like when it is shown: its colour and its name.
///
/// The single place that turns a semitone into a picture, so a note thrown by
/// the playhead and the same note thrown by a click cannot come out looking
/// like two different things. The degree is read back out of the pool rather
/// than carried around beside the note, because the note is the only thing
/// anything else stores — and the pool it belongs to is whatever the clock
/// says it is at the moment of the strike.
function music_note_look(_semi) {
	var _pool = music_scale(day_phase_index(), music_section());

	// Not in the pool means the tables were edited under a placed object. Show
	// it as the root rather than refusing to draw it: the colour is a hint, and
	// a wrong hint is better than a note that silently stops appearing.
	var _d = max(0, music_degree_of(_pool, _semi));

	return {
		colour: music_degree_colour(_d, array_length(_pool)),
		label:  music_note_name(_semi),
	};
}

/// A semitone offset from D, named.
function music_note_name(_semi) {
	var _names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

	// D is the third pitch class, and these offsets run either side of zero, so
	// the modulo has to survive a negative.
	return _names[((2 + _semi) mod 12 + 12) mod 12];
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
	// The median length, not the longest.
	//
	// Taking the longest let one bad export stretch the entire day: the
	// afternoon recording came back at 128 seconds where the other two were
	// 64, its second half being nothing but silence, and the cycle obligingly
	// doubled to fit it — so every phase ran twice as long and the afternoon
	// sat in a minute of dead air. The median cannot be dragged by a single
	// outlier in either direction, which is the property worth having when the
	// tracks are still being re-exported.
	var _lens = array_create(array_length(global.music_tracks), 0);
	for (var _i = 0; _i < array_length(_lens); _i++) {
		_lens[_i] = audio_sound_length(global.music_tracks[_i]);
	}
	array_sort(_lens, true);

	var _longest = _lens[array_length(_lens) div 2];

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
	return SEQ_STEPS * 60 / (max(20, gmlmcp_tunable("bpm", SEQ_BPM)) * SEQ_DIV);
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
