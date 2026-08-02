extends Node2D

signal popped_out(obj: Node)

@export var speed: float = 60.0         
@export var speed_increase: float = 40.0 
@export var jump_distance: float = 40.0  
@export var jump_duration: float = 0.3   
@export var jump_height: float = 20.0   
@export var max_clicks: int = 3         
@export var end_x: float = 1220.0       

var is_jumping: bool = false
var is_finished: bool = false
var click_count: int = 0

@onready var area: Area2D = $toy_mouse
@onready var animated_sprite: AnimatedSprite2D = $toy_mouse/Sprite2D

func _ready() -> void:
	animated_sprite.sprite_frames.set_animation_loop("rat_toy", true)
	animated_sprite.play("rat_toy")
	area.input_pickable = true
	area.input_event.connect(_on_area_input_event)

func _process(delta: float) -> void:
	if is_finished:
		return

	if not is_jumping:
		position.x += speed * delta

	if position.x >= end_x:
		_reach_end()

func _on_area_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_clicked()

func _on_clicked() -> void:
	if is_jumping or is_finished:
		return

	click_count += 1
	speed += speed_increase  # speed up each click

	if click_count >= max_clicks:
		_pop_and_disappear()
	else:
		_jump()

func _jump() -> void:
	is_jumping = true

	var target_x = position.x + jump_distance
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
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(self, "scale", Vector2(0, 0), 0.15)
	tween.finished.connect(func():
		popped_out.emit(self)
		queue_free()
	)

func _reach_end() -> void:
	is_finished = true
	area.input_pickable = false
	animated_sprite.stop()  
	popped_out.emit(self) 
