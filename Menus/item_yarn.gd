extends Node2D
signal popped_out(obj: Node)

@export var polaroid_scene: PackedScene = preload(
	"res://Menus/item_polaroid.tscn"
)
@export var polaroid_texture: Texture2D

@export_group("Pop Settings")
@export var pop_duration_seconds: float = 6.0
@export var fall_stagger_max: float = 1.5 

@export_group("Drop & Float Settings")
enum SettleStyle { BOUNCE, SPRING, SWAY }
@export var settle_style: SettleStyle = SettleStyle.BOUNCE
@export var fall_duration: float = 0.5
@export var settle_duration: float = 0.6
@export var idle_sway_enabled: bool = true
@export var idle_sway_amplitude_deg: float = 6.0
@export var idle_sway_speed: float = 1.2

@export_group("Timeout Fall Settings")
@export var fall_away_duration: float = 1.0
@export var fall_away_spin_degrees: float = 90.0
@export var fall_away_screen_buffer: float = 150.0   

var is_popping: bool = false
var is_hanging: bool = false
var hang_length: float = 0.0
var idle_time: float = 0.0
var anchor_position: Vector2 = Vector2.ZERO
@onready var string: ColorRect = $Yarn/String

@onready var gift_front: AnimatedSprite2D = $GiftAnimation

func _ready() -> void:
	add_to_group("camera_targets")
	$Yarn.input_event.connect(_on_area_input_event)
	$Yarn.input_pickable = true

	var timer = get_tree().create_timer(pop_duration_seconds, true)  # pause-aware
	timer.timeout.connect(_on_duration_expired)
	gift_front.visible = false


func _process(delta: float) -> void:
	if is_hanging and idle_sway_enabled and not is_popping:
		idle_time += delta
		var angle = deg_to_rad(idle_sway_amplitude_deg) * sin(idle_time * idle_sway_speed)
		global_position = anchor_position + Vector2(sin(angle), cos(angle)) * hang_length
		rotation = angle * 0.5


func spawn_drop_and_hang(target_global_pos: Vector2, anchor_global_pos: Vector2, delay: float = 0.0) -> void:
	anchor_position = anchor_global_pos
	hang_length = (target_global_pos - anchor_global_pos).length()
	global_position = anchor_global_pos
	scale = Vector2.ONE

	var drop_tween = create_tween()
	drop_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)

	match settle_style:
		SettleStyle.BOUNCE:
			drop_tween.set_trans(Tween.TRANS_BOUNCE)
			drop_tween.set_ease(Tween.EASE_OUT)
		SettleStyle.SPRING:
			drop_tween.set_trans(Tween.TRANS_ELASTIC)
			drop_tween.set_ease(Tween.EASE_OUT)
		SettleStyle.SWAY:
			drop_tween.set_trans(Tween.TRANS_QUAD)
			drop_tween.set_ease(Tween.EASE_OUT)

	var total_duration = fall_duration + settle_duration
	drop_tween.tween_property(self, "global_position", target_global_pos, total_duration).set_delay(delay)
	drop_tween.tween_callback(func(): is_hanging = true)


func _on_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if is_popping:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pop_out()

func _on_duration_expired() -> void:
	if is_popping:
		return
	var stagger = randf_range(0.0, fall_stagger_max)
	var timer = get_tree().create_timer(stagger, true)   # pause-aware
	timer.timeout.connect(func():
		if not is_popping:
			fall_and_disappear()
	)


func pop_out() -> void:
	string.visible = false
	is_popping = true
	is_hanging = false
	popped_out.emit(self)
	
	gift_front.visible = true
	gift_front.play("default")
	await gift_front.animation_finished
	var tween = create_tween()
	
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)

func fall_and_disappear() -> void:
	string.visible = false
	is_popping = true
	is_hanging = false
	popped_out.emit(self)

	var viewport_height = get_viewport_rect().size.y
	var fall_distance = (viewport_height - global_position.y) + fall_away_screen_buffer
	var fall_target = global_position + Vector2(0, fall_distance)

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)  

	tween.tween_property(self, "global_position", fall_target, fall_away_duration)
	tween.tween_property(self, "rotation", rotation + deg_to_rad(fall_away_spin_degrees), fall_away_duration)

	tween.chain().tween_callback(queue_free)
	
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
