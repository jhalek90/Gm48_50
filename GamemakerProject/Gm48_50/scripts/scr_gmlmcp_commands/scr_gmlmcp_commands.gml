// GML_MCP bridge - command handlers.
//
// GML has no eval, so the bridge cannot run arbitrary code sent over the
// wire. Every capability is an explicit verb operating on named assets;
// anything genuinely new needs a source edit and a recompile.

function gmlmcp_dispatch(_command, _args, _socket, _id) {
	switch (_command) {
		case "ping":       return gmlmcp_cmd_ping();
		case "get_var":    return gmlmcp_cmd_get_var(_args);
		case "set_var":    return gmlmcp_cmd_set_var(_args);
		case "instances":  return gmlmcp_cmd_instances(_args);
		case "call":       return gmlmcp_cmd_call(_args);
		case "create":     return gmlmcp_cmd_create(_args);
		case "destroy":    return gmlmcp_cmd_destroy(_args);
		case "goto_room":  return gmlmcp_cmd_goto_room(_args);
		case "speed":      return gmlmcp_cmd_speed(_args);
		case "tunables":   return gmlmcp_cmd_tunables(_args);
		case "screenshot": return gmlmcp_cmd_screenshot(_args, _socket, _id);
		case "seed":       return gmlmcp_cmd_seed(_args);
		case "input":      return gmlmcp_cmd_input(_args);
		case "wait":       return gmlmcp_cmd_wait(_args, _socket, _id);
		default: throw "unknown command: " + string(_command);
	}
}

/// @desc Fix the random sequence so a run can be repeated exactly.
///
/// Without this a test that depends on any randomness is not a test.
function gmlmcp_cmd_seed(_args) {
	var _seed = _args[$ "seed"];
	if (is_undefined(_seed)) return { seed: random_get_seed() };
	random_set_seed(_seed);
	return { seed: random_get_seed() };
}

/// @desc Resolve a key name to the code GameMaker uses.
///
/// Accepts a raw code, a single character, or a vk_ name. The lookup is a
/// struct of the real constants, so the compiler checks every one of them.
function gmlmcp_key_code(_key) {
	if (is_real(_key)) return _key;
	var _name = string_lower(string(_key));
	if (string_length(_name) == 1) return ord(string_upper(_name));

	static _codes = {
		vk_left: vk_left, vk_right: vk_right, vk_up: vk_up, vk_down: vk_down,
		vk_enter: vk_enter, vk_escape: vk_escape, vk_space: vk_space,
		vk_shift: vk_shift, vk_control: vk_control, vk_alt: vk_alt,
		vk_tab: vk_tab, vk_backspace: vk_backspace, vk_delete: vk_delete,
		vk_insert: vk_insert, vk_home: vk_home, vk_end: vk_end,
		vk_pageup: vk_pageup, vk_pagedown: vk_pagedown,
		vk_f1: vk_f1, vk_f2: vk_f2, vk_f3: vk_f3, vk_f4: vk_f4,
		vk_f5: vk_f5, vk_f6: vk_f6, vk_f7: vk_f7, vk_f8: vk_f8,
	};
	if (variable_struct_exists(_codes, _name)) return _codes[$ _name];
	throw "unknown key: " + string(_key);
}

/// @desc Simulate keyboard input.
///
/// keyboard_key_press and keyboard_key_release drive the same state the game
/// reads through keyboard_check, so scripted input is indistinguishable from
/// a person at the keyboard.
function gmlmcp_cmd_input(_args) {
	if (_args[$ "clear"] == true) io_clear();

	var _press = _args[$ "press"];
	if (!is_undefined(_press)) {
		var _down = is_array(_press) ? _press : [_press];
		for (var _i = 0; _i < array_length(_down); _i++) {
			keyboard_key_press(gmlmcp_key_code(_down[_i]));
		}
	}

	var _release = _args[$ "release"];
	if (!is_undefined(_release)) {
		var _up = is_array(_release) ? _release : [_release];
		for (var _j = 0; _j < array_length(_up); _j++) {
			keyboard_key_release(gmlmcp_key_code(_up[_j]));
		}
	}
	return { pressed: _press ?? [], released: _release ?? [] };
}

/// @desc Let the game run for a number of frames, then reply.
///
/// Combined with a raised game speed this is how a test simulates seconds of
/// play in a fraction of the wall clock.
function gmlmcp_cmd_wait(_args, _socket, _id) {
	var _frames = max(1, _args[$ "frames"] ?? 1);
	with (obj_gmlmcp_bridge) {
		array_push(waits, { socket: _socket, id: _id, until: frames + _frames });
	}
	return GMLMCP_DEFERRED;
}

function gmlmcp_cmd_ping() {
	return {
		protocol: GMLMCP_PROTOCOL,
		save_directory: game_save_id,
		room: room_get_name(room),
		fps: fps,
		speed: game_get_speed(gamespeed_fps),
		frames: obj_gmlmcp_bridge.frames,
		seed: random_get_seed(),
	};
}

/// @desc Resolve an instance id, or the first live instance of a named object.
function gmlmcp_resolve_instance(_scope) {
	if (is_real(_scope)) {
		if (!instance_exists(_scope)) throw "no instance with id " + string(_scope);
		return _scope;
	}
	var _object = asset_get_index(string(_scope));
	if (_object == -1) throw "no object named " + string(_scope);
	var _found = instance_find(_object, 0);
	if (!instance_exists(_found)) throw "no live instance of " + string(_scope);
	return _found;
}

