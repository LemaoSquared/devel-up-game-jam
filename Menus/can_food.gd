extends Node2D
signal popped_out(obj, was_clicked: bool)

# SARDINES
@export var sardine_scene: PackedScene = preload("res://Menus/Sardines.tscn")
# POLAROID
@export var polaroid_scene: PackedScene = preload("res://Menus/item_polaroid.tscn")
@export var polaroid_texture: Texture2D

@onready var click_area: Area2D = $Can_Food
@onready var anim_sprite: AnimatedSprite2D = $Can_Food/Sprite2D
@onready var anim_shadow: AnimatedSprite2D = $Can_Food/Sprite2D2
@onready var gift: AnimatedSprite2D = $GiftAnimation

var click_count: int = 0
const MAX_CLICKS: int = 3
@export var lifetime: float = 6.0
var is_finished: bool = false
var sardines_remaining: int = 0

const CAN_OPEN = preload("uid://dei326f80lxo0")
const CAN = preload("uid://hufov8jcs0i2")

func _ready() -> void:
	gift.visible = false
	add_to_group("camera_targets")
	click_area.input_pickable = false
	
	anim_sprite.animation = "Can_Foood"
	anim_sprite.frame = 0
	anim_sprite.stop()
	
	if anim_shadow:
		anim_shadow.animation = anim_sprite.animation
		anim_shadow.frame = 0
		anim_shadow.stop()

	# Changed 2nd argument from true to false so it pauses with the game
	var life_timer = get_tree().create_timer(lifetime, false)
	life_timer.timeout.connect(_on_lifetime_expired)

# --- Multi-touch & Mouse Input Handling ---
func _input(event: InputEvent) -> void:
	if is_finished or click_count >= MAX_CLICKS:
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
		if global_position.distance_to(click_pos) < 64.0: # Adjust radius if needed
			_advance_frame()

func _advance_frame() -> void:
	if is_finished or click_count >= MAX_CLICKS:
		return
	click_count += 1
	AudioManager.play_sound(CAN)
	
	anim_sprite.frame = click_count
	if anim_shadow:
		anim_shadow.frame = click_count
		
	_click_feedback()
	if click_count >= MAX_CLICKS:
		AudioManager.play_sound(CAN_OPEN)
		_spawn_sardines()

func _click_feedback() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _spawn_sardines() -> void:
	is_finished = true
	click_area.input_pickable = false
	var parent := get_parent()
	if parent == null:
		push_error("Can_Food has no valid parent.")
		return
		
	# First, tell ItemManager that the CAN ITSELF was completed successfully,
	# so it gets removed from the wave tracking before we add sub-sardines.
	popped_out.emit(self, true)

	var count: int = 3
	for i in range(count):
		var sardine := sardine_scene.instantiate() as SardineItem
		if sardine == null:
			push_error("Sardines.tscn must use sardines.gd on its root.")
			continue
		sardine.sardine_index = i
		sardine.total_sardines = count
		sardine.spawn_delay = i * 0.07
		parent.add_child(sardine)
		sardine.global_position = anim_sprite.global_position
		ItemManager.register_spawned_object(sardine, ItemManager.Item.SARDINE)
		sardine.launch()

	_pop_opened_can()

func _pop_opened_can() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_callback(queue_free)

func transform_to_polaroid() -> void:
	var polaroid := polaroid_scene.instantiate() as Node2D
	get_parent().add_child(polaroid)

	polaroid.global_position = global_position
	polaroid.global_rotation = global_rotation
	polaroid.scale = scale

	var photo_sprite := polaroid.get_node_or_null("Polaroid/Sprite2D") as Sprite2D
	if photo_sprite != null and polaroid_texture != null:
		photo_sprite.texture = polaroid_texture

	# Guarantee Polaroid Data & Connect Signal
	polaroid.set_meta("item_type", 9)
	polaroid.set("is_polaroid", true)

	if ItemManager.has_method("register_spawned_object"):
		ItemManager.register_spawned_object(polaroid, 9) # 9 is Item.POLAROID

	if polaroid.has_method("appear"):
		polaroid.appear()

	popped_out.emit(self, true)
	queue_free()

func _on_lifetime_expired() -> void:
	if is_finished:
		return
	is_finished = true
	click_area.input_pickable = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.finished.connect(func():
		popped_out.emit(self, false)
		queue_free()
	)
