extends Node2D



signal popped_out(obj: Node)
@onready var treat: Area2D = $treat


#POLAROID
@export var polaroid_texture: Texture2D
@export var polaroid_scene: PackedScene = preload(
	"res://Menus/item_polaroid.tscn"
)

var is_transforming: bool = false
var is_gravity: bool = false
var is_popping: bool = false
const Duration: float = 6.0

func _ready() -> void:
	add_to_group("camera_targets")
	treat.input_event.connect(_on_area_input_event)
	treat.input_pickable = true

	var timer = get_tree().create_timer(Duration)
	timer.timeout.connect(_on_duration_expired)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_popping:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pop_out()

func _on_duration_expired() -> void:
	if is_popping:
		return  
	pop_out()




func pop_out() -> void:
	is_popping = true
	popped_out.emit(self)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)


#Key to transforming
func transform_to_polaroid() -> void:
	if is_popping or is_transforming:
		return

	is_transforming = true
	is_popping = true
	treat.input_pickable = false

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

	
