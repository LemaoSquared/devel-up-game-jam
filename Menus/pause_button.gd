extends TextureButton

var original_scale: Vector2
var original_rotation: float

var hover_scale: Vector2 = Vector2(1.1, 1.1) # 10% bigger
var press_scale: Vector2 = Vector2(0.9, 0.9) # 10% smaller

var scale_tween: Tween
var wobble_tween: Tween

func _ready() -> void:
	original_scale = scale
	original_rotation = rotation_degrees
	
	# Center the pivot so it scales and rotates from the middle!
	pivot_offset = size / 2.0
	
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	button_down.connect(_on_press)
	button_up.connect(_on_release)

# --- SCALE ANIMATION ---
func animate_scale(target_scale: Vector2, duration: float) -> void:
	if scale_tween:
		scale_tween.kill()
		
	scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# --- WOBBLE ANIMATION ---
func start_wobble() -> void:
	if wobble_tween:
		wobble_tween.kill()
		
	wobble_tween = create_tween().set_loops()
	# Wiggle right, then left, then center
	wobble_tween.tween_property(self, "rotation_degrees", 5.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(self, "rotation_degrees", -5.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(self, "rotation_degrees", 0.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func stop_wobble() -> void:
	if wobble_tween:
		wobble_tween.kill()
		
	# Smoothly return to the original upright position
	wobble_tween = create_tween()
	wobble_tween.tween_property(self, "rotation_degrees", original_rotation, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# --- SIGNAL RESPONSES ---
func _on_hover() -> void:
	start_wobble()
	if not button_pressed:
		animate_scale(hover_scale, 0.15)

func _on_unhover() -> void:
	stop_wobble()
	animate_scale(original_scale, 0.2)

func _on_press() -> void:
	animate_scale(press_scale, 0.1)

func _on_release() -> void:
	if is_hovered():
		animate_scale(hover_scale, 0.15)
	else:
		animate_scale(original_scale, 0.2)
