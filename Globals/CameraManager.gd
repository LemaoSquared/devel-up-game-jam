extends Node

var trauma: float = 0.0
var decay: float = 0.9
var max_offset: Vector2 = Vector2(5, 5)
var max_roll: float = 0.8
var trauma_power: float = 1.0

var current_camera: Camera2D = null

func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

func register_camera(cam: Camera2D):
	current_camera = cam

func unregister_camera(cam: Camera2D):
	if current_camera == cam:
		current_camera = null

func get_shake_offset() -> Vector2:
	if trauma <= 0:
		return Vector2.ZERO
	var amount = pow(trauma, trauma_power)
	return Vector2(
		max_offset.x * amount * randf_range(-1, 1),
		max_offset.y * amount * randf_range(-1, 1)
	)

func get_shake_rotation() -> float:
	if trauma <= 0:
		return 0.0
	var amount = pow(trauma, trauma_power)
	return max_roll * amount * randf_range(-1, 1)

func _process(delta):
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		if current_camera:
			current_camera.offset = get_shake_offset()
			current_camera.rotation = get_shake_rotation()
	elif current_camera:
		current_camera.offset = Vector2.ZERO
		current_camera.rotation = 0.0
