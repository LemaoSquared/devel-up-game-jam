extends Node2D

signal popped_out(obj: Node)
signal camera_activated

var is_popping: bool = false

const Duration: float = 6.0

@onready var camera_area: Area2D = $Camera


func _ready() -> void:
	camera_area.input_event.connect(_on_area_input_event)
	camera_area.input_pickable = true

	var timer := get_tree().create_timer(Duration)
	timer.timeout.connect(_on_duration_expired)


func _on_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if is_popping:
		return

	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		activate_camera()


func activate_camera() -> void:
	if is_popping:
		return

	is_popping = true
	camera_area.input_pickable = false

	camera_activated.emit()
	popped_out.emit(self)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)


func _on_duration_expired() -> void:
	if is_popping:
		return

	pop_out()


func pop_out() -> void:
	if is_popping:
		return

	is_popping = true
	camera_area.input_pickable = false
	popped_out.emit(self)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
