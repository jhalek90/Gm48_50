if (game_playing()) exit;

// The scene, held back rather than hidden. The rain and the lake are the thing
// worth looking at and a title card that covers them wastes the one moment the
// player is certain to be looking — but the sky runs from noon overcast to
// midnight, and bone white text has to be legible against both ends of that.
draw_set_colour(c_black);
draw_set_alpha(gmlmcp_tunable("title_dim", 0.3));
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(1);

// Capped under the god ray threshold. shd_post treats anything above
// ray_thresh — 0.83 luminance — as a light source, and white letters would put
// every stroke of the wordmark over it, smearing a copy of the name across the
// sky toward the sun. This reads as the same bone white and sits at 0.77.
var _ink = make_colour_rgb(202, 196, 182);

// The title card is the one place with its own face. obj_render sets fntPixels
// once for the whole game because the interface only ever wants the one font;
// this is the exception that comment anticipated, so it is set here, where it
// is used, and put back at the bottom of the event. The font is global draw
// state and this object draws last of all, so leaving fntLogo set would hand
// it to every UI event on the following frame.
draw_set_font(fntLogo);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);

// Scaled to a target width rather than by a fixed multiplier, so the wordmark
// stays the size it was composed at if fntPixels is ever re-generated at a
// different point size.
var _name = "Petrichord";
var _s  = gmlmcp_tunable("title_size", 560) / max(1, string_width(_name));
var _cx = room_width * 0.5;
var _cy = gmlmcp_tunable("title_y", 236);

// Both strings are sized this way, which is what lets fntLogo be regenerated
// at any point size without moving anything on screen: a bigger source font
// comes out as a smaller multiplier and a sharper wordmark, not as a wordmark
// that has grown off the edge of the lake.

draw_set_colour(c_black);
draw_set_alpha(0.45);
draw_text_transformed(_cx + 6, _cy + 6, _name, _s, _s, 0);

draw_set_colour(_ink);
draw_set_alpha(1);
draw_text_transformed(_cx, _cy, _name, _s, _s, 0);

// The prompt, breathing rather than blinking. This is a game about standing on
// a porch watching it rain; a prompt that flashes at you is the wrong register
// for the first thing it says.
//
// Written without the angle brackets it was asked for: fntPixels carries ASCII
// less < and >, so both would have drawn as empty boxes.
var _msg = "press any key to start";
var _p   = 0.45 + 0.3 * sin(t * 1.6);
var _ps  = gmlmcp_tunable("title_prompt", 224) / max(1, string_width(_msg));
var _py  = _cy + string_height(_name) * _s * 0.5 + 52;

draw_set_colour(c_black);
draw_set_alpha(_p * 0.5);
draw_text_transformed(_cx + 3, _py + 3, _msg, _ps, _ps, 0);

draw_set_colour(_ink);
draw_set_alpha(_p);
draw_text_transformed(_cx, _py, _msg, _ps, _ps, 0);

draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(fntPixels);
