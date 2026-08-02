extends Node2D

signal popped_out(obj)
#POLAROID
@export var polaroid_scene: PackedScene = preload(
	"res://Menus/item_polaroid.tscn"
)
@export var polaroid_texture: Texture2D
@onready var click_area: Area2D = $Can_Food
@onready var anim_sprite: AnimatedSprite2D = $Can_Food/Sprite2D
@onready var sardine_template: Node2D = $Sardine
var click_count: int = 0
const MAX_CLICKS: int = 4

@onready var gift: AnimatedSprite2D = $GiftAnimation

@export var lifetime: float = 12.0
var is_finished: bool = false
var sardines_remaining: int = 0

var sardine_offsets: Array[Vector2] = [
	Vector2(-30, -20),
	Vector2(0, -35),
	Vector2(30, -20),
]

func _ready() -> void:
	gift.visible = false
	add_to_group("camera_targets")
	click_area.input_event.connect(_on_input_event)
	anim_sprite.animation = "Can_Foood"
	anim_sprite.frame = 0
	anim_sprite.stop()

	var life_timer = get_tree().create_timer(lifetime, true)
	life_timer.timeout.connect(_on_lifetime_expired)

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_frame()

func _advance_frame() -> void:
	if is_finished or click_count >= MAX_CLICKS:
		return
	click_count += 1
	anim_sprite.frame = click_count
	_click_feedback()

	if click_count >= MAX_CLICKS:
		_spawn_sardines()

func _click_feedback() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _spawn_sardines() -> void:
	is_finished = true
	click_area.input_pickable = false
	var count = 3
	sardines_remaining = count
	for i in range(count):
		var s = sardine_template.duplicate()
		s.sardine_index = i
		s.total_sardines = count
		s.spawn_delay = i * 0.3
		add_child(s)   
		s.sardine_clicked.connect(_on_sardine_clicked.bind(s))
		s.popped_in.connect(_on_sardine_popped_in)

func _on_sardine_clicked(s: Node2D) -> void:
	if is_instance_valid(s):
		s.pop_into_can(anim_sprite.global_position)

func _on_sardine_popped_in() -> void:
	sardines_remaining -= 1
	if sardines_remaining <= 0:
		_pop_out()

func _pop_out() -> void:
	gift.visible = true
	gift.play("default")
	await gift.animation_finished
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

func _on_lifetime_expired() -> void:
	if is_finished and sardines_remaining <= 0:
		return
	is_finished = true
	click_area.input_pickable = false

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.finished.connect(func():
		popped_out.emit(self)
		queue_free())
		
