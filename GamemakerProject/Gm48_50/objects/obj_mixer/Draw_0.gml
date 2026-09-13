/// Draw the faders.
///
/// On the porch floor to the right of the instrument picker, in the same flat
/// blocks as the rest of the scene rather than as a chrome widget. A panel
/// behind them because the deck is wood grain and white text on grain is hard
/// to read at any hour.

if (!game_playing()) exit;

var _x1 = MIX_X1;
var _x2 = MIX_X2;

draw_set_colour(c_black);
draw_set_alpha(0.45);
draw_rectangle(_x1 - 116, MIX_Y - 20, _x2 + 54, mixer_row_y(MIX_COUNT - 1) + MIX_H + 16, false);

draw_set_halign(fa_left);

for (var _i = 0; _i < MIX_COUNT; _i++) {
	var _y = mixer_row_y(_i);
	var _v = global.mix[_i];
	var _on = (dragging == _i) || (mixer_row_at(mouse_x, mouse_y) == _i);

	draw_set_colour(c_white);
	draw_set_alpha(_on ? 0.95 : 0.65);
	draw_text(_x1 - 108, _y - 4, global.mix_names[_i]);

	// The trough, then the filled part. Filled rather than a bare handle on a
	// line: at a glance you want the amount, and a bar reads as an amount where
	// a handle only reads as a position.
	draw_set_colour(c_black);
	draw_set_alpha(0.5);
	draw_rectangle(_x1, _y, _x2, _y + MIX_H, false);

	draw_set_colour(c_white);
	draw_set_alpha(_on ? 0.8 : 0.55);
	draw_rectangle(_x1, _y, mixer_value_x(_v), _y + MIX_H, false);

	// The handle, so there is something obvious to grab even at zero where the
	// filled part has nothing left to show.
	var _hx = mixer_value_x(_v);
	draw_set_colour(c_black);
	draw_set_alpha(0.7);
	draw_rectangle(_hx - 4, _y - 5, _hx + 4, _y + MIX_H + 5, false);
	draw_set_colour(c_white);
	draw_set_alpha(_on ? 1 : 0.85);
	draw_rectangle(_hx - 3, _y - 4, _hx + 3, _y + MIX_H + 4, false);

	// The number, so a player can set two machines the same.
	draw_set_alpha(_on ? 0.9 : 0.5);
	draw_text(_x2 + 12, _y - 4, string(round(_v * 100)));
}

draw_set_alpha(1);
