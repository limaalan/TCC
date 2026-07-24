class_name NetworkConfig
extends RefCounted

const DEFAULT_PORT := 7777

const SERVER_PORT_SETTING := "network/server_port"

static func get_server_port() -> int:
	var cli_value := _get_cli_value("port")
	if cli_value.is_valid_int():
		return sanitize_port(cli_value.to_int())

	var project_value := int(ProjectSettings.get_setting(
		SERVER_PORT_SETTING,
		DEFAULT_PORT
	))
	return sanitize_port(project_value)


static func sanitize_port(port: int) -> int:
	if port <= 0 or port > 65535:
		push_warning("Invalid network port %s. Using default %s." % [port, DEFAULT_PORT])
		return DEFAULT_PORT

	return port


static func _get_cli_value(key: String) -> String:
	var prefix := "--%s=" % key

	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)

	return ""
