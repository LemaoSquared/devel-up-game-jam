extends AnimatedSprite2D

@onready var bg_manager: Node2D = $"../BackgroundManager"

# Reference to track the active i-frame blinking tween
var invincibility_tween: Tween

# State trackers
var current_bg_index: int = 0
var has_gloves: bool = false

func _ready() -> void:
	add_to_group("player") # Register her to a group
	bg_manager.background_changed.connect(_on_background_changed)
	_on_background_changed(bg_manager.current_index)

func _on_background_changed(bg_index: int) -> void:
	current_bg_index = bg_index
	
	match bg_index:
		0:
			# Rules for Background 0 (e.g., The Menu)
			self.scale = Vector2(7.445, 7.445)
			self.position = Vector2(448.0, 520.0)
			print("Sprite set up for Background 0")
		1:
			# Rules for Background 1 (e.g., Level 1)
			self.scale = Vector2(2.338, 2.338)
			self.position = Vector2(208.0, 408.325)
			print("Sprite set up for Background 1")
		2:
			# Rules for Background 2 
			self.scale = Vector2(0.89, 0.89)
			self.position = Vector2(296.0, 520.0)
			print("Sprite set up for Background 2")

	# Update the animation visually without trying to maintain frame progress
	# since transitioning between backgrounds means changing locations completely.
	_update_animation_visually(false)

# Call this function from your ItemManager when gloves are collected or broken
func set_gloves_active(active: bool) -> void:
	if has_gloves == active:
		return # Do nothing if the state isn't actually changing
		
	has_gloves = active
	
	# Update the animation and maintain the current frame so the walk cycle doesn't skip
	_update_animation_visually(true)

func _update_animation_visually(maintain_frame: bool) -> void:
	# Cache current frame data before we swap the animation
	var cached_frame = self.frame
	var cached_progress = self.frame_progress
	
	var target_anim = ""
	
	match current_bg_index:
		0:
			target_anim = "outside_idle" # No glove equivalent provided in image_48f189.png
		1:
			target_anim = "Inside_Walk_Gloves" if has_gloves else "Inside_Walk"
		2:
			target_anim = "outside_walk_Gloves" if has_gloves else "outside_walk"
			
	self.play(target_anim)
	
	# If we want a seamless swap (like picking up a glove mid-walk), reapply the frame data
	if maintain_frame and target_anim != "outside_idle":
		# Ensure we don't try to set a frame that doesn't exist if animation lengths vary
		var max_frames = self.sprite_frames.get_frame_count(target_anim)
		if cached_frame < max_frames:
			self.set_frame_and_progress(cached_frame, cached_progress)
		else:
			self.set_frame_and_progress(0, 0.0)


func play_damage_effect() -> void:
	var original_position = self.position
	var up_position = original_position + Vector2(0, -12.0) 
	
	self.modulate = Color(1.0, 0.3, 0.3, self.modulate.a)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:r", 1.0, 0.3)
	tween.parallel().tween_property(self, "modulate:g", 1.0, 0.3)
	tween.parallel().tween_property(self, "modulate:b", 1.0, 0.3)
	
	var pos_tween = create_tween()
	pos_tween.tween_property(self, "position", up_position, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pos_tween.chain().tween_property(self, "position", original_position, 0.2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

	if invincibility_tween and invincibility_tween.is_valid():
		invincibility_tween.kill()

	invincibility_tween = create_tween()
	invincibility_tween.set_loops(14)
	invincibility_tween.tween_property(self, "modulate:a", 0.3, 0.15)
	invincibility_tween.tween_property(self, "modulate:a", 1.0, 0.15)

	invincibility_tween.finished.connect(func():
		self.modulate.a = 1.0
	)

func play_heal_effect() -> void:
	var original_scale = self.scale
	var zoom_scale = original_scale * 1.08 
	
	self.modulate = Color(0.4, 1.0, 0.4, 1.0)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
	
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", zoom_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.chain().tween_property(self, "scale", original_scale, 0.25).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
