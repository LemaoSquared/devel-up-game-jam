extends Node2D

const STREET = preload("uid://c6xk46jpedco4")

@export var backgrounds: Array[Node2D] 
@export var durations: Array[float] 
@export var loop_sequence: bool = true 
@export var starting_index: int = 0 
@export var start_moving: bool = false 

# --- SIGNALS ---
signal background_changed(new_index:int)
signal sequence_finished 

var is_visible: bool = true
var is_moving: bool = false
var current_index: int = 0 

# --- ENDLESS MODE SETTINGS ---
var is_endless_mode: bool = false
# Index 1 (Store) = 39.0s, Index 2 (Street) = 55.0s
var endless_durations: Dictionary = {
	1: 39.0,
	2: 55.0
}

# --- CANCELLATION TRACKING ---
var active_timer: SceneTreeTimer = null
var transition_id: int = 0

func reset():
	is_endless_mode = false
	is_moving = start_moving
	current_index = starting_index 
	
	# Invalidate any in-flight transitions or pending timers
	transition_id += 1
	active_timer = null
	
	if backgrounds.is_empty():
		push_error("ERROR: Your Backgrounds array is completely empty!")
	
	for i in range(backgrounds.size()):
		if backgrounds[i] == null:
			push_error("ERROR: Background slot [" + str(i) + "] is empty!")
	
	if durations.size() != backgrounds.size():
		push_warning("WARNING: Backgrounds and Durations arrays must match in size!")
		
	_apply_state()
	
func _ready():
	AudioManager.play_music(STREET)
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
	is_endless_mode = false
	start_sequence()

func _on_endless_start_pressed() -> void:
	is_endless_mode = true
	# Start gameplay on Index 1 (Store)
	_change_background(1)

func start_sequence():
	var next_index = current_index + 1
	if next_index >= backgrounds.size():
		next_index = 0 
		
	_change_background(next_index)

func _start_timer_for_current_bg():
	var wait_time = 5.0
	
	if is_endless_mode:
		wait_time = endless_durations.get(current_index, 39.0)
	else:
		if current_index < durations.size():
			wait_time = durations[current_index]
		
	var current_trans_id = transition_id
	active_timer = get_tree().create_timer(wait_time)
	active_timer.timeout.connect(func():
		# Only proceed if reset() hasn't been called in the meantime
		if current_trans_id == transition_id:
			_on_timer_finished()
	)

func _on_timer_finished():
	var next_index: int
	
	if is_endless_mode:
		# Toggle strictly between 1 (Store) and 2 (Street)
		next_index = 2 if current_index == 1 else 1
	else:
		next_index = current_index + 1
		if next_index >= backgrounds.size():
			if loop_sequence:
				next_index = 0
			else:
				print("Background sequence complete!")
				sequence_finished.emit()
				return 
			
	_change_background(next_index)

func _change_background(target_index: int):
	var current_trans_id = transition_id + 1
	transition_id = current_trans_id

	await SceneTransition.swipe_in()
	# Abort if reset() was called while swiping in
	if current_trans_id != transition_id:
		return

	current_index = target_index
	is_moving = true 
	_apply_state()
	background_changed.emit(current_index)
	
	await SceneTransition.swipe_out()
	# Abort if reset() was called while swiping out
	if current_trans_id != transition_id:
		return

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
