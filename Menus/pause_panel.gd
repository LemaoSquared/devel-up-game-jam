extends Panel  # change if Pause's root type is different (e.g. Control, Panel)

@onready var resume_button: Button = $VBoxContainer/Resume
@onready var quit_button: Button = $VBoxContainer/Quit
const STREET = preload("uid://c6xk46jpedco4")

# Flag to prevent multiple clicks during countdown
var is_counting_down: bool = false

func _ready() -> void:
	# This node must run even while paused, so it can respond to button presses
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = false

	PauseManager.game_paused.connect(_on_game_paused)
	PauseManager.game_unpaused.connect(_on_game_unpaused)

	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_game_paused() -> void:
	visible = true

func _on_game_unpaused() -> void:
	visible = false

func _on_resume_pressed() -> void:
	if is_counting_down:
		return
	is_counting_down = true
	
	# Hide the pause menu immediately so the countdown is clean
	visible = false
	
	# Run the 3, 2, 1, GO! countdown
	await _run_countdown()
	
	is_counting_down = false
	PauseManager.unpause_game()
	print("UNPAUSED")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	PauseManager.unpause_game()
	PauseManager.disable_pause()
	ItemManager.is_game_over = true 
	ItemManager.clear_objects()
	SceneTransition.reload_scene()
	AudioManager.stop_music()
	await get_tree().create_timer(0.4).timeout
	AudioManager.play_music(STREET)
	queue_free()

# --- COUNTDOWN SYSTEM ---
func _run_countdown() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return

	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 120)
	
	tree.current_scene.add_child(label)

	var viewport = tree.root.get_viewport()
	var active_cam = viewport.get_camera_2d() if viewport else null
	var center_pos: Vector2
	
	if active_cam:
		center_pos = active_cam.get_screen_center_position()
	else:
		center_pos = viewport.get_visible_rect().size / 2.0 if viewport else Vector2.ZERO

	label.custom_minimum_size = Vector2(300, 200)
	label.size = Vector2(300, 200)
	label.pivot_offset = label.size / 2.0
	label.global_position = center_pos - (label.size / 2.0)

	var sequence = ["3", "2", "1", "GO!"]
	var active_tween: Tween = null

	for step in sequence:
		# Kill any running tween from the previous step so it stops forcing alpha to 0
		if active_tween and active_tween.is_running():
			active_tween.kill()

		# Reset visual parameters
		label.text = step
		label.modulate.a = 1.0
		label.scale = Vector2(1.5, 1.5)

		# Create new tween
		active_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		active_tween.set_parallel(true)
		active_tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		active_tween.tween_property(label, "modulate:a", 0.0, 0.2).set_delay(0.25)

		# Wait for full step duration before moving to the next number
		await tree.create_timer(0.5, true, false, true).timeout

	if active_tween and active_tween.is_running():
		active_tween.kill()

	label.queue_free()
