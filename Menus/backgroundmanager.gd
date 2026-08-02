extends Node2D

@export var background_a: Node2D
@export var background_b: Node2D
@export var transition_screen: TextureRect
@export var seconds_until_a: float = 5.0 
@export var seconds_until_b: float = 10.0 
@export var swipe_speed: float = 0.5 
@export var start_moving: bool = false 

var is_visible: bool = true
var is_moving: bool = false
var active_bg: String = "B"

func _ready():
	is_moving = start_moving
	active_bg = "B"
	_apply_state()
	
	# Make sure the transition screen starts safely hidden off-screen to the right
	if transition_screen:
		transition_screen.position.x = get_viewport_rect().size.x
	else:
		push_error("Transition Screen not assigned in BackgroundManager!")

# --- TRIGGER THIS WHEN YOUR BUTTON IS PRESSED ---

func start_sequence():
	is_moving = true
	_apply_state()
	print("Sequence started! Background B is moving.")
	
	var timer = get_tree().create_timer(seconds_until_a)
	timer.timeout.connect(func(): _swipe_transition("A"))

# --- THE SWIPE ANIMATION ---

func _swipe_transition(target_bg: String):
	if not transition_screen:
		return
		
	var screen_width = get_viewport_rect().size.x
	
	# Reset the screen to the right side and ensure it covers the viewport
	transition_screen.position.x = screen_width
	transition_screen.size = get_viewport_rect().size
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	# 1. Slide the screen IN (Right to Left)
	tween.tween_property(transition_screen, "position:x", -1536.0, swipe_speed)
	
	# 2. Swap the backgrounds instantly while the screen covers the view
	tween.tween_callback(func():
		active_bg = target_bg
		_apply_state()
		print("Swapped to Background ", target_bg)
	)
	
	# 3. Slide the screen OUT (Continuing Left)
	tween.tween_property(transition_screen, "position:x", -screen_width -3100, swipe_speed)
	
	# 4. If we just swapped to A, queue up the swap back to B
	tween.tween_callback(func():
		if target_bg == "A":
			var timer = get_tree().create_timer(seconds_until_b)
			timer.timeout.connect(func(): _swipe_transition("B"))
	)

# --- THE ENGINE ROOM ---

func _apply_state():
	var a_active = (active_bg == "A")
	if background_a:
		background_a.visible = is_visible and a_active
		if is_visible and a_active and is_moving:
			background_a.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			background_a.process_mode = Node.PROCESS_MODE_DISABLED
			
	var b_active = (active_bg == "B")
	if background_b:
		background_b.visible = is_visible and b_active
		if is_visible and b_active and is_moving:
			background_b.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			background_b.process_mode = Node.PROCESS_MODE_DISABLED

func _on_start_pressed() -> void:
	start_sequence()
