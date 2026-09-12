/// Release the socket so a relaunch can bind the port again.

if (server >= 0) network_destroy(server);
ds_map_destroy(clients);
