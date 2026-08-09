extends Node2D

signal popped_out(obj: Node)
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

	var timer := get_tree().create_timer(Duration)
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
	ParticleManager.spawn_particle(CLICK_PARTICLE,global_position)
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

func start_floating(obj: Node2D, float_height: float = 12.0, duration: float = 1.0) -> void:
	var float_tween = obj.create_tween().set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Phase A: Float UP relatively from current position
	float_tween.tween_property(obj, "position:y", -float_height, duration).as_relative()
	
	# Phase B: Float DOWN relatively (must double height to pass the original center point)
	float_tween.tween_property(obj, "position:y", float_height * 2.0, duration * 2.0).as_relative()
	
	# Phase C: Float back UP relatively to return exactly to where the loop started
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
	popped_out.emit(self,true)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
