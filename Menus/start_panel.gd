extends TextureRect

signal game_started

const OBJECT_SCENE := preload("res://Menus/object.tscn")
const START_SOUND = preload("uid://bnvtg6wxrfprs")

@onready var entity: AnimatedSprite2D = $"../Entity"

@onready var background_manager: Node2D = $"../BackgroundManager"

@export var spawn_area: Control


var is_transitioning: bool = false

func _ready() -> void:
	pass
	
func _on_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	$Start.disabled = true
	game_started.emit()
	
	AudioManager.play_music(START_SOUND)
	ItemManager.spawn_random_pop_in_rect(spawn_area)

	
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
	
	#var entity_tween = create_tween()
	#entity_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	#entity_tween.tween_property(entity,"position:x", get_viewport_rect().size.x / 2, 1)
	
	background_manager.play_movement()
	
