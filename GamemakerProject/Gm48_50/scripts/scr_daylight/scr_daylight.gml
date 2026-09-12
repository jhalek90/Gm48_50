/// The day's light, as three keyed palettes.
///
/// THIS IS THE PLACE TO CHANGE WHAT THE SCENE LOOKS LIKE. Every colour that
/// varies with the time of day lives in the table below and nowhere else — the
/// sky, the lake, the porch, the rain and the splashes all read `global.pal`,
/// so retinting the whole game at one hour is an edit to one row here.
///
/// Time is a single number in [0, 1) that wraps, with the three phases spaced
/// evenly around it. Every frame the two phases either side of the current time
/// are blended into `global.pal`, so there is no moment where the scene snaps —
/// "Morning" is a key the picture passes through, not a state it sits in.
///
/// Storing a palette per phase and blending, rather than tinting one base
/// palette by a brightness curve, is the more code but the right call: a real
/// sky does not merely dim toward night, it changes hue, and the warm band
/// above the horizon that makes the dusk read has no business being there at
/// noon. A single multiplier cannot express that.

#macro DAY_PHASES 3

/// The hour the cycle starts at, so the readout means something to a person.
/// The phases land 8 hours apart: Morning 06:00, Afternoon 14:00, Night 22:00.
#macro DAY_START_HOUR 6

/// Where the debug scrubber sits. Shared by the hit test and the drawing so
/// the bar you can grab is always the bar you can see.
#macro DAY_UI_X1 40
#macro DAY_UI_X2 560
#macro DAY_UI_Y  150
#macro DAY_UI_H  14

/// The three keys of the cycle.
///
/// Every one of these is a rainstorm, so none of them is a clear sky — the
/// range runs from flat overcast daylight to deep wet dark, and the saturation
/// stays low throughout. The colours are authored by eye against the scene
/// rather than derived from a light model, for the same reason the rain
/// surfaces are authored in screen space: the picture decides.
function daylight_init() {
	global.day_keys = [
		{
			name: "Morning",
			// Early, cold and still damp. The warm band is low and pale — the
			// sun is up but has not got through the weather yet.
			sky_top:    make_colour_rgb( 86, 104, 138),
			sky_mid:    make_colour_rgb(140, 156, 178),
			sky_warm:   make_colour_rgb(222, 186, 158),
			// The sky's two lights, and the cloud bulk they sit behind. Overcast
			// throughout, so the sun is never a hard yellow disc — it is a pale warm
			// patch the weather is letting through, and it reads as morning because
			// the cloud around it is still cold.
			sun:        make_colour_rgb(255, 226, 178),
			moon:       make_colour_rgb(198, 210, 230),
			cloud:      make_colour_rgb( 96, 108, 132),
			cloud_lit:  make_colour_rgb(188, 196, 210),
			shore:      make_colour_rgb(104, 118, 136),
			water:      make_colour_rgb( 96, 112, 134),
			water_near: make_colour_rgb( 58,  72,  88),
			bank:       make_colour_rgb( 56,  68,  58),
			// The near bank. `bank` is the soil the blades stand in; the other two
			// are the blades themselves, body and the tips that catch the light.
			// Three tones is all the posterising has to work with, so they have to
			// be chosen to read apart at four bands, not to be subtle.
			grass:      make_colour_rgb( 58,  74,  58),
			grass_lit:  make_colour_rgb( 88, 106,  78),
			// Ambient light, for art that is painted rather than palette-driven.
			// The trees are drawn multiplied through this, so they darken with the
			// hour without anyone having to author a night version of the sprite.
			light:      make_colour_rgb(200, 210, 225),
			wood_dark:  make_colour_rgb( 56,  44,  40),
			wood:       make_colour_rgb( 88,  68,  56),
			wood_lit:   make_colour_rgb(120,  94,  74),
			rain:       make_colour_rgb(226, 238, 250),
			splash:     make_colour_rgb(232, 244, 255),
		},
		{
			name: "Afternoon",
			// The brightest the storm gets. Deliberately grey rather than blue:
			// an overcast afternoon has no warm band at all, and leaving one in
			// is what makes daylight scenes read as permanently sunset.
			sky_top:    make_colour_rgb(126, 142, 166),
			sky_mid:    make_colour_rgb(168, 180, 196),
			sky_warm:   make_colour_rgb(206, 208, 206),
			// Cloud and sky are close together here on purpose. A bright overcast
			// afternoon has very little contrast in the sky — push the clouds darker
			// and the weather stops reading as a downpour and starts reading as
			// scattered cumulus on a nice day.
			sun:        make_colour_rgb(255, 246, 224),
			moon:       make_colour_rgb(206, 214, 228),
			cloud:      make_colour_rgb(120, 130, 150),
			cloud_lit:  make_colour_rgb(208, 214, 222),
			shore:      make_colour_rgb(120, 132, 148),
			water:      make_colour_rgb(112, 128, 148),
			water_near: make_colour_rgb( 70,  84, 100),
			bank:       make_colour_rgb( 64,  78,  64),
			grass:      make_colour_rgb( 70,  88,  66),
			grass_lit:  make_colour_rgb(104, 124,  88),
			light:      make_colour_rgb(255, 255, 250),
			wood_dark:  make_colour_rgb( 66,  52,  46),
			wood:       make_colour_rgb(102,  80,  64),
			wood_lit:   make_colour_rgb(138, 110,  86),
			rain:       make_colour_rgb(236, 244, 252),
			splash:     make_colour_rgb(240, 248, 255),
		},
		{
			name: "Night",
			// Deep indigo with a last bruise of colour above the horizon. The
			// rain dims with everything else — leaving it bright white is the
			// single thing that stops a night scene from reading as night.
			sky_top:    make_colour_rgb( 22,  26,  48),
			sky_mid:    make_colour_rgb( 44,  44,  76),
			sky_warm:   make_colour_rgb( 78,  62,  86),
			// The moon is the only thing in the scene that does not dim at night —
			// it is the light source now, and the clouds are lit by it. The sun
			// colour is still keyed because the blend runs through it on the way
			// back round to morning, but it is below the horizon the whole phase.
			sun:        make_colour_rgb(120,  96, 110),
			moon:       make_colour_rgb(206, 216, 240),
			cloud:      make_colour_rgb( 30,  34,  58),
			cloud_lit:  make_colour_rgb( 68,  72, 104),
			shore:      make_colour_rgb( 28,  34,  54),
			water:      make_colour_rgb( 30,  38,  60),
			water_near: make_colour_rgb( 16,  22,  34),
			bank:       make_colour_rgb( 20,  28,  26),
			grass:      make_colour_rgb( 24,  34,  34),
			grass_lit:  make_colour_rgb( 40,  54,  56),
			// Not black. A night tint that multiplies the trees to nothing loses
			// their silhouette against the lake, which is the only thing about them
			// that still reads at this hour.
			light:      make_colour_rgb( 70,  80, 120),
			wood_dark:  make_colour_rgb( 20,  16,  16),
			wood:       make_colour_rgb( 36,  26,  22),
			wood_lit:   make_colour_rgb( 54,  40,  32),
			rain:       make_colour_rgb(150, 172, 200),
			splash:     make_colour_rgb(170, 192, 216),
		},
	];

	global.day_t = 0;
	global.pal = {};
	daylight_apply();
}

