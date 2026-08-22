extends AnimatedSprite2D

@onready var bg_manager: Node2D = $"../BackgroundManager"

func _ready() -> void:
	add_to_group("player") # Register her to a group
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

func play_damage_effect() -> void:
	var original_position = self.position
	var up_position = original_position + Vector2(0, -12.0) # Negative Y moves her upward
	
	# Flash red immediately
	self.modulate = Color(1, 0.3, 0.3)
	
	var tween = create_tween()
	
	# 1. Smoothly fade the red highlight back to normal white over 0.3 seconds
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# 2. Simultaneously handle the position bounce using a separate tween
	var pos_tween = create_tween()
	# Jump up quickly
	pos_tween.tween_property(self, "position", up_position, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Spring back down to her exact background position
	pos_tween.chain().tween_property(self, "position", original_position, 0.2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

func play_heal_effect() -> void:
	var original_scale = self.scale
	var zoom_scale = original_scale * 1.08 # A subtle, gentle size increase for the zoom
	
	# Flash green immediately
	self.modulate = Color(0.4, 1.0, 0.4)
	
	var tween = create_tween()
	
	# 1. Smoothly fade the green highlight back to normal white over 0.4 seconds
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
	
	# 2. Simultaneously handle the subtle zoom effect using a separate tween
	var scale_tween = create_tween()
	# Zoom in quickly
	scale_tween.tween_property(self, "scale", zoom_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Spring/smoothly return back to her exact background scale
	scale_tween.chain().tween_property(self, "scale", original_scale, 0.25).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
