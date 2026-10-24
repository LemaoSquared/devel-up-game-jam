extends Node2D
signal popped_out(obj: Node, was_clicked: bool)

# POLAROID
@export var polaroid_scene: PackedScene = preload("res://Menus/item_polaroid.tscn")
@export var polaroid_texture: Texture2D
@export var lifetime: float = 6.0

@export_group("Spawn Settings")
@export var spawn_delay_min: float = 0.01
@export var spawn_delay_max: float = 0.5
@export var offscreen_x_offset: float = 200.0
@export var min_y_offset: float = -140.0
@export var max_y_offset: float = 0.0

var speed: float = 0.0
var is_active: bool = false
var is_finished: bool = false
var direction: int = 1   # 1 = Left-to-Right, -1 = Right-to-Left
var end_x: float = 0.0
var shake_tween: Tween = null

@onready var area: Area2D = $toy_mouse
@onready var animated_sprite: AnimatedSprite2D = $toy_mouse/Sprite2D
@onready var anim_shadow: AnimatedSprite2D = $toy_mouse/Sprite2D2

const MOUSE = preload("uid://dhpdocurfpk5e")
const CLICK_PARTICLE = preload("uid://d3v5eteyxeame")
const GIFT = preload("uid://fojbgtm48t6b")
@onready var gift: AnimatedSprite2D = $GiftAnimation

func _ready() -> void:
	add_to_group("camera_targets")
	
	animated_sprite.sprite_frames.set_animation_loop("rat_toy", true)
	animated_sprite.play("rat_toy")
	
	if anim_shadow:
		if anim_shadow.sprite_frames and anim_shadow.sprite_frames.has_animation("rat_toy"):
			anim_shadow.sprite_frames.set_animation_loop("rat_toy", true)
		anim_shadow.play("rat_toy")

	area.input_pickable = false
	scale = Vector2.ZERO # Start invisible/scaled down for the spawn delay pop-in
	
	# Apply randomized vertical Y offset
	position.y += randf_range(min_y_offset, max_y_offset)

# Called directly by ItemManager after initialization
func set_direction(dir: int, _target_end_x: float) -> void:
	direction = dir
	
	var viewport_width = get_viewport_rect().size.x
	var start_x: float

	if direction > 0:
		start_x = -offscreen_x_offset
		end_x = viewport_width + offscreen_x_offset
	else:
		start_x = viewport_width + offscreen_x_offset
		end_x = -offscreen_x_offset

	global_position.x = start_x

	# Calculate speed required to traverse from start_x to end_x over the active lifetime
	var total_distance = abs(end_x - start_x)
	speed = total_distance / max(lifetime, 0.1)

	var is_flipped = direction < 0
	animated_sprite.flip_h = is_flipped
	if anim_shadow:
		anim_shadow.flip_h = is_flipped

	# --- SPAWN DELAY & POP-IN LOGIC ---
	var spawn_delay = randf_range(spawn_delay_min, spawn_delay_max)
	var delay_timer = get_tree().create_timer(spawn_delay, false)
	delay_timer.timeout.connect(_on_spawn_delay_finished)

func _on_spawn_delay_finished() -> void:
	if is_finished:
		return
		
	# Smooth scale pop-in when delay finishes
	var pop_tween = create_tween()
	pop_tween.set_trans(Tween.TRANS_BACK)
	pop_tween.set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(self, "scale", Vector2.ONE, 0.25)
	
	pop_tween.finished.connect(func():
		is_active = true
		area.input_pickable = true
		
		# Start constant shaky effect and lifetime countdown once active
		_start_shake_tween()
		var life_timer = get_tree().create_timer(lifetime, false)
		life_timer.timeout.connect(_on_lifetime_expired)
	)

# --- CONSTANT SHAKY EFFECT USING TWEEN ---
func _start_shake_tween() -> void:
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
		
	shake_tween = create_tween()
	shake_tween.set_loops() # Infinite looping shake
	shake_tween.set_parallel(false)
	
	# Rapid jittering offsets applied locally to the animated sprite for a twitchy toy feel
	shake_tween.tween_property(animated_sprite, "position", Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5)), 0.04)
	shake_tween.tween_property(animated_sprite, "position", Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5)), 0.04)
	shake_tween.tween_property(animated_sprite, "position", Vector2.ZERO, 0.04)

func _process(delta: float) -> void:
	if not is_active or is_finished:
		return
		
	position.x += speed * direction * delta
	
	if direction > 0 and position.x >= end_x:
		_reach_end()
	elif direction < 0 and position.x <= end_x:
		_reach_end()

# --- 1-Click Fragile Input Handling ---
func _input(event: InputEvent) -> void:
	if not is_active or is_finished:
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
			_on_clicked()

func _on_clicked() -> void:
	if is_finished:
		return
	is_finished = true
	is_active = false
	area.input_pickable = false
	
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
	
	AudioManager.play_sound(MOUSE)
	ParticleManager.spawn_particle(CLICK_PARTICLE, global_position)
	
	AudioManager.play_sound(GIFT)
	gift.visible = true
	gift.play("default")
	await gift.animation_finished
	_pop_and_disappear()

func _pop_and_disappear() -> void:
	is_finished = true
	is_active = false
	area.input_pickable = false
	
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
		
	animated_sprite.stop()
	if anim_shadow:
		anim_shadow.stop()
		
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(self, "scale", Vector2(0, 0), 0.15)
	tween.finished.connect(func():
		popped_out.emit(self, true)
		queue_free()
	)

func _reach_end() -> void:
	is_finished = true
	is_active = false
	area.input_pickable = false
	
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
		
	animated_sprite.stop()
	if anim_shadow:
		anim_shadow.stop()
		
	popped_out.emit(self, false)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.finished.connect(queue_free)
	
func _on_lifetime_expired() -> void:
	if is_finished:
		return
	is_finished = true
	is_active = false
	area.input_pickable = false
	
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
		
	animated_sprite.stop()
	if anim_shadow:
		anim_shadow.stop()
		
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.finished.connect(func():
		popped_out.emit(self, false)
		queue_free())

func transform_to_polaroid() -> void:
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
