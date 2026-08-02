extends Node2D
signal popped_in
signal popped_up
signal sardine_clicked
signal popped_out

@export var lifetime: float = 6.0
@export var spacing: float = 80.0  

var is_finished: bool = false
@onready var sardine_area: Area2D = $Sardine

func _ready() -> void:
	visible = false
	scale = Vector2.ZERO
	if sardine_area:
		sardine_area.input_pickable = false
		sardine_area.input_event.connect(_on_input_event)

	var life_timer = get_tree().create_timer(lifetime, true)
	life_timer.timeout.connect(_on_lifetime_expired)

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if sardine_area.input_pickable:
			sardine_area.input_pickable = false
			sardine_clicked.emit()

func pop_up(target_offset: Vector2, delay: float = 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, true).timeout
	visible = true
	position = Vector2.ZERO
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_offset, 0.6)     
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.1)
	tween.chain().tween_callback(func():
		if sardine_area:
			sardine_area.input_pickable = true
		popped_up.emit()
	)

func click_bounce() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)

func pop_into_can(target_position: Vector2) -> void:
	if sardine_area:
		sardine_area.input_pickable = false
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.12)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.1)
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_position, 0.25)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.5)
	tween.chain().tween_callback(func():
		popped_in.emit()
		queue_free())

func pop_out() -> void:
	if is_finished:
		return
	is_finished = true
	if sardine_area:
		sardine_area.input_pickable = false
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y + 40, 0.25)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(func():
		popped_out.emit()
		queue_free())

func _on_lifetime_expired() -> void:
	if is_finished:
		return
	pop_out()


static func get_fan_offsets(count: int, spacing_x: float = 55.0, spacing_y: float = 18.0) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	if count <= 0:
		return offsets
	if count == 1:
		offsets.append(Vector2.ZERO)
		return offsets

	var mid = (count - 1) / 2.0
	for i in count:
		var step = i - mid  
		var x = step * spacing_x
		# alternate vertical offset so they don't sit in a flat line
		var y = -abs(step) * spacing_y
		offsets.append(Vector2(x, y))
	return offsets
