/// Async - Networking.

var _type = async_load[? "type"];

// On connect and disconnect, "id" is the SERVER socket and the client is
// under "socket"; on data events only "id" is present and it is the client.
// Sending to the server socket fails with "can only be used on TCP sockets".
var _socket = async_load[? "socket"];
if (is_undefined(_socket)) _socket = async_load[? "id"];

if (_type == network_type_connect) {
	ds_map_set(clients, _socket, { pending: "" });
	gmlmcp_send(_socket, { event: "hello", protocol: GMLMCP_PROTOCOL, room: room_get_name(room) });
	exit;
}

if (_type == network_type_disconnect) {
	if (ds_map_exists(clients, _socket)) ds_map_delete(clients, _socket);
	exit;
}

if (_type != network_type_data) exit;
if (!ds_map_exists(clients, _socket)) exit;

var _client = clients[? _socket];
_client.pending += gmlmcp_buffer_text(async_load[? "buffer"], async_load[? "size"]);

var _frames = gmlmcp_take_frames(_client);
for (var _i = 0; _i < array_length(_frames); _i++) {
	var _request = undefined;
	try {
		_request = json_parse(_frames[_i]);
	} catch (_error) {
		gmlmcp_fail(_socket, -1, "malformed JSON frame");
		continue;
	}

	var _id = _request[$ "id"] ?? -1;
	try {
		var _result = gmlmcp_dispatch(string(_request[$ "cmd"]), _request[$ "args"] ?? {}, _socket, _id);
		// A deferred command replies once its work is actually done.
		if (!(is_string(_result) && _result == GMLMCP_DEFERRED)) {
			gmlmcp_reply(_socket, _id, _result);
		}
	} catch (_error) {
		gmlmcp_fail(_socket, _id, is_struct(_error) ? _error.message : _error);
	}
}
