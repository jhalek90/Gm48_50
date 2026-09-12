// GML_MCP bridge - wire protocol.
//
// Newline-delimited JSON over a raw TCP socket, with the game acting as the
// server. json_stringify escapes newlines inside strings, so a bare newline is
// an unambiguous frame terminator and there is no length prefix to keep in
// sync across partial reads.

#macro GMLMCP_PROTOCOL 1
#macro GMLMCP_PORT 5959
#macro GMLMCP_MAX_CLIENTS 4

/// @desc Marker returned by a command that will reply later.
#macro GMLMCP_DEFERRED "__gmlmcp_deferred__"

/// @desc Send one JSON frame to a connected socket.
function gmlmcp_send(_socket, _payload) {
	var _text = json_stringify(_payload) + "\n";
	var _size = string_byte_length(_text);
	var _buffer = buffer_create(_size, buffer_fixed, 1);
	buffer_write(_buffer, buffer_text, _text);
	network_send_raw(_socket, _buffer, buffer_get_size(_buffer));
	buffer_delete(_buffer);
}

function gmlmcp_reply(_socket, _id, _result) {
	gmlmcp_send(_socket, { id: _id, ok: true, result: _result });
}

function gmlmcp_fail(_socket, _id, _message) {
	gmlmcp_send(_socket, { id: _id, ok: false, error: string(_message) });
}

/// @desc Decode the bytes of an async networking event into a string.
///
/// The async buffer can be larger than the payload it carries, so copy
/// exactly the reported size and terminate it rather than reading to the end
/// of the buffer.
function gmlmcp_buffer_text(_source, _size) {
	if (_size <= 0) return "";
	var _temp = buffer_create(_size + 1, buffer_fixed, 1);
	buffer_copy(_source, 0, _size, _temp, 0);
	buffer_seek(_temp, buffer_seek_start, _size);
	buffer_write(_temp, buffer_u8, 0);
	buffer_seek(_temp, buffer_seek_start, 0);
	var _text = buffer_read(_temp, buffer_string);
	buffer_delete(_temp);
	return _text;
}

/// @desc Split accumulated text into complete frames, keeping any remainder.
///
/// TCP delivers a byte stream, not messages: one read can carry half a frame
/// or three of them.
function gmlmcp_take_frames(_client) {
	var _frames = [];
	var _at = string_pos("\n", _client.pending);
	while (_at > 0) {
		var _frame = string_copy(_client.pending, 1, _at - 1);
		_client.pending = string_delete(_client.pending, 1, _at);
		if (string_length(_frame) > 0) array_push(_frames, _frame);
		_at = string_pos("\n", _client.pending);
	}
	return _frames;
}
