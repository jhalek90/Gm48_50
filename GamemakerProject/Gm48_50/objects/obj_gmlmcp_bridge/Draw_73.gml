/// Post Draw - the last point in the frame, so the back buffer is complete.

if (array_length(shots) == 0) exit;

for (var _i = 0; _i < array_length(shots); _i++) {
	var _shot = shots[_i];
	try {
		screen_save(_shot.name);
		gmlmcp_reply(_shot.socket, _shot.id, {
			file: _shot.name,
			directory: game_save_id,
		});
	} catch (_error) {
		gmlmcp_fail(_shot.socket, _shot.id, is_struct(_error) ? _error.message : _error);
	}
}
shots = [];
