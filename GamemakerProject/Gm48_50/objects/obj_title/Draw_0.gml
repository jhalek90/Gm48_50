if (game_playing()) exit;

// The gate comes first and covers everything, including the title card. Two
// screens, one object: both are what the game shows before it starts, and
// splitting them would mean two objects agreeing about whose turn it is.
if (audio_gated()) {
	gate_draw();
	exit;
}

// The scene, held back rather than hidden. The rain and the lake are the thing
// worth looking at and a title card that covers them wastes the one moment the
// player is certain to be looking — but the sky runs from noon overcast to
// midnight, and bone white text has to be legible against both ends of that.
draw_set_colour(c_black);
draw_set_alpha(gmlmcp_tunable("title_dim", 0.3));
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(1);

// The name, and the prompt under it. Both are drawn by scr_title, so the gate
// screen in front of this one wears the name at exactly the same size, and so
// the fntLogo the pair of them need is set and put back in one place.
var _bottom = title_wordmark(gmlmcp_tunable("title_y", 236));

// Breathing rather than blinking. This is a game about standing on a porch
// watching it rain; a prompt that flashes at you is the wrong register for the
// first thing it says.
//
// Written without the angle brackets it was asked for: fntLogo carries ASCII
// less < and >, so both would have drawn as empty boxes.
title_line("press any key to relax", _bottom + 52,
	0.45 + 0.3 * sin(t * 1.6), gmlmcp_tunable("title_prompt", 224));
