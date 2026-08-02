extends Node2D

signal popped_out(obj: Node)

# POLAROID
@export var polaroid_scene: PackedScene = preload(
	"res://Menus/item_polaroid.tscn"
)
@export var polaroid_texture: Texture2D

@export_group("Drop Settings")
@export var fall_duration: float = 0.5
@export var settle_duration: float = 0.6
@export var idle_sway_enabled: bool = true
@export var idle_sway_amplitude_deg: float = 6.0
@export var idle_sway_speed: float = 1.2

var is_transforming: bool = false
var is_gravity: bool = false
var is_popping: bool = false
var is_hanging: bool = false

var hang_length: float = 0.0
var idle_time: float = 0.0
var anchor_position: Vector2 = Vector2.ZERO

const Duration: float = 6.0

@onready var yarn: Area2D = $Yarn


func _ready() -> void:
	add_to_group("camera_targets")

	yarn.input_event.connect(_on_area_input_event)
	yarn.input_pickable = true

	var timer := get_tree().create_timer(Duration, true)
	timer.timeout.connect(_on_duration_expired)


func _process(delta: float) -> void:
	if is_hanging and idle_sway_enabled and not is_popping:
		idle_time += delta

		var angle := (
			deg_to_rad(idle_sway_amplitude_deg)
			* sin(idle_time * idle_sway_speed)
		)

		global_position = (
			anchor_position
			+ Vector2(sin(angle), cos(angle)) * hang_length
		)

		rotation = angle * 0.5


func spawn_drop_and_hang(
	target_global_pos: Vector2,
	anchor_global_pos: Vector2,
	delay: float = 0.0
) -> void:
	anchor_position = anchor_global_pos
	hang_length = (
		target_global_pos - anchor_global_pos
	).length()

	global_position = anchor_global_pos
	scale = Vector2.ONE
	is_hanging = false

	var drop_tween := create_tween()
	drop_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	drop_tween.set_trans(Tween.TRANS_BOUNCE)
	drop_tween.set_ease(Tween.EASE_OUT)

	var total_duration := fall_duration + settle_duration

	drop_tween.tween_property(
		self,
		"global_position",
		target_global_pos,
		total_duration
	).set_delay(delay)

	drop_tween.tween_callback(
		func():
			if not is_popping:
				is_hanging = true
	)


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


func transform_to_polaroid() -> void:
	if is_popping or is_transforming:
		return

	is_transforming = true
	is_popping = true
	is_hanging = false
	yarn.input_pickable = false

	var parent := get_parent()

	if parent == null:
		push_error("Yarn has no parent for the Polaroid replacement.")
		return

	var polaroid := polaroid_scene.instantiate() as Node2D
	parent.add_child(polaroid)

	polaroid.global_position = global_position
	polaroid.global_rotation = global_rotation
	polaroid.global_scale = global_scale

	var photo_sprite := polaroid.get_node_or_null(
		"Polaroid/Sprite2D"
	) as Sprite2D

	if photo_sprite != null and polaroid_texture != null:
		photo_sprite.texture = polaroid_texture

	ItemManager.register_spawned_object(polaroid)

	if polaroid.has_method("appear"):
		polaroid.appear()

	popped_out.emit(self)
	queue_free()


func _on_duration_expired() -> void:
	if is_popping or is_transforming:
		return

	pop_out()


func pop_out() -> void:
	if is_popping:
		return

	is_popping = true
	is_hanging = false
	yarn.input_pickable = false

	popped_out.emit(self)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		self,
		"scale",
		Vector2.ZERO,
		0.3
	)
	tween.tween_callback(queue_free)
