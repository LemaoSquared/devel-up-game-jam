extends Node2D

signal popped_out(obj: Node)

var is_gravity: bool = false
var is_popping: bool = false

const Duration: float = 15.0
const REQUIRED_CLICKS: int = 10

var click_count: int = 0
var hit_tween: Tween

@export var sack_regions: Array[Rect2] = [
	Rect2(20, 37, 68, 57),  # Phase 1
	Rect2(87, 37, 68, 57),  # Phase 2
	Rect2(155, 37, 68, 57),  # Phase 3
	Rect2(222, 37, 68, 57),  # Phase 4
	Rect2(19, 37, 68, 57)   # Phase 5
]
@onready var sack: Area2D = $Sack
@onready var sack_sprite: Sprite2D = $Sack/Sprite2D
@onready var fish_particles: GPUParticles2D = $FishParticles


func _ready() -> void:
	sack.input_event.connect(_on_area_input_event)
	sack.input_pickable = true

	sack_sprite.region_enabled = true
	update_sack_sprite()

	var timer = get_tree().create_timer(Duration)
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
	print(
	"Click: ", click_count,
	" | Phase: ", region_index + 1,
	" | Region: ", sack_regions[region_index]
	)
	sack_sprite.region_rect = sack_regions[region_index]


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
