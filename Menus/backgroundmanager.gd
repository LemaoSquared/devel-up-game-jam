extends Node2D

@export var background_a: Node2D
@export var background_b: Node2D
@export var start_with_a: bool = true
@export var start_moving: bool = false # Keeps it frozen when the game starts

var is_visible: bool = true
var is_moving: bool = false
var active_bg: String = "A"

func _ready():
	is_moving = start_moving
	if not start_with_a:
		active_bg = "B"
		
	_apply_state()

# --- MOVEMENT CONTROLS (PLAY / PAUSE) ---

func play_movement():
	is_moving = true
	_apply_state()
	print("Background is moving")

func pause_movement():
	is_moving = false
	_apply_state()
	print("Background is frozen")

func toggle_movement():
	is_moving = !is_moving
	_apply_state()

# --- VISIBILITY CONTROLS (SHOW / HIDE) ---

func show_background():
	is_visible = true
	_apply_state()

func hide_background():
	is_visible = false
	_apply_state()

# --- SWITCHING BACKGROUNDS ---

func switch_to_a():
	active_bg = "A"
	_apply_state()
	print("Switched to Background A")

func switch_to_b():
	active_bg = "B"
	_apply_state()
	print("Switched to Background B")

# --- THE ENGINE ROOM ---

func _apply_state():
	# Evaluate Background A
	var a_active = (active_bg == "A")
	if background_a:
		background_a.visible = is_visible and a_active
		# Only allow movement if it is visible, active, AND the moving toggle is on
		if is_visible and a_active and is_moving:
			background_a.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			background_a.process_mode = Node.PROCESS_MODE_DISABLED
			
	# Evaluate Background B
	var b_active = (active_bg == "B")
	if background_b:
		background_b.visible = is_visible and b_active
		if is_visible and b_active and is_moving:
			background_b.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			background_b.process_mode = Node.PROCESS_MODE_DISABLED
