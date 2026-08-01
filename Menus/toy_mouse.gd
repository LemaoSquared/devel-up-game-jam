extends Node2D

signal popped_out(obj)

@onready var click_area: Area2D = $Toy_Mouse
@onready var sprite: Sprite2D = $Toy_Mouse/Sprite2D

@export var jump_height: float = 40.0
@export var jump_duration: float = 0.3

var click_count: int = 0
const MAX_CLICKS: int = 2

var run_tween: Tween

func _ready() -> void:
	click_area.input_event.connect(_on_input_event)

func run_in_direction(speed: float, distance: float, direction: int, start_delay: float = 0.0) -> void:
	# direction: 1 = right, -1 = left
	sprite.flip_h = direction < 0
	var duration = distance / speed
	run_tween = create_tween()
	run_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	run_tween.set_trans(Tween.TRANS_LINEAR)
	run_tween.tween_interval(start_delay)
	run_tween.tween_property(self, "global_position:x", global_position.x + (distance * direction), duration)
	run_tween.finished.connect(_on_run_finished)

func _on_run_finished() -> void:
	if click_count < MAX_CLICKS:
		popped_out.emit(self)
		queue_free()

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_clicked()

func _on_clicked() -> void:
	if click_count >= MAX_CLICKS:
		return
	click_count += 1
	_jump()
	if click_count >= MAX_CLICKS:
		var timer = get_tree().create_timer(jump_duration, true)
		await timer.timeout
		if run_tween and run_tween.is_valid():
			run_tween.kill()
		popped_out.emit(self)
		queue_free()

func _jump() -> void:
	var start_y = sprite.position.y
	var jump_tween = create_tween()
	jump_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	jump_tween.set_trans(Tween.TRANS_SINE)
	jump_tween.set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(sprite, "position:y", start_y - jump_height, jump_duration / 2)
	jump_tween.tween_property(sprite, "position:y", start_y, jump_duration / 2)
