extends Node2D

signal popped_out(obj: Node)

var is_popping: bool = false
@onready var polaroid: Area2D = $Polaroid

func _ready() -> void:
	polaroid.input_event.connect(_on_area_input_event)
	polaroid.input_pickable = true

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
		pop_out()


func appear() -> void:
	var target_scale := scale

	scale = Vector2.ZERO
	rotation += deg_to_rad(randf_range(-6.0, 6.0))

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self,
		"scale",
		target_scale,
		0.25
	)

func pop_out() -> void:
	if is_popping:
		return

	is_popping = true
	polaroid.input_pickable = false

	popped_out.emit(self)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)
