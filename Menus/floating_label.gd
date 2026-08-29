extends Label

# Handles numerical score popups with dynamic scaling and color coding
func setup(amount: int, spawn_position: Vector2, multiplier: int = 1) -> void:
	global_position = spawn_position
	
	var base_text = "+" + str(amount) if amount > 0 else str(amount)
	
	# Add the multiplier text if active (e.g. "+40 (x2)")
	if multiplier > 1 and amount > 0:
		text = base_text + " (x" + str(multiplier) + ")"
	else:
		text = base_text
	
	# Color and magnitude based on score value & multiplier
	var magnitude = 1.2
	if amount < 0:
		modulate = Color.FIREBRICK
		magnitude = 1.4
	elif multiplier == 3 and amount > 0:
		modulate = Color.ALICE_BLUE # Unique color for Taptap Streak
		magnitude = 1.9
	elif multiplier == 2 and amount > 0:
		modulate = Color.PALE_GOLDENROD # Unique color for Tap Streak
		magnitude = 1.7
	elif amount >= 25:
		modulate = Color.ORANGE_RED
		magnitude = 1.5
	elif amount >= 15:
		modulate = Color.GOLD
		magnitude = 1.8
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

# Handles text-based popups (e.g., "REGEN", "CAMERA", "GLOVE!", "BLOCKED!")
func setup_text(custom_text: String, custom_color: Color, spawn_position: Vector2) -> void:
	global_position = spawn_position
	text = custom_text
	modulate = custom_color

	var magnitude = 1.5
	var float_distance = 60.0
	
	# --- NEW: Specific juice for Glove powerups and hazard blocks ---
	if custom_text == "GLOVE!" or custom_text == "BLOCKED!":
		magnitude = 2.0       # Make it visibly larger than normal text
		float_distance = 80.0 # Float higher so it doesn't get lost in the chaos
		z_index = 10          # Push it to the front of the UI
		
	scale = Vector2.ZERO
	pivot_offset = size / 2

	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "scale", Vector2.ONE * magnitude, 0.15) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
		
	# Add a dynamic elastic wobble specifically for the blocking action
	if custom_text == "BLOCKED!":
		rotation_degrees = randf_range(-15.0, 15.0)
		tween.tween_property(self, "rotation_degrees", 0.0, 0.3) \
			.set_trans(Tween.TRANS_ELASTIC) \
			.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "global_position:y", global_position.y - float_distance, 0.6) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(0.25)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	fade_tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.35) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)
	
	fade_tween.tween_callback(queue_free)
