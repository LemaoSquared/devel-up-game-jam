extends ProgressBar

@onready var wave_effect: TextureRect = $WaveEffect

var current_active_timer: SceneTreeTimer = null
var wave_effect_tween: Tween = null

func _ready() -> void:
	min_value = 0.0
	max_value = 100.0
	value = 100.0
	visible = false
	
	if wave_effect:
		wave_effect.modulate.a = 0.0
		
	set_process(true) # Always process so it can detect when endless mode starts

func _process(_delta: float) -> void:
	if ItemManager.is_endless and not ItemManager.is_game_over:
		if not visible:
			visible = true
			
		var active_timer = ItemManager.active_wave_timer
		var total_duration = ItemManager.time_duration_perBatch

		# Detects whenever ItemManager spins up a brand new wave timer
		if active_timer != current_active_timer:
			current_active_timer = active_timer
			if active_timer != null:
				trigger_wave_effect()

		if active_timer and total_duration > 0:
			var time_left = active_timer.time_left
			value = (time_left / total_duration) * 100.0
		else:
			value = 100.0
	else:
		if visible:
			visible = false
		value = 0.0
		current_active_timer = null

func trigger_wave_effect() -> void:
	if not wave_effect:
		return
		
	# Cancel any ongoing wave effect tween to avoid visual overlaps
	if wave_effect_tween and wave_effect_tween.is_valid():
		wave_effect_tween.kill()
		
	wave_effect.modulate.a = 0.0
	wave_effect_tween = create_tween()
	
	# Phase 1: Quick punch-in / fade in
	wave_effect_tween.tween_property(wave_effect, "modulate:a", 1.0, 0.15)
	
	# Phase 2: Smooth fade out back to transparent
	wave_effect_tween.tween_property(wave_effect, "modulate:a", 0.0, 0.4)
