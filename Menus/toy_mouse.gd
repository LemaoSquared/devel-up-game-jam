extends Node2D
signal popped_out(obj: Node, was_clicked: bool)

# POLAROID
@export var polaroid_scene: PackedScene = preload("res://Menus/item_polaroid.tscn")
@export var polaroid_texture: Texture2D
@export var speed: float = 60.0          
@export var speed_increase: float = 40.0 
@export var jump_distance: float = 40.0  
@export var jump_duration: float = 0.3   
@export var jump_height: float = 20.0    
@export var max_clicks: int = 3          
@export var end_x: float = 1250.0
@export var lifetime: float = 6.0
var is_jumping: bool = false
var is_finished: bool = false
var click_count: int = 0
var direction: int = 1   
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

	# Disabled standard area input pickable in favor of global _input handling
	area.input_pickable = false
	
	var life_timer = get_tree().create_timer(lifetime, true)
	life_timer.timeout.connect(_on_lifetime_expired)

func set_direction(dir: int, target_end_x: float) -> void:
	direction = dir
	end_x = target_end_x
	
	var is_flipped = direction < 0
	animated_sprite.flip_h = is_flipped
	if anim_shadow:
		anim_shadow.flip_h = is_flipped

func _process(delta: float) -> void:
	if is_finished:
		return
	if not is_jumping:
		position.x += speed * direction * delta
	if direction > 0 and position.x >= end_x:
		_reach_end()
	elif direction < 0 and position.x <= end_x:
		_reach_end()

# --- Multi-touch & Mouse Input Handling ---
func _input(event: InputEvent) -> void:
	if is_finished:
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
		if global_position.distance_to(click_pos) < 64.0: # Adjust radius if needed
			_on_clicked()

func _on_clicked() -> void:
	if is_jumping or is_finished:
		return
	AudioManager.play_sound(MOUSE)
	ParticleManager.spawn_particle(CLICK_PARTICLE, global_position)
	click_count += 1
	speed += speed_increase
	if click_count >= max_clicks:
		is_finished = true         
		area.input_pickable = false
		AudioManager.play_sound(GIFT)
		gift.visible = true
		gift.play("default")
		await gift.animation_finished
		_pop_and_disappear()
	else:
		_jump()

func _jump() -> void:
	is_jumping = true
	var target_x = position.x + jump_distance * direction
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", target_x, jump_duration)
	tween.parallel().tween_method(_apply_hop_arc, 0.0, 1.0, jump_duration)
	tween.finished.connect(func(): is_jumping = false)

func _apply_hop_arc(t: float) -> void:
	animated_sprite.position.y = -sin(t * PI) * jump_height

func _pop_and_disappear() -> void:
	is_finished = true
	is_jumping = true
	area.input_pickable = false
	
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
	area.input_pickable = false
	
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
		return   # already popped or reached end — nothing to do
	is_finished = true
	is_jumping = true
	area.input_pickable = false
	
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

	# Guarantee Polaroid Data & Connect Signal
	polaroid.set_meta("item_type", 9)
	polaroid.set("is_polaroid", true)

	if ItemManager.has_method("register_spawned_object"):
		ItemManager.register_spawned_object(polaroid, 9) # 9 is Item.POLAROID

	if polaroid.has_method("appear"):
		polaroid.appear()

	popped_out.emit(self, true)
	queue_free()
