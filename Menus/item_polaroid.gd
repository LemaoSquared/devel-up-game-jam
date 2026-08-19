extends Node2D

const GIFT = preload("uid://fojbgtm48t6b")
signal popped_out(obj: Node, was_clicked: bool)
const POLAROID_TEXTURE = preload("uid://d1yvy81a81kxm")

# --- Polaroid Sound Effect ---
const POLAROID_SFX = preload("res://SFX/Polaroid.wav")

var is_popping: bool = false
const Duration: float = 8.0 # Standard display time before falling off screen
const CLICK_PARTICLE = preload("uid://d3v5eteyxeame")

@onready var area_2d: Area2D = $Polaroid
@onready var photo_sprite: Sprite2D = $Polaroid/Sprite2D
@onready var gift_front: AnimatedSprite2D = $GiftAnimation

func _ready() -> void:
	add_to_group("polaroid")
	add_to_group("camera_targets")
	
	if area_2d:
		area_2d.input_event.connect(_on_area_input_event)
		area_2d.input_pickable = true
		
	if gift_front:
		gift_front.visible = false
		
	start_tilting_loop(self)

func appear() -> void:
	# Entry animation when camera snaps a photo
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)

func start_tilting_loop(obj: Node2D) -> void:
	var tilt_angle: float = deg_to_rad(6.0) # Sway angle
	var duration: float = 1.0

	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(obj, "rotation", -tilt_angle, duration)
	tween.tween_property(obj, "rotation", tilt_angle, duration * 2.0)
	tween.tween_property(obj, "rotation", 0.0, duration)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_popping:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_popping = true
		if area_2d:
			area_2d.input_pickable = false
			
		AudioManager.play_sound(POLAROID_SFX)
		ParticleManager.spawn_particle(CLICK_PARTICLE, global_position)
		pop_out(true)

func pop_out(is_clicked = false) -> void:
	is_popping = true
	popped_out.emit(self, is_clicked)
	
	# Play gift animation over/on top of the polaroid without hiding it
	if gift_front:
		gift_front.visible = true
		# photo_sprite stays visible here!
		gift_front.play("default")
		await gift_front.animation_finished

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)

func drop_and_free() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position:y", global_position.y + 600.0, 0.4)
	tween.tween_callback(queue_free)
