extends Node2D

@export var backgrounds: Array[Node2D] 
@export var durations: Array[float]    
@export var loop_sequence: bool = true 
@export var starting_index: int = 0 
@export var transition_screen: TextureRect
@export var swipe_speed: float = 0.5 
@export var start_moving: bool = false 

@export var final_cutscene: PackedScene

signal background_changed(new_index:int)

var is_visible: bool = true
var is_moving: bool = false
var current_index: int = 0 

func _ready():
	is_moving = start_moving
	current_index = starting_index 
	
	if backgrounds.is_empty():
		push_error("ERROR: Your Backgrounds array is completely empty!")
	
	for i in range(backgrounds.size()):
		if backgrounds[i] == null:
			push_error("ERROR: Background slot [" + str(i) + "] is empty! Assign a node in the Inspector.")
	
	if durations.size() != backgrounds.size():
		push_warning("WARNING: You have " + str(backgrounds.size()) + " backgrounds but " + str(durations.size()) + " durations. They should match!")
	# -------------------------------
		
	_apply_state()
	
	if transition_screen:
		transition_screen.position.x = get_viewport_rect().size.x
	else:
		push_error("ERROR: Transition Screen not assigned!")

func _on_start_pressed() -> void:
	start_sequence()

func start_sequence():
	# Advance to the NEXT background in the array
	var next_index = current_index + 1
	if next_index >= backgrounds.size():
		next_index = 0 
		
	_swipe_transition(next_index)
	

# --- THE SEQUENCE LOGIC ---

func _start_timer_for_current_bg():
	var wait_time = 5.0
	if current_index < durations.size():
		wait_time = durations[current_index]
		
	var timer = get_tree().create_timer(wait_time)
	timer.timeout.connect(_on_timer_finished)

func _on_timer_finished():
	var next_index = current_index + 1
	
	if next_index >= backgrounds.size():
		if loop_sequence:
			next_index = 0
		else:
			print("Sequence complete! Moving to Cutscene...")
			if final_cutscene:
					_swipe_to_cutscene()
			else:
					push_error("NO CUTSCENE ASSIGNED")
			return 
			
	_swipe_transition(next_index)

# --- THE SWIPE ANIMATION ---
func _swipe_to_cutscene():
	if not transition_screen:
		get_tree().change_scene_to_packed(final_cutscene)
		return
	var screen_width = get_viewport_rect().size.x
	transition_screen.position.x = screen_width
	
	var tween = create_tween()
	tween.set_trans(tween.TRANS_LINEAR)
	
	tween.tween_property(transition_screen, "position:x", -1536,swipe_speed)
	
	tween.tween_callback(func():
		get_tree().change_scene_to_packed(final_cutscene))

func _swipe_transition(target_index: int):
	if not transition_screen:
		return
		
	var screen_width = get_viewport_rect().size.x
	transition_screen.position.x = screen_width
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_property(transition_screen, "position:x", -1536.0, swipe_speed)
	
	tween.tween_callback(func():
		current_index = target_index
		is_moving = true 
		_apply_state()
		
		background_changed.emit(current_index)
		
		print("Swapped to Background index ", current_index)
	)
	
	tween.tween_property(transition_screen, "position:x", -screen_width - 3100, swipe_speed)
	
	tween.tween_callback(func():
		_start_timer_for_current_bg()
	)

# --- THE ENGINE ROOM ---

func _apply_state():
	for i in range(backgrounds.size()):
		var bg = backgrounds[i]
		if not bg: 
			continue
			
		var is_active = (i == current_index)
		
		bg.visible = is_visible and is_active
		
		if is_visible and is_active and is_moving:
			bg.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			bg.process_mode = Node.PROCESS_MODE_DISABLED
