extends TextureRect
const STREET = preload("uid://c6xk46jpedco4")
@onready var tutorial_label: Label = $"../TutorialLabel"

signal game_started
signal endless_started
const SHOP_BELL = preload("uid://fswaj7rxfula")
const OBJECT_SCENE = preload("res://Menus/item_cat_treat.tscn")
const TAPTAP = preload("uid://bnvtg6wxrfprs")
const KATKAT = preload("uid://dy575c21gytdn")

@onready var label: Label = $Label

@onready var entity: AnimatedSprite2D = $"../Entity"
@onready var background_manager: Node2D = $"../BackgroundManager"

@export var spawn_area: Control

var is_transitioning: bool = false
var hover_tween: Tween 
var hover_tween2: Tween

func _ready() -> void:
	$Start.pivot_offset = $Start.size / 2.0
	$Start.mouse_entered.connect(_on_start_hovered)
	$Start.mouse_exited.connect(_on_start_unhovered)
	
	$EndlessStart.pivot_offset = $EndlessStart.size / 2.0
	$EndlessStart.mouse_entered.connect(_on_endless_hovered)
	$EndlessStart.mouse_exited.connect(_on_endless_unhovered)

	# Clean slate setup for the tutorial label
	if tutorial_label:
		tutorial_label.modulate.a = 0.0
		tutorial_label.visible = false

# --- START BUTTON LOGIC ---
func _on_start_hovered() -> void:
	if is_transitioning: 
		return 
		
	if hover_tween:
		hover_tween.kill()
		
	hover_tween = create_tween().set_loops()
	hover_tween.tween_property($Start, "rotation_degrees", 360.0, 1.5).as_relative().set_trans(Tween.TRANS_LINEAR)

func _on_start_unhovered() -> void:
	if is_transitioning:
		return
		
	if hover_tween:
		hover_tween.kill()
		
	$Start.rotation_degrees = wrapf($Start.rotation_degrees, 0.0, 360.0)
	var target_rotation = 360.0 if $Start.rotation_degrees > 180.0 else 0.0
	
	hover_tween = create_tween()
	hover_tween.tween_property($Start, "rotation_degrees", target_rotation, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hover_tween.tween_callback(func(): $Start.rotation_degrees = 0.0)
	
func _on_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	if hover_tween:
		hover_tween.kill()
	if hover_tween2:
		hover_tween2.kill()
		
	# Button press feedback
	var bounce_tween = create_tween()
	bounce_tween.tween_property($Start, "position:y", $Start.position.y - 20.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property($Start, "position:y", $Start.position.y, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	AudioManager.play_sound(SHOP_BELL)
	$Start.disabled = true
	$EndlessStart.disabled = true
	game_started.emit()
	
	await get_tree().create_timer(0.4).timeout
	AudioManager.stop_music()
	AudioManager.play_music(TAPTAP)
	
	ItemManager.area = spawn_area
	ScoreManager.reset_score()
	ItemManager.is_game_over = false
	ItemManager.current_pattern = 1
	ItemManager.play_pattern(1)
	
	
	var obj = OBJECT_SCENE.instantiate()
	get_tree().current_scene.add_child(obj)
	obj.global_position = $Start.global_position
	
	var obj_tween = create_tween()
	obj_tween.set_trans(Tween.TRANS_CUBIC)
	obj_tween.set_ease(Tween.EASE_OUT)
	obj_tween.tween_callback(obj.queue_free)

	_trigger_tutorial_sequence()

	# Fade out and clean up this menu screen layout manager safely
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)

# --- ENDLESS START BUTTON LOGIC ---
func _on_endless_hovered() -> void:
	if is_transitioning: 
		return 
		
	if hover_tween2:
		hover_tween2.kill()
		
	hover_tween2 = create_tween().set_loops()
	hover_tween2.tween_property($EndlessStart, "rotation_degrees", 360.0, 1.5).as_relative().set_trans(Tween.TRANS_LINEAR)

func _on_endless_unhovered() -> void:
	if is_transitioning:
		return
		
	if hover_tween2:
		hover_tween2.kill()
		
	$EndlessStart.rotation_degrees = wrapf($EndlessStart.rotation_degrees, 0.0, 360.0)
	var target_rotation = 360.0 if $EndlessStart.rotation_degrees > 180.0 else 0.0
	
	hover_tween2 = create_tween()
	hover_tween2.tween_property($EndlessStart, "rotation_degrees", target_rotation, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hover_tween2.tween_callback(func(): $EndlessStart.rotation_degrees = 0.0)

func _on_endless_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if hover_tween:
		hover_tween.kill()
	if hover_tween2:
		hover_tween2.kill()
		
	# Added: Missing button press feedback bounce animation
	var bounce_tween = create_tween()
	bounce_tween.tween_property($EndlessStart, "position:y", $EndlessStart.position.y - 20.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property($EndlessStart, "position:y", $EndlessStart.position.y, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	AudioManager.play_sound(SHOP_BELL)
	$Start.disabled = true
	$EndlessStart.disabled = true
	endless_started.emit()

	await get_tree().create_timer(0.4).timeout
	AudioManager.stop_music()
	AudioManager.play_music(KATKAT)

	ItemManager.area = spawn_area
	ScoreManager.reset_score()
	LivesManager.reset_lives()
	ItemManager.start_endless()
	ItemManager.is_game_over = false
	
	# Spawn treat effect at Endless button position
	var obj = OBJECT_SCENE.instantiate()
	get_tree().current_scene.add_child(obj)
	obj.global_position = $EndlessStart.global_position
	
	var obj_tween = create_tween()
	obj_tween.set_trans(Tween.TRANS_CUBIC)
	obj_tween.set_ease(Tween.EASE_OUT)
	obj_tween.tween_callback(obj.queue_free)

	_trigger_tutorial_sequence()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)

# --- HELPER FUNCTIONS ---
func _trigger_tutorial_sequence() -> void:
	if tutorial_label:
		tutorial_label.visible = true
		tutorial_label.pivot_offset = tutorial_label.size / 2.0
		tutorial_label.modulate.a = 0.0
		
		var tilt_angle: float = deg_to_rad(6.0)
		var tilt_duration: float = 0.8
		var tilt_tween = tutorial_label.create_tween().set_loops()
		tilt_tween.set_trans(Tween.TRANS_SINE)
		tilt_tween.set_ease(Tween.EASE_IN_OUT)
		tilt_tween.tween_property(tutorial_label, "rotation", -tilt_angle, tilt_duration)
		tilt_tween.tween_property(tutorial_label, "rotation", tilt_angle, tilt_duration * 2.0)
		tilt_tween.tween_property(tutorial_label, "rotation", -tilt_angle, tilt_duration * 2.0)
		
		var lifecycle_tween = tutorial_label.create_tween()
		lifecycle_tween.set_trans(Tween.TRANS_SINE)
		
		lifecycle_tween.set_ease(Tween.EASE_OUT)
		lifecycle_tween.tween_property(tutorial_label, "modulate:a", 1.0, 0.5)
		
		lifecycle_tween.tween_interval(6.0)
		
		lifecycle_tween.set_ease(Tween.EASE_IN)
		lifecycle_tween.tween_property(tutorial_label, "modulate:a", 0.0, 0.5)
		
		lifecycle_tween.tween_callback(func():
			if is_instance_valid(tilt_tween):
				tilt_tween.kill()
			tutorial_label.visible = false
			tutorial_label.rotation = 0.0
		)
