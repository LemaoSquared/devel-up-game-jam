extends ProgressBar

signal countdown_finished

const COUNTDOWN_TIME: float = 20.0  # 1min 30 sec

@onready var timer: Timer = $Timer

func _ready() -> void:
	min_value = 0
	max_value = 100
	value = 0
	set_process(false)

func start_countdown() -> void:
	timer.wait_time = COUNTDOWN_TIME
	timer.one_shot = true
	timer.start()
	set_process(true)

func _process(_delta: float) -> void:
	var elapsed: float = COUNTDOWN_TIME - timer.time_left
	value = (elapsed / COUNTDOWN_TIME) * 100.0


func _on_timer_timeout() -> void:
	value = 100.0
	set_process(false)
	countdown_finished.emit()
	PauseManager.disable_pause() 
	PauseManager.pause_game()      
