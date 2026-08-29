extends Node

signal life_lost(remaining: int)
signal life_gained(current: int)
signal lives_reset(max_lives: int)
signal game_over

@export var max_lives: int = 3
var lives: int = 3


func reset_lives() -> void:
	lives = max_lives
	lives_reset.emit(lives)


func lose_life() -> void:
	if lives <= 0:
		return

	lives -= 1
	life_lost.emit(lives)

	if lives <= 0:
		game_over.emit()


func gain_life(amount: int = 1) -> void:
	if lives >= max_lives:
		return

	lives = min(lives + amount, max_lives)
	life_gained.emit(lives)
