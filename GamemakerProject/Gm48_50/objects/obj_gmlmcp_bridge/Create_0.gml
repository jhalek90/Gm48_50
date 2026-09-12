/// GML_MCP bridge.
///
/// Persistent, so it survives room changes and stays reachable for the whole
/// session.

persistent = true;

clients = ds_map_create();
shots = [];

// Frame counter and pending waits, so a test can advance the game a precise
// number of steps and be told when it has happened.
frames = 0;
waits = [];

server = network_create_server_raw(network_socket_tcp, GMLMCP_PORT, GMLMCP_MAX_CLIENTS);
if (server < 0) {
	show_debug_message("[gmlmcp] could not listen on port " + string(GMLMCP_PORT));
} else {
	show_debug_message("[gmlmcp] listening on port " + string(GMLMCP_PORT));
}
