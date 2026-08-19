extends Node2D

signal popped_out(obj: Node, was_clicked: bool, item_type: int)
signal camera_activated
const CAMERA = preload("uid://ce3v411cq8pkb")
const CLICK_PARTICLE = preload("uid://d3v5eteyxeame")

var is_popping: bool = false
const Duration: float = 6.0

@onready var camera_area: Area2D = $Camera
@onready var sprite_2d: AnimatedSprite2D = $Camera/Sprite2D

func _ready() -> void:
	sprite_2d.play("default")
	camera_area.input_event.connect(_on_area_input_event)
	camera_area.input_pickable = true

	var timer := get_tree().create_timer(Duration, false)
	timer.timeout.connect(_on_duration_expired)
	start_floating(self)

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
	AudioManager.play_sound(CAMERA)
	ParticleManager.spawn_particle(CLICK_PARTICLE, global_position)
	if is_popping:
		return

	is_popping = true
	camera_area.input_pickable = false
	
	camera_activated.emit()
	# Pass was_clicked = true and Item.CAMERA (index 3 based on ItemManager enum)
	popped_out.emit(self, true, 3) 

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)

func start_floating(obj: Node2D, float_height: float = 12.0, duration: float = 1.0) -> void:
	var float_tween = obj.create_tween().set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	
	float_tween.tween_property(obj, "position:y", -float_height, duration).as_relative()
	float_tween.tween_property(obj, "position:y", float_height * 2.0, duration * 2.0).as_relative()
	float_tween.tween_property(obj, "position:y", -float_height * 2.0, duration * 2.0).as_relative()

func _on_duration_expired() -> void:
	if is_popping:
		return
	pop_out()

func pop_out() -> void:
	if is_popping:
		return

	is_popping = true
	camera_area.input_pickable = false
	# When it expires without being clicked, pass was_clicked = false and Item.CAMERA (3)
	# ItemManager already ignores CAMERA for missing penalties, keeping HP completely safe!
	popped_out.emit(self, false, 3)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
