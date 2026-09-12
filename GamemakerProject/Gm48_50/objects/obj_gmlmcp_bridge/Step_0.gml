/// Frame counter, and the pending waits that depend on it.
///
/// A test advances the game a precise number of frames and is told when it
/// has happened, rather than sleeping and hoping.

frames += 1;
if (array_length(waits) == 0) exit;

var _still = [];
for (var _i = 0; _i < array_length(waits); _i++) {
	var _wait = waits[_i];
	if (frames >= _wait.until) {
		gmlmcp_reply(_wait.socket, _wait.id, { frames: frames });
	} else {
		array_push(_still, _wait);
	}
}
waits = _still;
