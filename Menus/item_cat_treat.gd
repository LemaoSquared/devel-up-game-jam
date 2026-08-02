extends Node2D

signal popped_out(obj: Node)

var is_gravity: bool = false
var is_popping: bool = false
const Duration: float = 6.0

@onready var gift: AnimatedSprite2D = $GiftAnimation

func _ready() -> void:
	$Yarn.input_event.connect(_on_area_input_event)
	$Yarn.input_pickable = true
	gift.visible = false
	var timer = get_tree().create_timer(Duration)
	timer.timeout.connect(_on_duration_expired)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_popping:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		gift.visible = true
		gift.play("default")
		await gift.animation_finished
		pop_out()

func _on_duration_expired() -> void:
	if is_popping:
		return  
	pop_out()

func pop_out() -> void:
	is_popping = true
	popped_out.emit(self)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)


	
