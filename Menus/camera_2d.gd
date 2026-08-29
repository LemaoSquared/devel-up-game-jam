extends Camera2D

func _ready():
	randomize()
	CameraManager.register_camera(self)

func _exit_tree():
	CameraManager.unregister_camera(self)
