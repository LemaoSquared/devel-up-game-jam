extends ProgressBar

func _ready() -> void:
	min_value = 0.0
	max_value = 100.0
	value = 100.0
	visible = false
	set_process(true) # Always process so it can detect when endless mode starts

func _process(_delta: float) -> void:
	if ItemManager.is_endless and not ItemManager.is_game_over:
		if not visible:
			visible = true
			
		var active_timer = ItemManager.active_wave_timer
		var total_duration = ItemManager.time_duration_perBatch

		if active_timer and total_duration > 0:
			var time_left = active_timer.time_left
			value = (time_left / total_duration) * 100.0
		else:
			value = 100.0
	else:
		if visible:
			visible = false
		value = 0.0
