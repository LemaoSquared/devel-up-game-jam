class_name SardineItem
extends Node2D
signal popped_out(obj, was_clicked: bool)

@export var lifetime: float = 12.0
const GIFT = preload("uid://fojbgtm48t6b")
const CLICK_PARTICLE = preload("uid://d3v5eteyxeame")
const FLOATING_LABEL = preload("uid://cu8xcr7igstbj")

@export_group("Spread Settings")
@export var spacing_x: float = 90.0
@export var upward_distance: float = 80.0
@export var spread_duration: float = 0.5

@export_group("Swimming Escape Settings")
@export var swim_speed: float = 120.0
@export var wave_amplitude: float = 15.0  # Height of the sine wave bob
@export var wave_frequency: float = 8.0   # Speed of the swimming oscillation
@export var offscreen_padding: float = 150.0

var is_finished: bool = false
var has_launched: bool = false
var is_popping: bool = false
var is_swimming: bool = false

var sardine_index: int = 0
var total_sardines: int = 1
var spawn_delay: float = 0.0

var swim_direction: int = 1  # 1 = Swim Right, -1 = Swim Left
var time_alive: float = 0.0
var base_y: float = 0.0

@onready var sardine_area: Area2D = $Sardines
@onready var gift: AnimatedSprite2D = $GiftAnimation
@onready var sprite: Node2D = $Sprite2D if has_node("Sprite2D") else self # Fallback reference for flipping

func _ready() -> void:
	# Ensure they don't start at zero scale/invisible if launched immediately
	scale = Vector2.ONE
	visible = true

	sardine_area.input_pickable = false
	start_tilting_loop(self)

func launch() -> void:
	if has_launched or is_finished:
		return

	has_launched = true
	
	# Fallback: make sure scale and visibility are correct right before spreading
	visible = true
	scale = Vector2.ONE
	
	await _spread_apart()

	if is_finished:
		return

	# Determine escape direction based on initial world position relative to screen center
	var viewport_width = get_viewport_rect().size.x
	if global_position.x < viewport_width / 2.0:
		swim_direction = -1  # Left side swims left off-screen
	else:
		swim_direction = 1   # Right side swims right off-screen

	scale.x = abs(scale.x) * swim_direction

	base_y = global_position.y
	is_swimming = true

	var life_timer := get_tree().create_timer(lifetime, false)
	life_timer.timeout.connect(_on_lifetime_expired)

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


func _process(delta: float) -> void:
	if not is_swimming or is_finished:
		return

	time_alive += delta

	# Horizontal swimming movement
	global_position.x += swim_speed * swim_direction * delta

	# Vertical Sine Wave oscillation (swimming bobbing effect)
	global_position.y = base_y + sin(time_alive * wave_frequency) * wave_amplitude

	# Check if it has escaped past the screen bounds
	var viewport_width = get_viewport_rect().size.x
	if swim_direction > 0 and global_position.x > viewport_width + offscreen_padding:
		_escape_offscreen()
	elif swim_direction < 0 and global_position.x < -offscreen_padding:
		_escape_offscreen()

func _escape_offscreen() -> void:
	if is_finished:
		return
	is_finished = true
	is_swimming = false
	sardine_area.input_pickable = false
	
	popped_out.emit(self, false) # Count as missed/escaped
	queue_free()

func _spread_apart() -> void:
	var offsets := get_fan_offsets(total_sardines, spacing_x, upward_distance)

	if sardine_index < 0 or sardine_index >= offsets.size():
		push_error("Invalid sardine_index: " + str(sardine_index))
		return

	var starting_position := global_position
	var target_position := starting_position + offsets[sardine_index]

	if spawn_delay > 0.0:
		await get_tree().create_timer(spawn_delay, true).timeout

	if is_finished:
		return

	visible = true

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)

	tween.tween_property(self, "global_position", target_position, spread_duration)
	tween.tween_property(self, "scale", Vector2(abs(scale.x) if scale.x != 0 else 1.0, 1.0), 0.3)

	await tween.finished

	if not is_finished:
		sardine_area.input_pickable = true

# --- Multi-touch & Mouse Input Handling ---
func _input(event: InputEvent) -> void:
	if is_finished or not sardine_area.input_pickable:
		return
		
	var click_pos = Vector2.ZERO
	var is_triggered: bool = false
	
	if event is InputEventScreenTouch and event.pressed:
		click_pos = event.position
		is_triggered = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_pos = event.position
		is_triggered = true
		
	if is_triggered:
		if global_position.distance_to(click_pos) < 64.0:
			trigger_click()

func trigger_click() -> void:
	is_popping = true  
	is_swimming = false
	sardine_area.input_pickable = false
	
	AudioManager.play_sound(GIFT)
	ParticleManager.spawn_particle(CLICK_PARTICLE, global_position)
	gift.visible = true
	gift.play("default")
	await gift.animation_finished
	pop_out(true)

func pop_out(was_clicked: bool = false) -> void:
	if is_finished:
		return

	is_finished = true
	is_swimming = false
	sardine_area.input_pickable = false

	popped_out.emit(self, was_clicked)
	
	if was_clicked:
		ScoreManager.add_points(5)
		
		# Spawn +5 floating label only in Endless Mode
		if is_inside_tree() and "is_endless" in ItemManager and ItemManager.is_endless and FLOATING_LABEL:
			var label = FLOATING_LABEL.instantiate()
			get_tree().current_scene.add_child(label)
			if label.has_method("setup"):
				label.setup(5, global_position)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)

	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_property(self, "position:y", position.y - 15.0, 0.25)

	tween.chain().tween_callback(queue_free)

func _on_lifetime_expired() -> void:
	if is_finished:
		return

	pop_out(false)

static func get_fan_offsets(count: int, sx: float = 90.0, up_distance: float = 100.0) -> Array[Vector2]:
	if count == 3:
		return [
			Vector2(-sx, -25),
			Vector2(0, -35),
			Vector2(sx, -25)
		]

	var offsets: Array[Vector2] = []

	if count <= 0:
		return offsets

	if count == 1:
		offsets.append(Vector2(0, -up_distance))
		return offsets

	var middle := (count - 1) / 2.0

	for i in range(count):
		var horizontal_step := i - middle
		offsets.append(Vector2(horizontal_step * sx, -up_distance))

	return offsets
