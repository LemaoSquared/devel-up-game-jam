extends Node

signal life_lost(remaining: int)
signal lives_reset(max_lives: int)
signal game_over

@export var max_lives: int = 3
var lives: int = 3

func reset_lives() -> void:
	lives = max_lives
	lives_reset.emit(max_lives)

func lose_life() -> void:
	if lives <= 0:
		return
	lives -= 1
	life_lost.emit(lives)
	if lives <= 0:
		game_over.emit()
