extends Node2D

@onready var red_shoes_rect: TextureRect = $CameraEffects/RedShoesRect
signal popped_out(obj: Node, was_clicked: bool)

const RED_SHOES = preload("uid://tf58kq3fxh2b")
const SACK_PARTICLE = preload("uid://bncb0rx7oecq0")
const FLOATING_LABEL = preload("uid://cu8xcr7igstbj")

@export var polaroid_scene: PackedScene = preload("res://Menus/item_polaroid.tscn")
@export var polaroid_texture: Texture2D

@export_group("Endless Mode Red Shoes Settings")
@export var total_lifetime: float = 3.0          # Quick reflex window
@export var reward_points: int = 250
@export var hang_length: float = 650.0           # Balanced string length to keep arc on screen
@export var pivot_height_offset: float = -200.0  # Higher top-center pivot position off-screen
@export var extra_offscreen_buffer: float = 120.0 # Extra horizontal distance beyond screen edges

@onready var string: ColorRect = $Shoes/String

var is_popping: bool = false
var elapsed_time: float = 0.0
var spawn_side: int = -1                         # -1 = Start Left, 1 = Start Right
var current_angle: float = 0.0
var anchor_position: Vector2 = Vector2.ZERO

var start_angle_rad: float = 0.0
var target_angle_rad: float = 0.0


func _ready() -> void:
	add_to_group("camera_targets")
	$Shoes.input_pickable = false
	
	# Randomly choose which side it starts on (-1 = Left, 1 = Right)
	spawn_side = -1 if randf() > 0.5 else 1
	var viewport_size = get_viewport_rect().size
	
	# --- HIGHER TOP-CENTER PIVOT ANCHOR ---
	anchor_position = Vector2(viewport_size.x * 0.5, pivot_height_offset)
	
	# Calculate exact angles to sweep cleanly across the screen width from the higher pivot
	var left_bound = -extra_offscreen_buffer
	var right_bound = viewport_size.x + extra_offscreen_buffer
	
	var angle_left = asin(clamp((left_bound - anchor_position.x) / hang_length, -1.0, 1.0))
	var angle_right = asin(clamp((right_bound - anchor_position.x) / hang_length, -1.0, 1.0))
	
	if spawn_side == -1:
		start_angle_rad = angle_left
		target_angle_rad = angle_right
	else:
		start_angle_rad = angle_right
		target_angle_rad = angle_left
		
	current_angle = start_angle_rad
	update_position_from_angle(current_angle)


func _process(delta: float) -> void:
	if is_popping:
		return
		
	elapsed_time += delta
	var lifetime_ratio = elapsed_time / total_lifetime
	
	if lifetime_ratio < (1.0 / 3.0):
		# --- PHASE 1: Gentle idle sway on its starting side (First 1/3 prep time) ---
		var idle_sway = deg_to_rad(3.0) * sin(elapsed_time * 4.0)
		current_angle = start_angle_rad + idle_sway
	else:
		# --- PHASE 2: Swift pendulum swing across the whole screen (Final 2/3 swing time) ---
		var phase_progress = (lifetime_ratio - (1.0 / 3.0)) / (2.0 / 3.0) # 0.0 to 1.0 over last 2/3
		
		# Smoothly whip across the entire screen from one side to the other
		current_angle = lerp(start_angle_rad, target_angle_rad, ease(phase_progress, -2.5))
		
	update_position_from_angle(current_angle)
	
	# Despawn when lifetime finishes
	if elapsed_time >= total_lifetime:
		despawn_offscreen()


func update_position_from_angle(angle: float) -> void:
	global_position = anchor_position + Vector2(sin(angle), cos(angle)) * hang_length
	rotation = angle * 0.8


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
	if is_popping:
		return
		
	is_popping = true
	AudioManager.play_sound(RED_SHOES)
	ParticleManager.spawn_particle(SACK_PARTICLE, global_position)
	
	# --- CINEMATIC POLISH EFFECT (MIRRORS GLOVE HAZARD BLOCK) ---
	if CameraManager and CameraManager.has_method("add_trauma"):
		CameraManager.add_trauma(0.6)
		
	# 1. Hitstop/Time Freeze
	Engine.time_scale = 0.0
	var hitstop_timer = get_tree().create_timer(0.25, true, true, true)
	hitstop_timer.timeout.connect(func():
		if is_inside_tree():
			Engine.time_scale = 1.0
	)
	
	# 2. BGM Temporary Mute
	var was_bgm_muted = AudioManager.is_bgm_muted
	AudioManager.set_music_muted(true)
	
	var music_timer = get_tree().create_timer(0.25, true, true, true)
	music_timer.timeout.connect(func():
		if is_inside_tree():
			AudioManager.set_music_muted(was_bgm_muted)
	)
	
	# 3. Camera Effects (Red Shoes Vignette + White Flash)
	var camera_effects := get_tree().get_first_node_in_group("camera_effects")
	if camera_effects != null:
		# Red Shoes Vignette Flash
		var target_vignette = red_shoes_rect if red_shoes_rect else camera_effects.get_node_or_null("RedShoesRect")
		if target_vignette is TextureRect or target_vignette is ColorRect:
			target_vignette.visible = true
			target_vignette.modulate.a = 1.0
			var vig_tween = create_tween()
			vig_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
			vig_tween.tween_property(target_vignette, "modulate:a", 0.0, 0.25).set_delay(0.05)
			vig_tween.tween_callback(func(): target_vignette.visible = false)
			
		# White Screen Flash
		var white_flash = camera_effects.get_node_or_null("WhiteFlash")
		if white_flash is ColorRect or white_flash is TextureRect:
			white_flash.visible = true
			white_flash.modulate.a = 1.0
			var flash_tween = create_tween()
			flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
			flash_tween.tween_property(white_flash, "modulate:a", 0.0, 0.3)
			flash_tween.tween_callback(func(): white_flash.visible = false)
			
	# 4. Award Points & Spawn Floating Text Label
	ScoreManager.add_points(reward_points)
	if FLOATING_LABEL:
		var label = FLOATING_LABEL.instantiate()
		get_tree().current_scene.add_child(label)
		
		if label.has_method("setup_text"):
			label.setup_text("RED SHOES\n+250", Color.RED, global_position)
		elif label.has_method("setup"):
			label.setup(reward_points, global_position)
			label.scale = Vector2(1.5, 1.5)
			
	pop_out(true)


func pop_out(was_clicked: bool = false) -> void:
	if string:
		string.visible = false
	popped_out.emit(self, was_clicked)

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)


func despawn_offscreen() -> void:
	if is_popping:
		return
	is_popping = true
	popped_out.emit(self, false)
	queue_free()


func transform_to_polaroid() -> void:
	if is_popping:
		return
		
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


# --- STUBS FOR COMPATIBILITY ---
func start_drag() -> void:
	pass

func end_drag(_tween_back: bool = true, _duration: float = 0.3) -> void:
	pass

func update_anchor_position(_new_global_pos: Vector2) -> void:
	pass
