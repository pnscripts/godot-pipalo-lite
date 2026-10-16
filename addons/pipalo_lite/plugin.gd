@tool
extends EditorPlugin
## Adds the "PipaloLite" autoload (device tracking) when the plugin is enabled.
## The nodes register themselves through class_name and show their own icons.

const AUTOLOAD := "PipaloLite"


func _enable_plugin() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD):
		add_autoload_singleton(AUTOLOAD, get_script().resource_path.get_base_dir() + "/pipalo_device.gd")


func _disable_plugin() -> void:
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD):
		remove_autoload_singleton(AUTOLOAD)