/// Fold a time back into [0, 1).
///
/// Written with floor rather than frac so it handles negatives: scrubbing
/// backward past midnight should arrive at the evening, not at a negative
/// index that reads off the end of the table.
function day_wrap(_t) {
	return _t - floor(_t);
}

/// Blend the two phases either side of the current time into `global.pal`.
///
/// The fields are walked by name rather than listed out, so adding a colour to
/// the table above is the only edit needed — a hand-written blend function is
/// a second list of the same fields, and the two drift apart the first time
/// someone is in a hurry.
function daylight_apply() {
	var _f = day_wrap(global.day_t) * DAY_PHASES;
	var _i = floor(_f) mod DAY_PHASES;
	var _j = (_i + 1) mod DAY_PHASES;
	var _k = _f - floor(_f);

	var _a = global.day_keys[_i];
	var _b = global.day_keys[_j];
	var _names = variable_struct_get_names(_a);

	for (var _n = 0; _n < array_length(_names); _n++) {
		var _key = _names[_n];
		if (_key == "name") continue;
		global.pal[$ _key] = merge_colour(_a[$ _key], _b[$ _key], _k);
	}
}

/// One colour from the table at an arbitrary time.
///
/// Deliberately does not touch `global.pal`: this answers "what would the sky
/// be at 4pm" while the scene is busy drawing 9am, which is what lets the
/// debug scrubber paint itself with the cycle it controls.
function day_sample(_t, _key) {
	var _f = day_wrap(_t) * DAY_PHASES;
	var _i = floor(_f) mod DAY_PHASES;
	var _j = (_i + 1) mod DAY_PHASES;
	return merge_colour(
		global.day_keys[_i][$ _key],
		global.day_keys[_j][$ _key],
		_f - floor(_f)
	);
}

/// The phase the clock is currently in.
function day_phase_index() {
	return floor(day_wrap(global.day_t) * DAY_PHASES) mod DAY_PHASES;
}

function day_phase_name(_i) {
	return global.day_keys[_i mod DAY_PHASES].name;
}

/// How far through the current phase, 0 to 1.
function day_phase_progress() {
	var _f = day_wrap(global.day_t) * DAY_PHASES;
	return _f - floor(_f);
}

/// The time of day as a 24-hour clock, for the readout.
function day_clock() {
	var _h = DAY_START_HOUR + day_wrap(global.day_t) * 24;
	var _hh = floor(_h) mod 24;
	var _mm = floor((_h - floor(_h)) * 60);
	return string_replace(string_format(_hh, 2, 0), " ", "0") + ":" +
	       string_replace(string_format(_mm, 2, 0), " ", "0");
}

/// Is this screen position on the scrubber?
///
/// The grab area is taller than the drawn bar. A 14px target is a fiddly thing
/// to hit with a mouse, and this is a tool, not a puzzle.
function day_slider_hit(_mx, _my) {
	return (_mx >= DAY_UI_X1 - 8 && _mx <= DAY_UI_X2 + 8 &&
	        _my >= DAY_UI_Y - 12 && _my <= DAY_UI_Y + DAY_UI_H + 12);
}

/// The time a screen x on the scrubber corresponds to.
function day_slider_t(_mx) {
	return clamp((_mx - DAY_UI_X1) / (DAY_UI_X2 - DAY_UI_X1), 0, 0.9999);
}

/// The screen x a time sits at on the scrubber.
function day_slider_x(_t) {
	return DAY_UI_X1 + (DAY_UI_X2 - DAY_UI_X1) * day_wrap(_t);
}
