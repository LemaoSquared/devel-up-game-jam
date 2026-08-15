extends HBoxContainer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D
@export var base_hearts: int = 3
@export var heart_size: Vector2 = Vector2(64, 64) # --- NEW: Set your size here! ---

var active_hearts: Array[TextureRect] = []

func _ready() -> void:
	if not full_heart or not empty_heart:
		push_error("LIVES UI: You must assign both Full and Empty heart textures in the inspector!")
		
	for child in get_children():
		child.queue_free()

	LivesManager.life_lost.connect(_on_life_lost)
	LivesManager.life_gained.connect(_on_life_gained)
	LivesManager.lives_reset.connect(_on_lives_reset)

	_sync_hearts(false)


# --- SIGNAL RESPONSES ---

func _on_life_lost(_value: int) -> void:
	_sync_hearts(true)

func _on_life_gained(_value: int) -> void:
	_sync_hearts(true)

func _on_lives_reset(_value: int) -> void:
	_sync_hearts(true)


# --- CORE LOGIC ---

func _sync_hearts(animate: bool) -> void:
	var target_slots = max(base_hearts, LivesManager.lives)
	
	# 1. REMOVE OVERFLOW
	while active_hearts.size() > target_slots:
		var extra_heart = active_hearts.pop_back() 
		if animate:
			_animate_destroy(extra_heart)
		else:
			extra_heart.queue_free()

	# 2. ADD OVERFLOW
	while active_hearts.size() < target_slots:
		var new_heart = _create_heart()
		active_hearts.append(new_heart)
		
		var is_full = (active_hearts.size() - 1) < LivesManager.lives
		new_heart.set_meta("is_full", is_full)
		new_heart.texture = full_heart if is_full else empty_heart
		
		if animate:
			_animate_create(new_heart)

	# 3. UPDATE BASE HEARTS
	for i in range(active_hearts.size()):
		var heart = active_hearts[i]
		var should_be_full = i < LivesManager.lives
		var currently_full = heart.get_meta("is_full")
		
		if should_be_full != currently_full:
			heart.set_meta("is_full", should_be_full) 
			if animate:
				if should_be_full:
					_animate_fill(heart)
				else:
					_animate_empty(heart)
			else:
				heart.texture = full_heart if should_be_full else empty_heart

func _create_heart() -> TextureRect:
	var rect = TextureRect.new()
	
	# --- NEW: Force the texture to scale to your custom size ---
	rect.custom_minimum_size = heart_size
	rect.size = heart_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED 
	
	add_child(rect)
	
	# Pre-calculate pivot offset based on the newly set custom size
	rect.pivot_offset = heart_size / 2.0
		
	return rect


# --- ANIMATIONS ---

func _animate_create(heart: TextureRect) -> void:
	heart.scale = Vector2.ZERO
	heart.modulate = Color(0.2, 1.0, 0.2) 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(heart, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "modulate", Color.WHITE, 0.4).set_delay(0.1)

func _animate_destroy(heart: TextureRect) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(heart, "modulate", Color(1.0, 0.2, 0.2, 0.0), 0.3)
	tween.tween_property(heart, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	tween.set_parallel(false)
	tween.tween_callback(heart.queue_free)

func _animate_empty(heart: TextureRect) -> void:
	var tween = create_tween()
	
	tween.set_parallel(true)
	tween.tween_property(heart, "modulate", Color(1.0, 0.2, 0.2), 0.15)
	tween.tween_property(heart, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	tween.set_parallel(false)
	tween.tween_callback(func(): 
		heart.texture = empty_heart
		heart.modulate = Color.WHITE
	)
	
	tween.tween_property(heart, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _animate_fill(heart: TextureRect) -> void:
	var tween = create_tween()
	
	tween.tween_property(heart, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(func(): 
		heart.texture = full_heart
		heart.modulate = Color(0.2, 1.0, 0.2)
	)
	
	tween.set_parallel(true)
	tween.tween_property(heart, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_property(heart, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(heart, "modulate", Color.WHITE, 0.2)
