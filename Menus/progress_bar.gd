extends ProgressBar

@onready var gradient: TextureRect = $"../Background/Gradient"

signal countdown_finished
const COUNTDOWN_TIME: float = 90.0  # 1min 30 sec
const FIRST_GRADIENT_TIME: float = 30.0
const SECOND_GRADIENT_TIME: float = 70.0

@onready var timer: Timer = $Timer

# Tracking variables to ensure the gradient tweens only fire once
var first_gradient_triggered: bool = false
var second_gradient_triggered: bool = false

func _ready() -> void:
	min_value = 0
	max_value = 100
	value = 0
	set_process(false)
	
	# Ensure the gradient starts completely invisible
	if gradient:
		gradient.visible = false
		gradient.self_modulate.a = 0.0

func on_gradient_in(target_alpha: float = 0.5) -> void:
	if not gradient: return
	
	gradient.visible = true
	
	# 1. Smoothly fade the gradient in over 1.0 second
	var fade_in_tween = create_tween()
	fade_in_tween.set_trans(Tween.TRANS_SINE)
	fade_in_tween.set_ease(Tween.EASE_OUT)
	fade_in_tween.tween_property(gradient, "self_modulate:a", target_alpha, 1.0)
	
	# 2. Wait for the fade-in to complete, then start the 10-second display timer
	fade_in_tween.tween_callback(func():
		var display_timer = get_tree().create_timer(20.0, true)
		display_timer.timeout.connect(on_gradient_out)
	)

func on_gradient_out() -> void:
	if not gradient: return
	
	# 3. Smoothly fade the gradient back to invisible over 1.0 second
	var fade_out_tween = create_tween()
	fade_out_tween.set_trans(Tween.TRANS_SINE)
	fade_out_tween.set_ease(Tween.EASE_IN)
	fade_out_tween.tween_property(gradient, "self_modulate:a", 0.0, 1.0)
	
	# 4. Turn off visibility completely when the fade out finishes to save rendering performance
	fade_out_tween.tween_callback(func(): gradient.visible = false)
	
func start_countdown() -> void:
	# Reset tracking flags in case this is restarted
	first_gradient_triggered = false
	second_gradient_triggered = false
	if gradient:
		gradient.visible = false
		gradient.self_modulate.a = 0.0

	timer.wait_time = COUNTDOWN_TIME
	timer.one_shot = true
	timer.start()
	set_process(true)

func _process(_delta: float) -> void:
	var elapsed: float = COUNTDOWN_TIME - timer.time_left
	value = (elapsed / COUNTDOWN_TIME) * 100.0

	# --- GRADIENT MILESTONE CHECKS ---
	
	# Check for 30 seconds threshold
	if not first_gradient_triggered and elapsed >= FIRST_GRADIENT_TIME:
		first_gradient_triggered = true
		on_gradient_in(0.4)
		print("30 seconds reached: First gradient showing for 10 seconds.")

	# Check for 70 seconds threshold
	if not second_gradient_triggered and elapsed >= SECOND_GRADIENT_TIME:
		second_gradient_triggered = true
		on_gradient_in(0.8)
		print("70 seconds reached: Second gradient showing for 10 seconds.")

func _on_timer_timeout() -> void:
	value = 100.0
	set_process(false)
	countdown_finished.emit()
	PauseManager.disable_pause() 
	PauseManager.pause_game()
