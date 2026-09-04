extends TextureRect

@onready var streak_label: Label = $StreakLabel
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var streak_notif: Label = $"../StreakNotif"

@export_group("Animation Settings")
@export var hidden_offset_x: float = -250.0  # How far off-screen to the left it starts relative to its editor position
@export var slide_duration: float = 0.35
@export var tilt_angle_deg: float = 8.0      # Max tilt angle in degrees
@export var tilt_duration: float = 0.8       # Swing duration factor

@export_group("Color Settings")
@export var tap_color: Color = Color.PALE_GOLDENROD     # Color for x2 (Tap) streak
@export var taptap_color: Color = Color.ALICE_BLUE      # Color for x3 (Taptap) streak
@export var triple_tap_color: Color = Color.CORAL       # Color for x4 (Triple Tap) streak
@export var tap_flash_color: Color = Color.WHITE        # Flash color on tap

var target_position: Vector2
var hidden_position: Vector2
var is_visible_streak: bool = false
var tilt_tween: Tween = null
var flash_tween: Tween = null
var notif_tween: Tween = null
var current_text_color: Color = Color.WHITE
var last_notified_val: int = 1

func _ready() -> void:
	# Set the pivot offset to the center so it rotates in place
	pivot_offset = size / 2.0
	
	# Capture the position set in the editor as the target destination
	target_position = position
	hidden_position = Vector2(target_position.x + hidden_offset_x, target_position.y)
	
	# Automatically tuck it away and hide it on start
	position = hidden_position
	visible = false
	
	if streak_label:
		current_text_color = tap_color
		streak_label.add_theme_color_override("font_color", current_text_color)
		
	# Initialize streak notification label
	if streak_notif:
		streak_notif.pivot_offset = streak_notif.size / 2.0
		streak_notif.modulate.a = 0.0

func _process(_delta: float) -> void:
	pass

# Call this whenever the streak or multiplier changes
func update_streak_ui(streak_count: int, multiplier: int) -> void:
	var active_val = multiplier if multiplier > 1 else streak_count
	
	if active_val >= 2:
		# Assign colors & trigger notifications based on x2, x3, and x4+
		match active_val:
			2:
				current_text_color = tap_color
				if last_notified_val != 2:
					_trigger_streak_notification("Tap Streak!")
					last_notified_val = 2
			3:
				current_text_color = taptap_color
				if last_notified_val != 3:
					_trigger_streak_notification("Taptap Streak!")
					last_notified_val = 3
			_:
				# x4 and above
				current_text_color = triple_tap_color
				if last_notified_val != 4:
					_trigger_streak_notification("Triple Tap Streak!")
					last_notified_val = 4
			
		if streak_label:
			streak_label.text = "x" + str(active_val)
			streak_label.add_theme_color_override("font_color", current_text_color)
		
		if not is_visible_streak:
			is_visible_streak = true
			visible = true
			_slide_in()
			_start_tilting()
			if gpu_particles_2d:
				gpu_particles_2d.restart()
				gpu_particles_2d.emitting = true
	else:
		last_notified_val = 1
		if is_visible_streak:
			is_visible_streak = false
			_stop_tilting()
			_slide_out()
			if gpu_particles_2d:
				gpu_particles_2d.emitting = false

# Call this function on tap / tap-tap to flash the label color
func trigger_tap_flash(custom_color: Color = Color.TRANSPARENT) -> void:
	if not streak_label:
		return
		
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
		
	var flash_col = custom_color if custom_color != Color.TRANSPARENT else tap_flash_color
	streak_label.modulate = flash_col
	
	flash_tween = create_tween()
	flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	flash_tween.tween_property(streak_label, "modulate", Color.WHITE, 0.25)

func _trigger_streak_notification(text: String) -> void:
	if not streak_notif:
		return
		
	if notif_tween and notif_tween.is_valid():
		notif_tween.kill()
		
	streak_notif.text = text
	streak_notif.visible = true
	streak_notif.modulate.a = 0.0
	streak_notif.scale = Vector2(0.6, 0.6)
	
	notif_tween = create_tween()
	notif_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	
	# Pop in: Fade in + scale up with a slight back ease
	notif_tween.tween_property(streak_notif, "modulate:a", 1.0, 0.2)
	notif_tween.parallel().tween_property(streak_notif, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Hold on screen briefly
	notif_tween.tween_interval(0.4)
	
	# Fade out & scale out larger
	notif_tween.tween_property(streak_notif, "modulate:a", 0.0, 0.3)
	notif_tween.parallel().tween_property(streak_notif, "scale", Vector2(1.4, 1.4), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _slide_in() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_position, slide_duration)

func _slide_out() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", hidden_position, slide_duration).from_current()
	tween.tween_callback(func(): visible = false)

func _start_tilting() -> void:
	if tilt_tween and tilt_tween.is_valid():
		tilt_tween.kill()
		
	var tilt_rad: float = deg_to_rad(tilt_angle_deg)
	
	tilt_tween = create_tween()
	tilt_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tilt_tween.set_loops()
	tilt_tween.set_trans(Tween.TRANS_SINE)
	tilt_tween.set_ease(Tween.EASE_IN_OUT)

	tilt_tween.tween_property(self, "rotation", -tilt_rad, tilt_duration)
	tilt_tween.tween_property(self, "rotation", tilt_rad, tilt_duration * 2.0)
	tilt_tween.tween_property(self, "rotation", 0.0, tilt_duration)

func _stop_tilting() -> void:
	if tilt_tween and tilt_tween.is_valid():
		tilt_tween.kill()
		
	# Smoothly return rotation to zero when hidden
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 0.0, 0.25)
