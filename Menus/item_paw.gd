extends Node2D

signal popped_out(obj: Node, was_clicked: bool)
#const PAW_PARTICLE = preload("uid://b1e6bon8ifbuk")
#const PAW_SOUND = preload("uid://dl4pnno0q6i3k")

var is_popping: bool = false

const DURATION: float = 6.0

@onready var paw_area: Area2D = $Paw
@onready var sprite_2d: AnimatedSprite2D = $Paw/Sprite2D


func _ready() -> void:
	if sprite_2d and sprite_2d.sprite_frames and sprite_2d.sprite_frames.has_animation("default"):
		sprite_2d.play("default")

	paw_area.input_pickable = false

	var timer := get_tree().create_timer(DURATION, false)
	timer.timeout.connect(_on_duration_expired)

	start_floating(self)


# --- Multi-touch & Mouse Input Handling ---
func _input(event: InputEvent) -> void:
	if is_popping:
		return
		
	var click_pos = Vector2.ZERO
	var is_triggered: bool = false
	
	if event is InputEventScreenTouch and event.pressed:
		click_pos = event.position
		is_triggered = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_pos = event.position
		is_triggered = true
		
	if is_triggered:
		if global_position.distance_to(click_pos) < 64.0:
			collect_paw()


func collect_paw() -> void:
	if is_popping:
		return

	var cat_paw_node := get_tree().get_first_node_in_group("cat_paw") # Or use a direct path
	if cat_paw_node and cat_paw_node.has_method("play_paw_swipe"):
		cat_paw_node.play_paw_swipe()
	#AudioManager.play_sound(PAW_SOUND)
	#ParticleManager.spawn_particle(PAW_PARTICLE, global_position)
	
	is_popping = true
	paw_area.input_pickable = false

	# --- PAW POWER-UP SPATIAL CONTROL EFFECT ---
	var paw_pos = global_position
	var current_scene = get_tree().current_scene
	
	if current_scene:
		for node in current_scene.get_children():
			if node == self or not node is Node2D:
				continue
				
			# Check if the node is an active game item
			if node.has_meta("item_type") or "item_type" in node or node.has_method("pop_out"):
				var item_type = node.get_meta("item_type", -1)
				
				# Identify hazards (Item.GARBAGE = 2, Item.SHOES = 4)
				var is_hazard = (item_type == 2 or item_type == 4)
				
				var item_pos = node.global_position
				var to_item = item_pos - paw_pos
				var dist = max(to_item.length(), 1.0)
				var dir = to_item / dist
				
				# --- Tell hanging items (like shoes/yarn) to stop swaying ---
				if node.has_method("start_drag"):
					node.start_drag()
				
				var tween = node.create_tween()
				tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
				tween.set_trans(Tween.TRANS_QUAD)
				tween.set_ease(Tween.EASE_OUT)
				
				if is_hazard:
					# Push shoes/garbage farther away
					var target_pos = item_pos + (dir * 140.0)
					tween.tween_property(node, "global_position", target_pos, 0.3)
					
					# Update anchor so it stays and sways from its NEW pushed position
					if node.has_method("update_anchor_position"):
						tween.tween_callback(func(): node.update_anchor_position(target_pos))
					elif node.has_method("end_drag"):
						tween.tween_callback(func(): node.end_drag(false))

				else:
					# Pull regular gifts closer toward the paw's position (35% distance remaining)
					var target_pos = paw_pos + (to_item * 0.35)
					tween.tween_property(node, "global_position", target_pos, 0.3)
					
					# --- Update anchor so it stays and sways right where it was pulled ---
					if node.has_method("update_anchor_position"):
						tween.tween_callback(func(): node.update_anchor_position(target_pos))
					elif node.has_method("end_drag"):
						tween.tween_callback(func(): node.end_drag(false))

	popped_out.emit(self, true)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)


func start_floating(
	obj: Node2D,
	float_height: float = 12.0,
	duration: float = 1.0
) -> void:
	var float_tween := obj.create_tween().set_loops()

	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)

	float_tween.tween_property(
		obj,
		"position:y",
		-float_height,
		duration
	).as_relative()

	float_tween.tween_property(
		obj,
		"position:y",
		float_height * 2.0,
		duration * 2.0
	).as_relative()

	float_tween.tween_property(
		obj,
		"position:y",
		-float_height * 2.0,
		duration * 2.0
	).as_relative()


func _on_duration_expired() -> void:
	if is_popping:
		return

	pop_out()


func pop_out() -> void:
	if is_popping:
		return

	is_popping = true
	paw_area.input_pickable = false

	popped_out.emit(self, false)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
