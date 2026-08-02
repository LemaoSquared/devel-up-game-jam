extends Node2D
signal popped_out(obj: Node)
var is_popping: bool = false
var points_value: int = 0
@onready var polaroid: Area2D = $Polaroid
@onready var gift_animation: AnimatedSprite2D = $GiftAnimation

func _ready() -> void:
	gift_animation.visible = false
	polaroid.input_event.connect(_on_area_input_event)
	polaroid.input_pickable = true
	start_tilting_loop(self)

func setup(points: int) -> void:
	points_value = points

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
		gift_animation.visible = true
		gift_animation.play("default")
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

func start_tilting_loop(obj: Node2D) -> void:
	var tilt_angle: float = deg_to_rad(8.0)
	var duration: float = 0.8
	var tween = create_tween()
	tween.set_loops() 
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(obj, "rotation", -tilt_angle, duration)
	tween.tween_property(obj, "rotation", tilt_angle, duration * 2.0)
	tween.tween_property(obj, "rotation", 0.0, duration)

func pop_out() -> void:
	if is_popping:
		return
	is_popping = true
	polaroid.input_pickable = false

	if points_value != 0:
		ScoreManager.add_points(points_value)

	popped_out.emit(self)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)
