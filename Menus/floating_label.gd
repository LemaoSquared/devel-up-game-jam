extends Label

# Handles numerical score popups with dynamic scaling and color coding
func setup(amount: int, spawn_position: Vector2) -> void:
	global_position = spawn_position
	text = "+" + str(amount) if amount > 0 else str(amount)
	
	# Color and magnitude based on score value
	var magnitude = 1.2
	if amount < 0:
		modulate = Color.FIREBRICK
		magnitude = 1.4
	elif amount >= 15:
		modulate = Color.GOLD
		magnitude = 1.8
	elif amount >= 25:
		modulate = Color.ORANGE_RED
		magnitude = 1.5
	else:
		modulate = Color.WHITE
		magnitude = 1.2

	scale = Vector2.ZERO
	pivot_offset = size / 2

	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "scale", Vector2.ONE * magnitude, 0.15) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "global_position:y", global_position.y - 60.0, 0.6) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(0.25)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	fade_tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.35) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)
	
	fade_tween.tween_callback(queue_free)

# Handles text-based popups (e.g., "REGEN", "CAMERA")
func setup_text(custom_text: String, custom_color: Color, spawn_position: Vector2) -> void:
	global_position = spawn_position
	text = custom_text
	modulate = custom_color

	var magnitude = 1.5
	scale = Vector2.ZERO
	pivot_offset = size / 2

	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "scale", Vector2.ONE * magnitude, 0.15) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "global_position:y", global_position.y - 60.0, 0.6) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(0.25)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	fade_tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.35) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)
	
	fade_tween.tween_callback(queue_free)
