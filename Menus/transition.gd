extends ColorRect

func transition(duration: float = 1.0) -> void:
	color = Color.WHITE
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, duration)
	await tween.finished

func Return(duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	await tween.finished
	visible = false
	AudioManager.stop_music()
