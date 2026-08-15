extends Label


func _ready() -> void:
	LivesManager.life_lost.connect(_on_lives_changed)
	LivesManager.life_gained.connect(_on_lives_changed)
	LivesManager.lives_reset.connect(_on_lives_changed)

	update_heart_count()


func _on_lives_changed(_value: int) -> void:
	update_heart_count()


func update_heart_count() -> void:
	text = "HEART COUNT: " + str(LivesManager.lives)
