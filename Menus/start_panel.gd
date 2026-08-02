extends TextureRect

signal game_started
const SHOP_BELL = preload("uid://fswaj7rxfula")
const OBJECT_SCENE = preload("res://Menus/item_cat_treat.tscn")
const START_SOUND = preload("uid://bnvtg6wxrfprs")

@onready var entity: AnimatedSprite2D = $"../Entity"
@onready var background_manager: Node2D = $"../BackgroundManager"

@export var spawn_area: Control

var is_transitioning: bool = false
var hover_tween: Tween 

func _ready() -> void:
	$Start.pivot_offset = $Start.size / 2.0
	$Start.mouse_entered.connect(_on_start_hovered)
	$Start.mouse_exited.connect(_on_start_unhovered)
	
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
		
	var bounce_tween = create_tween()
	bounce_tween.tween_property($Start, "position:y", $Start.position.y - 20.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property($Start, "position:y", $Start.position.y, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	AudioManager.play_sound(SHOP_BELL)
	$Start.disabled = true
	game_started.emit()
	await get_tree().create_timer(0.4).timeout
	AudioManager.play_music(START_SOUND)
	ItemManager.area = spawn_area
	ItemManager.play_pattern(1)
	
	var obj = OBJECT_SCENE.instantiate()
	get_tree().current_scene.add_child(obj)
	obj.global_position = $Start.global_position
	
	var obj_tween = create_tween()
	obj_tween.set_trans(Tween.TRANS_CUBIC)
	obj_tween.set_ease(Tween.EASE_OUT)
	obj_tween.tween_callback(obj.queue_free)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)
