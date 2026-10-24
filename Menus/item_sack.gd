extends Node2D

signal popped_out(obj: Node, was_clicked: bool)
@onready var hold_bar: ProgressBar = $HoldBar

const SACK = preload("uid://844bkgax2wrd")
const SACK_OPEN = preload("uid://d3nlvoeoqtbyp")
const SACK_PARTICLE = preload("uid://bncb0rx7oecq0")
const FLOATING_LABEL = preload("uid://cu8xcr7igstbj")

# Preload Cat Treat Scene for spawning on burst
@export var treat_scene: PackedScene = preload("uid://dopbjbokm0whf")

# POLAROID
@export var polaroid_scene: PackedScene = preload("res://Menus/item_polaroid.tscn")
@export var polaroid_texture: Texture2D

@export_group("Hold Settings")
@export var hold_duration_required: float = 0.5
@export var treat_spawn_count: int = 5
@export var treat_burst_radius: float = 120.0
@export var success_points: int = 25

@export_group("Sack Regions")
@export var sack_regions: Array[Rect2] = [
	Rect2(0.0, 104.0, 75.856, 56.829),
	Rect2(80.0, 104.0, 75.856, 56.829),
	Rect2(160.0, 104.0, 72.0, 56.829),
	Rect2(240.0, 104.0, 72.0, 56.829),
	Rect2(320.0, 112.0, 72.0, 56.829)
]

@onready var sack: Area2D = $Sack
@onready var sack_sprite: Sprite2D = $Sack/Sprite2D
@onready var fish_particles: GPUParticles2D = $FishParticles
@onready var sack_shadow: Sprite2D = $Sack/Sprite2D2

const Duration: float = 12.0

var is_popping: bool = false
var is_transforming: bool = false
var is_holding: bool = false

var hold_timer: float = 0.0
var active_touch_index: int = -1

var tilt_tween: Tween
var shake_tween: Tween
var rewind_tween: Tween

const BASE_SCALE: float = 0.75
const HOLD_SCALE: float = 1.0

func _ready() -> void:
	add_to_group("camera_targets")

	sack.input_pickable = false
	scale = Vector2(BASE_SCALE, BASE_SCALE) # Make it initially smaller

	if hold_bar:
		hold_bar.visible = false
		hold_bar.max_value = 100.0
		hold_bar.value = 0.0

	sack_sprite.region_enabled = true
	sack_sprite.region_filter_clip_enabled = true
	
	if sack_shadow:
		sack_shadow.region_enabled = true
		sack_shadow.region_filter_clip_enabled = true

	update_sack_sprite_by_progress(0.0)

	var timer = get_tree().create_timer(Duration, false)
	timer.timeout.connect(_on_duration_expired)

	start_tilting_loop()

func _process(delta: float) -> void:
	if not is_holding or is_popping:
		return

	hold_timer += delta
	var progress = clamp(hold_timer / hold_duration_required, 0.0, 1.0)
	
	# Update HoldBar progress value (0 to 100)
	if hold_bar:
		hold_bar.value = progress * 100.0

	# Progressively scale up from the smaller base size while holding
	var target_scale = lerp(BASE_SCALE, HOLD_SCALE, progress)
	scale = Vector2(target_scale, target_scale)

	# Update sprite regions based on hold progress
	update_sack_sprite_by_progress(progress)

	if hold_timer >= hold_duration_required:
		_on_hold_completed()

# --- Touch & Mouse Hold Handling (Mobile Touch Supportive) ---
func _input(event: InputEvent) -> void:
	if is_popping:
		return

	# Mobile Touch Press / Release
	if event is InputEventScreenTouch:
		if event.pressed:
			if global_position.distance_to(event.position) < 64.0 and not is_holding:
				active_touch_index = event.index
				_start_holding()
		elif event.index == active_touch_index:
			_release_holding()

	# Mobile Touch Drag (cancel if dragged off item radius)
	elif event is InputEventScreenDrag and event.index == active_touch_index:
		if global_position.distance_to(event.position) > 80.0:
			_release_holding()

	# Mouse Press / Release (for desktop testing)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if global_position.distance_to(event.position) < 64.0 and not is_holding:
				active_touch_index = -999 # Special index for mouse
				_start_holding()
		elif active_touch_index == -999:
			_release_holding()

func _start_holding() -> void:
	is_holding = true
	hold_timer = 0.0

	if hold_bar:
		hold_bar.visible = true
		hold_bar.value = 0.0

	if rewind_tween and rewind_tween.is_valid():
		rewind_tween.kill()

	AudioManager.play_sound(SACK)
	_start_erratic_shake()

func _release_holding() -> void:
	if not is_holding or is_popping:
		return

	is_holding = false
	active_touch_index = -1

	if hold_bar:
		hold_bar.visible = false

	_stop_erratic_shake()
	_rewind_holding_progress()

func _start_erratic_shake() -> void:
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()

	shake_tween = create_tween()
	shake_tween.set_loops()
	
	# Rapid, unpredictable local offsets
	shake_tween.tween_property(sack_sprite, "position", Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0)), 0.03)
	shake_tween.tween_property(sack_sprite, "position", Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0)), 0.03)
	shake_tween.tween_property(sack_sprite, "position", Vector2.ZERO, 0.03)

func _stop_erratic_shake() -> void:
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
	sack_sprite.position = Vector2.ZERO

func _rewind_holding_progress() -> void:
	if rewind_tween and rewind_tween.is_valid():
		rewind_tween.kill()

	var start_progress = hold_timer / hold_duration_required
	rewind_tween = create_tween()
	rewind_tween.set_parallel(true)
	rewind_tween.set_trans(Tween.TRANS_QUAD)
	rewind_tween.set_ease(Tween.EASE_OUT)

	# Reset scale back to the smaller base size and rewind progress
	rewind_tween.tween_property(self, "scale", Vector2(BASE_SCALE, BASE_SCALE), 0.25)
	rewind_tween.tween_method(update_sack_sprite_by_progress, start_progress, 0.0, 0.25)
	
	rewind_tween.finished.connect(func(): hold_timer = 0.0)

