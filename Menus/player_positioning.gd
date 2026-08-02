extends AnimatedSprite2D

@onready var bg_manager: Node2D = $"../BackgroundManager"

func _ready():
	bg_manager.background_changed.connect(_on_background_changed)
	_on_background_changed(bg_manager.current_index)


func _on_background_changed(bg_index: int):
	
	match bg_index:
		0:
			# Rules for Background 0 (e.g., The Menu)
			self.scale = Vector2(7.445, 7.445)
			self.position = Vector2(448.0, 520.0)
			self.play("outside_idle")
			print("Sprite set up for Background 0")
			
		1:
			# Rules for Background 1 (e.g., Level 1)
			self.scale = Vector2(2.338, 2.338)
			self.position = Vector2(208, 408.325)
			self.play("Inside_Walk")
			print("Sprite set up for Background 1")
			
		2:
			# Rules for Background 2 
			self.scale = Vector2(0.89, 0.89)
			self.position = Vector2(296.0, 520.0)
			self.play("outside_walk")
			print("Sprite set up for Background 2")
