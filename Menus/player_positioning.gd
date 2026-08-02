extends Node2D

@onready var bg_manager: Node2D = $"../BackgroundManager"

func _ready():
	bg_manager.background_changed.connect(_on_background_changed)
	_on_background_changed(bg_manager.current_index)


func _on_background_changed(bg_index: int):
	
	match bg_index:
		0:
			# Rules for Background 0 (e.g., The Menu)
			self.scale = Vector2(1.687, 1.687)
			self.position = Vector2(264.0, 520)
			print("Sprite set up for Background 0")
			
		1:
			# Rules for Background 1 (e.g., Level 1)
			self.scale = Vector2(2.344, 2.344)
			self.position = Vector2(264.0, 400.0)
			print("Sprite set up for Background 1")
			
		2:
			# Rules for Background 2 
			self.scale = Vector2(0.672, 0.672)
			self.position = Vector2(256.0, 512.0)
			print("Sprite set up for Background 2")
