extends Node2D

signal popped_out(obj)

@onready var click_area: Area2D = $Can_Food
@onready var anim_sprite: AnimatedSprite2D = $Can_Food/Sprite2D

var click_count: int = 0
const MAX_CLICKS: int = 3

func _ready() -> void:
	click_area.input_event.connect(_on_input_event)
	anim_sprite.animation = "Can_Foood"
	anim_sprite.frame = 0
	anim_sprite.stop()  

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_frame()

func _advance_frame() -> void:
	if click_count >= MAX_CLICKS:
		return
	click_count += 1
	anim_sprite.frame = click_count
	_click_feedback()
	if click_count >= MAX_CLICKS:
		_pop_out()

func _click_feedback() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _pop_out() -> void:
	var timer = get_tree().create_timer(0.3, true)
	await timer.timeout
	popped_out.emit(self)
	queue_free()
