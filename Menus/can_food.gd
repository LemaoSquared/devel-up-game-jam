extends Node2D

signal popped_out(obj)
#POLAROID
@export var polaroid_scene: PackedScene = preload(
	"res://Menus/item_polaroid.tscn"
)
@export var polaroid_texture: Texture2D
@onready var click_area: Area2D = $Can_Food
@onready var anim_sprite: AnimatedSprite2D = $Can_Food/Sprite2D

var click_count: int = 0
const MAX_CLICKS: int = 3

func _ready() -> void:
	add_to_group("camera_targets")
	click_area.input_event.connect(_on_input_event)
	anim_sprite.animation = "Can_Foood"
	anim_sprite.frame = 0
	anim_sprite.stop()  

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_frame()

func _advance_frame() -> void:
	if click_count >= MAX_CLICKS:
		return
	click_count += 1
	anim_sprite.frame = click_count
	_click_feedback()
	if click_count >= MAX_CLICKS:
		_pop_out()

func _click_feedback() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _pop_out() -> void:
	var timer = get_tree().create_timer(0.3, true)
	await timer.timeout
	popped_out.emit(self)
	queue_free()
	
func transform_to_polaroid() -> void:
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
