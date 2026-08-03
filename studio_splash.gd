extends Control

@export_file("*.tscn") var next_scene_path: String = "res://Menus/Main.tscn"

@export var fade_in_duration: float = 1.2
@export var logo_display_duration: float = 1.5
@export var fade_out_duration: float = 1.2

@onready var logo_container: Control = $CenterContainer
@onready var background: ColorRect = $ColorRect

var is_changing_scene: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Start completely invisible.
	logo_container.modulate.a = 0.0

	play_splash_animation()


func play_splash_animation() -> void:
	var tween := create_tween()

	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Smooth fade in.
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		logo_container,
		"modulate:a",
		1.0,
		fade_in_duration
	)

	# Keep the logo visible.
	tween.tween_interval(logo_display_duration)

	# Smooth fade out.
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		logo_container,
		"modulate:a",
		0.0,
		fade_out_duration
	)

	await tween.finished
	await warm_up_shaders()
	change_to_main_scene()


func change_to_main_scene() -> void:
	if is_changing_scene:
		return

	is_changing_scene = true

	var error := get_tree().change_scene_to_file(next_scene_path)

	if error != OK:
		push_error(
			"Failed to load scene: " + next_scene_path
		)


const CAN_FOOD = preload("uid://c5taqxs74p4e5")
const ITEM_CAMERA = preload("uid://ixb0ggojn7t0")
const ITEM_CAT_TREAT = preload("uid://dopbjbokm0whf")
const ITEM_GARBAGE = preload("uid://brji5cukaog0e")
const ITEM_POLAROID = preload("uid://cseyvipe7oolj")
const ITEM_SACK = preload("uid://jwsabqug58lp")
const ITEM_SHOES = preload("uid://ctjkipwa5ie5d")
const ITEM_YARN = preload("uid://cgbbkrcpsj0dq")
const SARDINES = preload("uid://cxer0bggywph6")
const TOY_MOUSE = preload("uid://bp1cyo6ql5jf2")
const STORY_BACKGROUND = preload("uid://bdih0pbvhnhv8")
const MAIN = preload("uid://fldj3nccgla6")
const FINAL_CUTSCENE = preload("uid://bqfwjyhkbhn82")
const GAME_OVER_SCREEN = preload("uid://dh364flg18d2j")

func warm_up_shaders() -> void:
	print("warming up")
	# Group all preloaded scenes into an array to warm up
	var item_scenes: Array[PackedScene] = [
		CAN_FOOD,
		ITEM_CAMERA,
		ITEM_CAT_TREAT,
		ITEM_GARBAGE,
		ITEM_POLAROID,
		ITEM_SACK,
		ITEM_SHOES,
		ITEM_YARN,
		SARDINES,
		TOY_MOUSE,
		STORY_BACKGROUND,
		MAIN,
		FINAL_CUTSCENE,
		GAME_OVER_SCREEN
	]
	
	# Create an off-screen container (keep visible = true so WebGL forces compile!)
	var warmup_container = Node2D.new()
	warmup_container.position = Vector2(-9999, -9999)
	get_tree().current_scene.add_child(warmup_container)
	
	for scene in item_scenes:
		if scene:
			var dummy = scene.instantiate()
			warmup_container.add_child(dummy)
			
	# Wait 2 process frames so WebGL has enough render passes to compile shaders
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Safely clear the dummy nodes now that their materials/shaders live in GPU memory
	warmup_container.queue_free()