func update_sack_sprite_by_progress(progress: float) -> void:
	if sack_regions.size() == 0:
		return
		
	var region_index = int(progress * (sack_regions.size() - 1))
	region_index = clamp(region_index, 0, sack_regions.size() - 1)

	sack_sprite.region_rect = sack_regions[region_index]
	if sack_shadow:
		sack_shadow.region_rect = sack_regions[region_index]

func _on_hold_completed() -> void:
	is_popping = true
	is_holding = false
	active_touch_index = -1

	if hold_bar:
		hold_bar.visible = false

	_stop_erratic_shake()
	sack.input_pickable = false

	AudioManager.play_sound(SACK_OPEN)
	ParticleManager.spawn_particle(SACK_PARTICLE, global_position)

	# --- AWARD POINTS AND SPAWN FLOATING SCORE LABEL ---
	ScoreManager.add_points(success_points)
	if FLOATING_LABEL:
		var label = FLOATING_LABEL.instantiate()
		get_tree().current_scene.add_child(label)
		if label.has_method("setup"):
			label.setup(success_points, global_position)
	# ---------------------------------------------------

	# Burst Cat Treats immediately around proximity
	_burst_cat_treats()

	# --- BRIEF WHITE FLASH & SHRINK TO ZERO ---
	popped_out.emit(self, true)

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_parallel(true)
	
	# Bright white flash tint
	tween.tween_property(self, "modulate", Color(4.0, 4.0, 4.0, 1.0), 0.08)
	tween.tween_property(self, "scale", scale * 1.25, 0.08) # slight pop outward

	var shrink_tween = create_tween()
	shrink_tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	shrink_tween.set_parallel(true)
	shrink_tween.set_trans(Tween.TRANS_BACK)
	shrink_tween.set_ease(Tween.EASE_IN)
	
	shrink_tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_delay(0.08)
	shrink_tween.tween_property(self, "modulate:a", 0.0, 0.2).set_delay(0.08)
	shrink_tween.chain().tween_callback(queue_free)

func _burst_cat_treats() -> void:
	if treat_scene == null:
		return

	var parent_node = get_parent()
	if parent_node == null:
		return

	var angle_step = TAU / float(treat_spawn_count)

	for i in range(treat_spawn_count):
		var treat_instance = treat_scene.instantiate() as Node2D
		if treat_instance == null:
			continue

		parent_node.add_child(treat_instance)
		treat_instance.global_position = global_position

		# Determine target position on the radial circle
		var angle = angle_step * i + randf_range(-0.15, 0.15)
		var offset = Vector2(cos(angle), sin(angle)) * randf_range(treat_burst_radius * 0.7, treat_burst_radius)
		var target_pos = global_position + offset

		# Animate treats launching outwards from the sack
		var burst_tween = treat_instance.create_tween()
		burst_tween.set_trans(Tween.TRANS_BACK)
		burst_tween.set_ease(Tween.EASE_OUT)
		burst_tween.set_parallel(true)

		burst_tween.tween_property(treat_instance, "global_position", target_pos, 0.4)
		burst_tween.tween_property(treat_instance, "scale", Vector2.ONE, 0.3).from(Vector2.ZERO)

		# Register with ItemManager if active
		if ItemManager.has_method("register_spawned_object"):
			ItemManager.register_spawned_object(treat_instance, ItemManager.Item.TREAT)

func _on_duration_expired() -> void:
	if is_popping:
		return
	_execute_pop_out(false)

func _execute_pop_out(was_clicked: bool = false) -> void:
	is_popping = true
	sack.input_pickable = false

	if hold_bar:
		hold_bar.visible = false

	_stop_erratic_shake()

	popped_out.emit(self, was_clicked)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)

func start_tilting_loop() -> void:
	var tilt_angle: float = deg_to_rad(8.0)
	var duration: float = 0.8

	tilt_tween = create_tween()
	tilt_tween.set_loops()
	tilt_tween.set_trans(Tween.TRANS_SINE)
	tilt_tween.set_ease(Tween.EASE_IN_OUT)

	tilt_tween.tween_property(self, "rotation", -tilt_angle, duration)
	tilt_tween.tween_property(self, "rotation", tilt_angle, duration * 2.0)
	tilt_tween.tween_property(self, "rotation", 0.0, duration)

func transform_to_polaroid() -> void:
	if is_popping or is_transforming:
		return
	is_transforming = true
	is_popping = true
	sack.input_pickable = false

	if hold_bar:
		hold_bar.visible = false

	_stop_erratic_shake()

	var polaroid := polaroid_scene.instantiate() as Node2D
	get_parent().add_child(polaroid)
	polaroid.global_position = global_position
	polaroid.global_rotation = global_rotation
	polaroid.scale = scale

	var photo_sprite := polaroid.get_node_or_null("Polaroid/Sprite2D") as Sprite2D
	if photo_sprite != null and polaroid_texture != null:
		photo_sprite.texture = polaroid_texture

	polaroid.set_meta("item_type", 9)
	polaroid.set("is_polaroid", true)

	if ItemManager.has_method("register_spawned_object"):
		ItemManager.register_spawned_object(polaroid, 9)

	if polaroid.has_method("appear"):
		polaroid.appear()
	
	popped_out.emit(self, true)
	queue_free()

func pop_out(was_clicked: bool = false) -> void:
	_execute_pop_out(was_clicked)