function gmlmcp_cmd_get_var(_args) {
	var _name = string(_args[$ "name"]);
	var _scope = _args[$ "scope"] ?? "global";
	if (_scope == "global") {
		if (!variable_global_exists(_name)) throw "no global named " + _name;
		return variable_global_get(_name);
	}
	return variable_instance_get(gmlmcp_resolve_instance(_scope), _name);
}

function gmlmcp_cmd_set_var(_args) {
	var _name = string(_args[$ "name"]);
	var _value = _args[$ "value"];
	var _scope = _args[$ "scope"] ?? "global";
	if (_scope == "global") {
		variable_global_set(_name, _value);
	} else {
		variable_instance_set(gmlmcp_resolve_instance(_scope), _name, _value);
	}
	return { name: _name, value: _value };
}

function gmlmcp_cmd_instances(_args) {
	var _object = all;
	var _name = _args[$ "object"];
	if (!is_undefined(_name)) {
		_object = asset_get_index(string(_name));
		if (_object == -1) throw "no object named " + string(_name);
	}
	var _limit = _args[$ "limit"] ?? 50;
	var _count = instance_number(_object);
	var _list = [];
	for (var _i = 0; _i < _count; _i++) {
		if (array_length(_list) >= _limit) break;
		var _inst = instance_find(_object, _i);
		if (!instance_exists(_inst)) continue;
		array_push(_list, {
			id: real(_inst),
			object: object_get_name(_inst.object_index),
			x: _inst.x,
			y: _inst.y,
		});
	}
	return { count: _count, instances: _list };
}

/// @desc Call a named script function with JSON arguments.
function gmlmcp_cmd_call(_args) {
	var _name = string(_args[$ "function"]);
	var _target = asset_get_index(_name);
	if (_target == -1) throw "no script or function named " + _name;
	var _list = _args[$ "args"] ?? [];
	return script_execute_ext(_target, _list);
}

function gmlmcp_cmd_create(_args) {
	var _name = string(_args[$ "object"]);
	var _object = asset_get_index(_name);
	if (_object == -1) throw "no object named " + _name;
	var _layer = _args[$ "layer"] ?? layer_get_name(layer_get_id_at_depth(0));
	var _inst = instance_create_layer(_args[$ "x"] ?? 0, _args[$ "y"] ?? 0, _layer, _object);
	return { id: real(_inst) };
}

function gmlmcp_cmd_destroy(_args) {
	var _inst = gmlmcp_resolve_instance(_args[$ "id"]);
	instance_destroy(_inst);
	return { destroyed: real(_inst) };
}

function gmlmcp_cmd_goto_room(_args) {
	var _name = string(_args[$ "room"]);
	var _target = asset_get_index(_name);
	if (_target == -1) throw "no room named " + _name;
	room_goto(_target);
	return { room: _name };
}

function gmlmcp_cmd_speed(_args) {
	var _value = _args[$ "fps"];
	if (is_undefined(_value)) return { speed: game_get_speed(gamespeed_fps) };
	game_set_speed(_value, gamespeed_fps);
	return { speed: _value };
}

/// @desc Read a live-tunable value, registering its default the first time.
///
/// This is the one bridge function meant to be called from your own game code:
///
///     move_speed = gmlmcp_tunable("move_speed", 4);
///
/// Call it where the value is used, not once in a Create event -- it returns
/// whatever the value currently is, so reading it every step is what lets an
/// outside process change it while the game runs.
///
/// The first call registers the default, which puts the name in the registry.
/// That is how an agent discovers what is adjustable without being told.
function gmlmcp_tunable(_name, _default) {
	if (!variable_global_exists("gmlmcp_tunables")) global.gmlmcp_tunables = {};
	var _key = string(_name);
	if (!variable_struct_exists(global.gmlmcp_tunables, _key)) {
		global.gmlmcp_tunables[$ _key] = _default;
	}
	return global.gmlmcp_tunables[$ _key];
}

/// @desc Read or write the live tunables registry.
///
/// Game code registers values it wants adjustable at runtime. Changing them
/// needs no recompile, which is what makes an inspect-adjust-look loop
/// possible at all: GML cannot evaluate new code in a running game.
function gmlmcp_cmd_tunables(_args) {
	if (!variable_global_exists("gmlmcp_tunables")) global.gmlmcp_tunables = {};
	var _set = _args[$ "set"];
	if (!is_undefined(_set)) {
		var _names = variable_struct_get_names(_set);
		for (var _i = 0; _i < array_length(_names); _i++) {
			var _key = _names[_i];
			variable_struct_set(global.gmlmcp_tunables, _key, _set[$ _key]);
		}
	}
	return global.gmlmcp_tunables;
}

/// @desc Queue a screenshot, taken at the end of the frame.
///
/// screen_save captures the current back buffer, so calling it from an async
/// event would catch a partly drawn frame. The reply is sent once the image
/// exists.
function gmlmcp_cmd_screenshot(_args, _socket, _id) {
	var _name = _args[$ "name"] ?? ("gmlmcp_" + string(get_timer()) + ".png");
	array_push(obj_gmlmcp_bridge.shots, { socket: _socket, id: _id, name: _name });
	return GMLMCP_DEFERRED;
}
