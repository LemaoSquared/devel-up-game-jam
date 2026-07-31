extends TextureRect

signal game_started

var is_transitioning: bool = false

func _ready() -> void:
	pass


func _on_start_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	$Start.disabled = true
	game_started.emit()

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)
