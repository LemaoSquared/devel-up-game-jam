extends Node

func _ready() -> void:
	# 1. Change the Text Name on the Taskbar / Window Title
	DisplayServer.window_set_title("Taptap")
	# 2. Change the Taskbar Icon dynamically (Optional)
	var custom_logo = load("res://Assets/Object Assets/Yarn.png") # Make sure path matches your image
	if custom_logo:
		var image = custom_logo.get_image()
		DisplayServer.window_set_icon(image)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F:
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	# Check if the current platform/display driver physically supports changing window modes
	if not DisplayServer.has_feature(DisplayServer.FEATURE_SUBWINDOWS) and OS.has_feature("web"):
		print("Fullscreen via window mode is not supported on this platform style.")
		return

	var current_mode := DisplayServer.window_get_mode()
	
	if current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
