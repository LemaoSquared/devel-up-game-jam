extends CanvasLayer

var effect_running: bool = false

const SLOW_TIME_SCALE: float = 0.25
const SLOW_MOTION_DURATION: float = 0.7

@onready var flash_rect: ColorRect = $FlashRect

func _ready() -> void:
	add_to_group("camera_effects")

	flash_rect.modulate.a = 0.0
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func activate_camera_effect() -> void:
	if effect_running:
		return
	effect_running = true
	await flash_in()
	Engine.time_scale = SLOW_TIME_SCALE
	transform_all_items()
	await flash_out()
	await get_tree().create_timer(
		SLOW_MOTION_DURATION,
		true,
		false,
		true
	).timeout

	Engine.time_scale = 1.0
	effect_running = false


func transform_all_items() -> void:
	var targets := get_tree().get_nodes_in_group("camera_targets")
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.has_method("transform_to_polaroid"):
			target.transform_to_polaroid()


func flash_in() -> void:
	flash_rect.modulate.a = 0.0
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		flash_rect,
		"modulate:a",
		1.0,
		0.08
	)

	await tween.finished


func flash_out() -> void:
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		flash_rect,
		"modulate:a",
		0.0,
		0.3
	)

	await tween.finished
