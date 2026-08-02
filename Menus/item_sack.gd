extends Node2D

signal popped_out(obj: Node)

#POLAROID
@export var polaroid_scene: PackedScene = preload(
	"res://Menus/item_polaroid.tscn"
)
@export var polaroid_texture: Texture2D
var is_transforming: bool = false

var is_gravity: bool = false
var is_popping: bool = false

const Duration: float = 15.0
const REQUIRED_CLICKS: int = 10

var click_count: int = 0
var hit_tween: Tween

@export var sack_regions: Array[Rect2] = [
	Rect2(0.0, 104.0, 75.856, 56.829),  # Phase 1
	Rect2(80.0, 104.0, 75.856, 56.829),  # Phase 2
	Rect2(160.0, 104.0, 72.0, 56.829),  # Phase 3
	Rect2(240.0, 104.0, 72.0, 56.829),  # Phase 4
	Rect2(320.0, 112.0, 72.0, 56.829)   # Phase 5
]
@onready var sack: Area2D = $Sack
@onready var sack_sprite: Sprite2D = $Sack/Sprite2D
@onready var fish_particles: GPUParticles2D = $FishParticles


func _ready() -> void:
	add_to_group("camera_targets")
	sack.input_event.connect(_on_area_input_event)
	sack.input_pickable = true

	sack_sprite.region_enabled = true
	update_sack_sprite()

	var timer = get_tree().create_timer(Duration)
	timer.timeout.connect(_on_duration_expired)
	start_tilting_loop(self)


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
		hit_sack()


func hit_sack() -> void:
	if is_popping:
		return

	click_count += 1
	print("Sack clicked: ", click_count)

	play_fish_effect()
	play_hit_animation()

	if click_count >= REQUIRED_CLICKS:
		pop_out()
		return

	update_sack_sprite()

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
	
func update_sack_sprite() -> void:
	var region_index: int = 0

	if click_count >= 9:
		region_index = 4
	elif click_count >= 7:
		region_index = 3
	elif click_count >= 5:
		region_index = 2
	elif click_count >= 3:
		region_index = 1

	region_index = clamp(region_index, 0, sack_regions.size() - 1)
	sack_sprite.region_rect = sack_regions[region_index]


func transform_to_polaroid() -> void:
	if is_popping or is_transforming:
		return

	is_transforming = true
	is_popping = true
	sack.input_pickable = false

	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()

	var polaroid := polaroid_scene.instantiate() as Node2D
	get_parent().add_child(polaroid)

	polaroid.global_position = global_position
	polaroid.global_rotation = global_rotation
	polaroid.scale = scale

	var photo_sprite := polaroid.get_node_or_null(
		"Polaroid/Sprite2D"
	) as Sprite2D

	if photo_sprite != null and polaroid_texture != null:
		photo_sprite.texture = polaroid_texture

	if ItemManager.has_method("register_spawned_object"):
		ItemManager.register_spawned_object(polaroid)

	if polaroid.has_method("appear"):
		polaroid.appear()

	popped_out.emit(self)
	queue_free()
func play_fish_effect() -> void:
	fish_particles.restart()
	fish_particles.emitting = true


func play_hit_animation() -> void:
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()

	hit_tween = create_tween()
	hit_tween.set_trans(Tween.TRANS_QUAD)
	hit_tween.set_ease(Tween.EASE_OUT)

	hit_tween.tween_property(
		self,
		"scale",
		Vector2(0.9, 1.1),
		0.05
	)

	hit_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.08
	)


func _on_duration_expired() -> void:
	if is_popping:
		return

	pop_out()


func pop_out() -> void:
	if is_popping:
		return

	is_popping = true
	sack.input_pickable = false

	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()

	popped_out.emit(self)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
