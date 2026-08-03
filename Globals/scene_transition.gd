extends CanvasLayer

@onready var transition_rect: TextureRect = $Gradient
var swipe_speed: float = 0.5
var is_testing: bool = false

func _ready() -> void:
	# REMOVED: ResourceLoader.load self-call which creates export resource locks!
	
	# Fallback safety guard if node or layout calculations aren't initialized yet
	if not transition_rect:
		return
		
	# Ensure the node handles processing even if the main game tree is paused
	process_mode = PROCESS_MODE_ALWAYS
	
	# Reset pivot and grab starting position cleanly
	await get_tree().process_frame # Wait one frame for the layout engine to calculate true size
	var screen_width = get_viewport().get_visible_rect().size.x
	transition_rect.position.x = screen_width

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_R:
			if not is_testing:
				run_animation_test()

func run_animation_test() -> void:
	is_testing = true
	
	# 1. Swipe in to cover the screen
	await swipe_in()
	
	# 2. Hold the screen dark briefly
	await get_tree().create_timer(0.5).timeout
	
	# 3. Swipe out to uncover the screen
	await swipe_out()
	
	is_testing = false

func swipe_in() -> void:
	if not is_instance_valid(transition_rect): return
	
	var screen_width = get_viewport().get_visible_rect().size.x
	transition_rect.position.x = screen_width
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(transition_rect, "position:x", -1536.0, swipe_speed)
	await tween.finished

func swipe_out() -> void:
	if not is_instance_valid(transition_rect): return
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	var screen_width = get_viewport().get_visible_rect().size.x
	var target_x = -screen_width - 3100.0
	
	tween.tween_property(transition_rect, "position:x", target_x, swipe_speed)
	await tween.finished
	
func change_scene(target_scene: PackedScene) -> void:
	await swipe_in()
	get_tree().change_scene_to_packed(target_scene)
	await swipe_out()

func reload_scene() -> void:
	await swipe_in()
	get_tree().reload_current_scene()
	await swipe_out()
