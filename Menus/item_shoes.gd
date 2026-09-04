extends Node2D
signal popped_out(obj: Node, was_clicked: bool)

const TRASH = preload("uid://bnyi53tue8oe2")
const TRASH_PARTICLE = preload("uid://bqldp717ro0a4")

@export var polaroid_scene: PackedScene = preload("res://Menus/item_polaroid.tscn")
@export var polaroid_texture: Texture2D

@export_group("Pop Settings")
@export var pop_duration_seconds: float = 6.0
@export var fall_stagger_max: float = 1.5 
@onready var string: ColorRect = $Shoes/String

@export_group("Drop & Float Settings")
enum SettleStyle { BOUNCE, SPRING, SWAY }
@export var settle_style: SettleStyle = SettleStyle.BOUNCE
@export var fall_duration: float = 0.5
@export var settle_duration: float = 0.6
@export var idle_sway_enabled: bool = true
@export var idle_sway_amplitude_deg: float = 6.0
@export var idle_sway_speed: float = 1.2
@export var spawn_offset_y: float = -150.0 # Offset to raise the initial spawn position higher off-screen

@export_group("Timeout Fall Settings")
@export var fall_away_duration: float = 1.0
@export var fall_away_spin_degrees: float = 90.0
@export var fall_away_screen_buffer: float = 150.0   

var is_popping: bool = false
var is_hanging: bool = false
var is_dragged: bool = false
var hang_length: float = 0.0
var idle_time: float = 0.0
var anchor_position: Vector2 = Vector2.ZERO

var active_drop_tween: Tween

func _ready() -> void:
	add_to_group("camera_targets")
	$Shoes.input_pickable = false

	var timer = get_tree().create_timer(pop_duration_seconds, false)
	timer.timeout.connect(_on_duration_expired)

func _process(delta: float) -> void:
	if is_hanging and idle_sway_enabled and not is_popping and not is_dragged:
		idle_time += delta
		var angle = deg_to_rad(idle_sway_amplitude_deg) * sin(idle_time * idle_sway_speed)
		global_position = anchor_position + Vector2(sin(angle), cos(angle)) * hang_length
		rotation = angle * 0.8

func spawn_drop_and_hang(target_global_pos: Vector2, anchor_global_pos: Vector2, delay: float = 0.0) -> void:
	anchor_position = anchor_global_pos
	hang_length = (target_global_pos - anchor_global_pos).length()
	
	# Start higher off-screen using spawn_offset_y to prevent initial bleeding onto screen
	global_position = anchor_global_pos + Vector2(0, spawn_offset_y)
	scale = Vector2.ONE

	active_drop_tween = create_tween()
	active_drop_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)

	match settle_style:
		SettleStyle.BOUNCE:
			active_drop_tween.set_trans(Tween.TRANS_BOUNCE)
			active_drop_tween.set_ease(Tween.EASE_OUT)
		SettleStyle.SPRING:
			active_drop_tween.set_trans(Tween.TRANS_ELASTIC)
			active_drop_tween.set_ease(Tween.EASE_OUT)
		SettleStyle.SWAY:
			active_drop_tween.set_trans(Tween.TRANS_QUAD)
			active_drop_tween.set_ease(Tween.EASE_OUT)

	var total_duration = fall_duration + settle_duration
	active_drop_tween.tween_property(self, "global_position", target_global_pos, total_duration).set_delay(delay)
	active_drop_tween.tween_callback(func(): is_hanging = true)

func _input(event: InputEvent) -> void:
	if is_popping:
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
	AudioManager.play_sound(TRASH)
	ParticleManager.spawn_particle(TRASH_PARTICLE, global_position)
	pop_out(true)

func _on_duration_expired() -> void:
	if is_popping:
		return
	var stagger = randf_range(0.0, fall_stagger_max)
	var timer = get_tree().create_timer(stagger, false)
	timer.timeout.connect(func():
		if not is_popping:
			fall_and_disappear()
	)

func pop_out(_is_clicked: bool = false) -> void:
	if is_popping:
		return
		
	if active_drop_tween and active_drop_tween.is_valid():
		active_drop_tween.kill()
		
	string.visible = false
	is_popping = true
	is_hanging = false
	popped_out.emit(self, true)

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)

func fall_and_disappear() -> void:
	if is_popping:
		return
		
	if active_drop_tween and active_drop_tween.is_valid():
		active_drop_tween.kill()
		
	string.visible = false
	is_popping = true
	is_hanging = false
	popped_out.emit(self, false)

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

func despawn() -> void:
	if is_popping:
		return
		
	if active_drop_tween and active_drop_tween.is_valid():
		active_drop_tween.kill()
		
	string.visible = false
	is_popping = true
	is_hanging = false

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
	if active_drop_tween and active_drop_tween.is_valid():
		active_drop_tween.kill()
		
	var polaroid := polaroid_scene.instantiate() as Node2D
	get_parent().add_child(polaroid)

	polaroid.global_position = global_position
	polaroid.global_rotation = global_rotation
	polaroid.scale = scale

	var photo_sprite := polaroid.get_node_or_null("Polaroid/Sprite2D") as Sprite2D
	if photo_sprite != null and polaroid_texture != null:
		photo_sprite.texture = polaroid_texture

	polaroid.set_meta("item_type", 9)
	polaroid.set("is_polaroid", true)

	if ItemManager.has_method("register_spawned_object"):
		ItemManager.register_spawned_object(polaroid, 9) 

	if polaroid.has_method("appear"):
		polaroid.appear()

	popped_out.emit(self, true)
	queue_free()

# --- PAW DRAG LOGIC ---
func start_drag() -> void:
	is_dragged = true
	if active_drop_tween and active_drop_tween.is_valid():
		active_drop_tween.kill()

func end_drag(tween_back_automatically: bool = true, duration: float = 0.3) -> void:
	if not tween_back_automatically:
		is_dragged = false
		return
		
	var resting_pos = anchor_position + Vector2(0, hang_length)
	
	var return_tween = create_tween()
	return_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	return_tween.set_parallel(true)
	return_tween.tween_property(self, "global_position", resting_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return_tween.tween_property(self, "rotation", 0.0, duration)
	
	return_tween.chain().tween_callback(func(): is_dragged = false)

func update_anchor_position(new_global_pos: Vector2) -> void:
	anchor_position = new_global_pos
	hang_length = 0.0
	is_dragged = false
