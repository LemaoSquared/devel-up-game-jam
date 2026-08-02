extends Node2D

@export var backgrounds: Array[Node2D] 
@export var durations: Array[float]    
@export var loop_sequence: bool = true 
@export var starting_index: int = 0 
@export var start_moving: bool = false 

# --- NEW: It just announces when it's done! ---
signal background_changed(new_index:int)
signal sequence_finished 
# ----------------------------------------------

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
			push_error("ERROR: Background slot [" + str(i) + "] is empty!")
	
	if durations.size() != backgrounds.size():
		push_warning("WARNING: Backgrounds and Durations arrays must match in size!")
		
	_apply_state()

func _on_start_pressed() -> void:
	start_sequence()

func start_sequence():
	var next_index = current_index + 1
	if next_index >= backgrounds.size():
		next_index = 0 
		
	_change_background(next_index)

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
			print("Background sequence complete!")
			# --- NEW: Tell the rest of the game we are done ---
			sequence_finished.emit()
			return 
			
	_change_background(next_index)


func _change_background(target_index: int):
	await SceneTransition.swipe_in()
	
	current_index = target_index
	is_moving = true 
	_apply_state()
	background_changed.emit(current_index)
	
	await SceneTransition.swipe_out()
	_start_timer_for_current_bg()

func _apply_state():
	for i in range(backgrounds.size()):
		var bg = backgrounds[i]
		if not bg: continue
			
		var is_active = (i == current_index)
		bg.visible = is_visible and is_active
		
		if is_visible and is_active and is_moving:
			bg.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			bg.process_mode = Node.PROCESS_MODE_DISABLED
