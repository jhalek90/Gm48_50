/// The fullscreen toggle, top right.
///
/// Top right because every other piece of interface is already spoken for: the
/// day scrubber has the top left, the picker and the mixer have the bottom.
/// The roof fills that corner and nothing in the scene happens there, so a
/// small control sits on it without covering anything.
///
/// Drawn whether or not the game has started, unlike the picker and the
/// faders. Choosing a window size is the one setting somebody might reasonably
/// want to change *before* they begin, and a control that appears only after
/// you commit is a control you find by accident.

/// The corner button of the top-right row.
#macro FS_SIZE UI_BTN_SIZE
#macro FS_X    ui_btn_x(0)
#macro FS_Y    UI_BTN_Y

/// Is this screen position on the button?
function fullscreen_at(_mx, _my) {
	return (_mx >= FS_X && _mx <= FS_X + FS_SIZE &&
	        _my >= FS_Y && _my <= FS_Y + FS_SIZE);
}

function fullscreen_toggle() {
	window_set_fullscreen(!window_get_fullscreen());
}

function fullscreen_draw() {
	var _hot = fullscreen_at(mouse_x, mouse_y);
	var _on  = window_get_fullscreen();

	// The same panel treatment the picker buttons use, so it belongs to the
	// same interface rather than looking like a browser chrome dropped on top.
	// Solid, not a tint. The row reaches across the lantern's chain, which
	// hangs at 1204 and showed straight through a translucent panel and under
	// the glyph on top of it. Tinted toward the water like the two modal
	// panels, so the whole interface is one material.
	draw_set_alpha(1);
	draw_set_colour(merge_colour(c_black, global.pal.water, 0.18));
	draw_rectangle(FS_X, FS_Y, FS_X + FS_SIZE, FS_Y + FS_SIZE, false);

	draw_set_colour(_hot ? UI_INK : c_black);
	draw_set_alpha(_hot ? 0.7 : 0.45);
	draw_rectangle(FS_X, FS_Y, FS_X + FS_SIZE, FS_Y + FS_SIZE, true);

	// Four corner brackets. Pointing outward means "make this bigger"; when
	// already fullscreen they are inset and point inward, which is the same
	// icon everything else uses and so needs no label.
	//
	// Held under the god ray threshold like the rest of the interface, or a
	// bright glyph up against the roof would smear toward the sun.
	draw_set_colour(UI_INK);
	draw_set_alpha(_hot ? 0.95 : 0.6);

	var _cx  = FS_X + FS_SIZE * 0.5;
	var _cy  = FS_Y + FS_SIZE * 0.5;
	var _r   = _on ? FS_SIZE * 0.16 : FS_SIZE * 0.30;
	var _arm = 7;
	var _t   = 2;

	// Arms run inward from the corners when expanding, outward when already
	// full — one sign flip serves both icons.
	var _dir = _on ? 1 : -1;

	for (var _sx = -1; _sx <= 1; _sx += 2) {
		for (var _sy = -1; _sy <= 1; _sy += 2) {
			var _x = _cx + _sx * _r;
			var _y = _cy + _sy * _r;

			// The horizontal arm, then the vertical one, meeting at the corner.
			draw_rectangle(min(_x, _x + _sx * _dir * _arm), _y - _t * 0.5,
			               max(_x, _x + _sx * _dir * _arm), _y + _t * 0.5, false);

			draw_rectangle(_x - _t * 0.5, min(_y, _y + _sy * _dir * _arm),
			               _x + _t * 0.5, max(_y, _y + _sy * _dir * _arm), false);
		}
	}

	draw_set_alpha(1);
}
