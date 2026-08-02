class_name SardineItem
extends Node2D
signal popped_out(obj)

@export var lifetime: float = 6.0
const GIFT = preload("uid://fojbgtm48t6b")

@export_group("Spread Settings")
@export var spacing_x: float = 90.0
@export var upward_distance: float = 80.0
@export var spread_duration: float = 0.5

var is_finished: bool = false
var has_launched: bool = false

var sardine_index: int = 0
var total_sardines: int = 1
var spawn_delay: float = 0.0

@onready var sardine_area: Area2D = $Sardines


func _ready() -> void:
	visible = false
	scale = Vector2.ZERO

	sardine_area.input_pickable = false
	sardine_area.input_event.connect(_on_input_event)
	start_tilting_loop(self)

func start_tilting_loop(obj: Node2D) -> void:
	# Define your variables (tweak these to your liking)
	var tilt_angle: float = deg_to_rad(8.0) # How far to tilt (in radians)
	var duration: float = 0.8               # Time taken for half of the swing

	# 1. Create the tween and set it to loop indefinitely
	var tween = create_tween()
	tween.set_loops() 
	
	# Optional: Smooth transitions using Sine or Quad curves
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# 2. Chain the tilting properties sequentially
	# Step A: Tilt Left
	tween.tween_property(obj, "rotation", -tilt_angle, duration)
	
	# Step B: Swing all the way Right
	tween.tween_property(obj, "rotation", tilt_angle, duration * 2.0)
	
	# Step C: Return to center to finish the cycle smoothly
	tween.tween_property(obj, "rotation", 0.0, duration)

func launch() -> void:
	if has_launched or is_finished:
		return

	has_launched = true
	await _spread_apart()

	if is_finished:
		return

	var life_timer := get_tree().create_timer(
		lifetime,
		true
	)
	life_timer.timeout.connect(_on_lifetime_expired)
func _spread_apart() -> void:
	var offsets := get_fan_offsets(
		total_sardines,
		spacing_x,
		upward_distance
	)

	if sardine_index < 0 or sardine_index >= offsets.size():
		push_error("Invalid sardine_index: " + str(sardine_index))
		return

	var starting_position := global_position
	var target_position := starting_position + offsets[sardine_index]

	if spawn_delay > 0.0:
		await get_tree().create_timer(
			spawn_delay,
			true
		).timeout

	if is_finished:
		return

	visible = true

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"global_position",
		target_position,
		spread_duration
	)

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.3
	)

	await tween.finished

	if not is_finished:
		sardine_area.input_pickable = true
func _on_input_event(
	_viewport,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if is_finished:
		return

	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		AudioManager.play_sound(GIFT)
		pop_out()


func pop_out() -> void:
	if is_finished:
		return

	is_finished = true
	sardine_area.input_pickable = false

	popped_out.emit(self)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"scale",
		Vector2.ZERO,
		0.25
	)

	tween.tween_property(
		self,
		"position:y",
		position.y - 15.0,
		0.25
	)

	tween.chain().tween_callback(queue_free)


func _on_lifetime_expired() -> void:
	if is_finished:
		return

	pop_out()

static func get_fan_offsets(
	count: int,
	sx: float = 90.0,
	up_distance: float = 100.0
) -> Array[Vector2]:
	
	if count == 3:
		return [
		Vector2(-sx, -25),
		Vector2(0, -35),
		Vector2(sx, -25)
	]
	
	#if count == 3:
		#return [
			#Vector2(-sx, -up_distance),          # ↖ Left
			#Vector2(0, -up_distance - 40.0),    # ↑ Middle, higher
			#Vector2(sx, -up_distance)            # ↗ Right
		#]

	var offsets: Array[Vector2] = []

	if count <= 0:
		return offsets

	if count == 1:
		offsets.append(Vector2(0, -up_distance))
		return offsets

	var middle := (count - 1) / 2.0

	for i in range(count):
		var horizontal_step := i - middle
		offsets.append(
			Vector2(
				horizontal_step * sx,
				-up_distance
			)
		)

	return offsets
