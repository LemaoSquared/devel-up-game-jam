extends CanvasLayer

@onready var dim_background: ColorRect = $"Background Dimming"
@onready var hanger_container: Control = $Hanger

@onready var resume_button: TextureButton = $Hanger/Continue
@onready var quit_button: TextureButton = $Hanger/Quit

const STREET = preload("uid://c6xk46jpedco4")

var offscreen_y: float = -1200.0
var onscreen_y: float = 0.0

var transition_tween: Tween

var original_scales: Dictionary = {} 
var original_rotations: Dictionary = {} 
var hover_tweens: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	dim_background.modulate.a = 0.0
	hanger_container.position.y = offscreen_y

	# Save their starting custom scales AND rotations
	original_scales[resume_button] = resume_button.scale
	original_scales[quit_button] = quit_button.scale
	
	original_rotations[resume_button] = resume_button.rotation_degrees
	original_rotations[quit_button] = quit_button.rotation_degrees

	# Connect Pause Signals
	PauseManager.game_paused.connect(_on_game_paused)
	PauseManager.game_unpaused.connect(_on_game_unpaused)

	# Connect Button Presses
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect Button Hovers
	resume_button.mouse_entered.connect(_on_button_hovered.bind(resume_button))
	resume_button.mouse_exited.connect(_on_button_unhovered.bind(resume_button))
	quit_button.mouse_entered.connect(_on_button_hovered.bind(quit_button))
	quit_button.mouse_exited.connect(_on_button_unhovered.bind(quit_button))

# --- HOVER LOGIC ---

func _on_button_hovered(btn: TextureButton) -> void:
	if hover_tweens.has(btn) and hover_tweens[btn]:
		hover_tweens[btn].kill()
		
	hover_tweens[btn] = create_tween()
	var target_scale = original_scales[btn] * 1.1 
	hover_tweens[btn].tween_property(btn, "scale", target_scale, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_button_unhovered(btn: TextureButton) -> void:
	if hover_tweens.has(btn) and hover_tweens[btn]:
		hover_tweens[btn].kill()
		
	hover_tweens[btn] = create_tween()
	hover_tweens[btn].tween_property(btn, "scale", original_scales[btn], 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# --- PAUSE MANAGER SIGNALS ---

func _on_game_paused() -> void:
	if not PauseManager.pause_enabled:
		return
	visible = true
	_slide_in()

func _on_game_unpaused() -> void:
	_slide_out()

# --- ANIMATIONS ---

func _slide_in() -> void:
	if transition_tween:
		transition_tween.kill()
		
	transition_tween = create_tween().set_parallel(true)
	transition_tween.tween_property(dim_background, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	hanger_container.position.y = offscreen_y
	transition_tween.tween_property(hanger_container, "position:y", onscreen_y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	hanger_container.rotation_degrees = -5.0
	transition_tween.tween_property(hanger_container, "rotation_degrees", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_swing_picture(resume_button)
	_swing_picture(quit_button)

func _swing_picture(btn: TextureButton) -> void:
	var swing = create_tween()
	var base_rot = original_rotations[btn] 
	
	swing.tween_property(btn, "rotation_degrees", base_rot + 12.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	swing.tween_property(btn, "rotation_degrees", base_rot - 8.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_property(btn, "rotation_degrees", base_rot + 4.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_property(btn, "rotation_degrees", base_rot, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _slide_out() -> void:
	if transition_tween:
		transition_tween.kill()
		
	transition_tween = create_tween().set_parallel(true)
	transition_tween.tween_property(dim_background, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	
	transition_tween.tween_property(hanger_container, "position:y", offscreen_y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	transition_tween.tween_property(resume_button, "rotation_degrees", original_rotations[resume_button] - 15.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	transition_tween.tween_property(quit_button, "rotation_degrees", original_rotations[quit_button] - 10.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	_on_button_unhovered(resume_button)
	_on_button_unhovered(quit_button)
	
	transition_tween.set_parallel(false)
	transition_tween.tween_callback(func(): visible = false)

# --- BUTTON LOGIC ---

func _on_resume_pressed() -> void:
	PauseManager.unpause_game()
	_slide_out()

func _on_quit_pressed() -> void:
	_reset_game_state()
	
	SceneTransition.reload_scene()
	AudioManager.stop_music()
	
	await get_tree().create_timer(0.4).timeout
	AudioManager.play_music(STREET)

func _reset_game_state() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	PauseManager.unpause_game()
	PauseManager.disable_pause()
	ItemManager.is_game_over = true 
	ItemManager.clear_objects()
	
	visible = false
	dim_background.modulate.a = 0.0
	hanger_container.position.y = offscreen_y
	
	resume_button.rotation_degrees = original_rotations[resume_button]
	quit_button.rotation_degrees = original_rotations[quit_button]
