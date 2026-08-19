extends Node2D

const TRASH = preload("uid://bnyi53tue8oe2")
const TRASH_PARTICLE = preload("uid://bqldp717ro0a4")
signal popped_out(obj: Node, was_clicked: bool)

var is_gravity: bool = false
var is_popping: bool = false
const Duration: float = 6.0

# POLAROID
@export var polaroid_scene: PackedScene = preload("res://Menus/item_polaroid.tscn")
@export var polaroid_texture: Texture2D

@onready var sprite_2d: AnimatedSprite2D = $Garbage/Sprite2D
@onready var gift: AnimatedSprite2D = $GiftAnimation

func _ready() -> void:
	add_to_group("camera_targets")
	$Garbage.input_event.connect(_on_area_input_event)
	$Garbage.input_pickable = true

	if gift:
		gift.visible = false

	var timer = get_tree().create_timer(Duration, false)
	timer.timeout.connect(_on_duration_expired)
	start_tilting_loop(self)

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

func _on_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if is_popping:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_sound(TRASH)
		ParticleManager.spawn_particle(TRASH_PARTICLE, global_position)
		pop_out(true)

func _on_duration_expired() -> void:
	if is_popping:
		return  
	pop_out(false)

func pop_out(is_clicked: bool = false) -> void:
	if is_popping:
		return
	is_popping = true

	# Disable input so it can't be clicked multiple times while popping out
	$Garbage.input_pickable = false

	# Pass the actual click status instead of hardcoding true!
	popped_out.emit(self, is_clicked)

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)

func transform_to_polaroid() -> void:
	if is_popping:
		return
	is_popping = true
	$Garbage.input_pickable = false

	if popped_out.is_connected(ItemManager._on_object_popped_out):
		popped_out.disconnect(ItemManager._on_object_popped_out)

	ItemManager.spawned_objects.erase(self)
	ItemManager.wave_one_objects.erase(self)

	if polaroid_scene == null:
		polaroid_scene = load("res://Menus/item_polaroid.tscn")

	var polaroid := polaroid_scene.instantiate() as Node2D
	if polaroid == null:
		queue_free()
		return

	get_parent().add_child(polaroid)
	polaroid.global_position = global_position
	polaroid.global_rotation = global_rotation
	polaroid.scale = scale

	var photo_sprite := polaroid.get_node_or_null("Polaroid/Sprite2D") as Sprite2D
	if photo_sprite != null and polaroid_texture != null:
		photo_sprite.texture = polaroid_texture

	if ItemManager.has_method("register_spawned_object"):
		ItemManager.register_spawned_object(polaroid, ItemManager.Item.POLAROID)

	if polaroid.has_method("appear"):
		polaroid.appear()

	queue_free()
