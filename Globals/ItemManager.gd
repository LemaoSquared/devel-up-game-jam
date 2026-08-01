extends Node

@export var cat_treat: PackedScene = preload("res://Menus/item_cat_treat.tscn")
@export var yarn: PackedScene = preload("res://Menus/item_yarn.tscn")
@export var shoes: PackedScene = preload("res://Menus/item_shoes.tscn")
@export var sack: PackedScene = preload("res://Menus/item_sack.tscn")


@export var min_spawn_distance: float = 64.0
@export var max_placement_attempts: int = 30

enum SpawnType { RANDOM, GRID } #How the Item Spawn
enum SpawnAnimation { POP_SCALE, DROP_IN } #Animation of Item Spawning
enum Item{
	TREAT,
	YARN,
	GARBAGE,
	CAMERA,
	SHOES,
	SARDINE,
	RAT,
	SACK
}
@export_group("Animation Settings")
@export var spawn_animation: SpawnAnimation = SpawnAnimation.POP_SCALE
@export var drop_start_height: float = 100.0
@export var drop_duration: float = 0.5

@export_group("Spawn Settings")
@export var spawn_type: SpawnType = SpawnType.GRID
@export var pattern_columns: int = 12
@export var pattern_rows: int = 12
@export var enable_drop_wave: bool = true
@export var spawn_count: int = 10



var time_duration_perBatch: float = 6.0   # minimum total time this batch must occupy
var spawned_objects: Array[Node] = []
var wave_one_objects: Array[Node] = []
var drop_wave_triggered: bool = false
var batch_start_time: float = 0.0                 
var current_area: Control
var current_parent: Node
var current_pattern
var area

func _ready() -> void:
	current_pattern = 1
	pass


func spawn_random_pop_in_rect(obj_type, count: int = -1, parent: Node = null) -> void:
	var target_parent = parent if parent else get_tree().current_scene
	var final_count = count if count >= 0 else spawn_count

	current_area = area
	current_parent = target_parent
	wave_one_objects.clear()
	drop_wave_triggered = false
	batch_start_time = Time.get_ticks_msec() / 1000.0   # record batch start, in seconds
	
	match spawn_type:
		SpawnType.RANDOM:
			pass
		SpawnType.GRID:
			_spawn_grid(area, final_count, target_parent,obj_type)


		
func _spawn_drop_grid(obj_type,count: int=-1, target_parent: Node=null) -> void:
	var cell_size = Vector2(area.size.x / pattern_columns, area.size.y / pattern_rows)
	var anchor_y = area.global_position.y - drop_start_height

	var row_pool: Array[int] = []
	for r in range(pattern_rows):
		row_pool.append(r)
	row_pool.shuffle()

	for index in range(count):
		var c = index % pattern_columns
		if index > 0 and index % pattern_rows == 0:
			row_pool.shuffle()
		var r = row_pool[index % pattern_rows]

		var cell_origin = area.global_position + Vector2(c * cell_size.x, r * cell_size.y)
		var pos = cell_origin + cell_size / 2.0
		var anchor_pos = Vector2(pos.x, anchor_y)

		#THIS FUNCTION IS FOR DROP ITEMS ONLY
		var obj
		match obj_type:
			Item.YARN: obj = yarn.instantiate()
			Item.SHOES: obj = shoes.instantiate()

		target_parent.add_child(obj)
		obj.popped_out.connect(_on_object_popped_out)
		spawned_objects.append(obj)

		if obj.has_method("spawn_drop_and_hang"):
			obj.spawn_drop_and_hang(pos, anchor_pos, index * 0.05)
		else:
			push_warning("ItemManager: yarn_scene has no spawn_drop_and_hang method.")


func _spawn_grid(area: Control, count: int, target_parent: Node,obj_type) -> void:
	var cell_size = Vector2(area.size.x / pattern_columns, area.size.y / pattern_rows)
	var total_cells = pattern_columns * pattern_rows
	var spawn_total = min(count, total_cells)

	var row_pool: Array[int] = []
	for r in range(pattern_rows):
		row_pool.append(r)
	row_pool.shuffle()

	for index in range(spawn_total):
		var c = index % pattern_columns
		if index > 0 and index % pattern_rows == 0:
			row_pool.shuffle()
		var r = row_pool[index % pattern_rows]

		var cell_origin = area.global_position + Vector2(c * cell_size.x, r * cell_size.y)
		var pos = cell_origin + cell_size / 2.0
		_instantiate_object(pos, target_parent, index,obj_type)


func _instantiate_object(pos: Vector2, target_parent: Node, delay_index: int, obj_type) -> void:
	#THIS FUNCTION IS FOR POP ITEMS ONLY
	# DROP ITEMS ARE ON _SPAWN_DROP_GRID FUNCTION
	var obj
	match obj_type:
		Item.TREAT: obj = cat_treat.instantiate()
		Item.GARBAGE: obj = cat_treat.instantiate()
		Item.CAMERA: obj = cat_treat.instantiate()
		Item.SARDINE: obj = cat_treat.instantiate()
		Item.RAT: obj = cat_treat.instantiate()
		Item.SACK: obj = sack.instantiate()
	target_parent.add_child(obj)
	obj.popped_out.connect(_on_object_popped_out)
	spawned_objects.append(obj)
	wave_one_objects.append(obj)

	match spawn_animation:
		SpawnAnimation.POP_SCALE:
			_animate_pop_scale(obj, pos, delay_index)
		SpawnAnimation.DROP_IN:
			_animate_drop_in(obj, pos, delay_index)


func _animate_pop_scale(obj: Node, pos: Vector2, delay_index: int) -> void:
	obj.global_position = pos
	obj.scale = Vector2.ZERO

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(obj, "scale", Vector2.ONE, 0.4).set_delay(delay_index * 0.05)


func _animate_drop_in(obj: Node, pos: Vector2, delay_index: int) -> void:
	var anchor_y = current_area.global_position.y - drop_start_height if current_area else pos.y - drop_start_height
	var anchor_pos = Vector2(pos.x, anchor_y)

	if obj.has_method("spawn_drop_and_hang"):
		obj.spawn_drop_and_hang(pos, anchor_pos, delay_index * 0.05)
	else:
		obj.global_position = anchor_pos
		obj.scale = Vector2.ONE
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(obj, "global_position", pos, drop_duration).set_delay(delay_index * 0.05)


func _find_valid_position(existing: Array[Vector2]) -> Variant:
	for attempt in range(max_placement_attempts):
		var rand_x = randf_range(0, area.size.x)
		var rand_y = randf_range(0, area.size.y)
		var candidate = area.global_position + Vector2(rand_x, rand_y)
		var far_enough = true
		for p in existing:
			if candidate.distance_to(p) < min_spawn_distance:
				far_enough = false
				break
		if far_enough:
			return candidate
	return null


func clear_objects() -> void:
	for obj in spawned_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	spawned_objects.clear()
	wave_one_objects.clear()


func _on_object_popped_out(obj: Node) -> void:
	spawned_objects.erase(obj)
	wave_one_objects.erase(obj)

	# If you still want the drop wave sub-step to trigger inside the 6 seconds:
	if enable_drop_wave and not drop_wave_triggered and wave_one_objects.is_empty():
		drop_wave_triggered = true
		
		var elapsed = (Time.get_ticks_msec() / 1000.0) - batch_start_time
		var remaining = max(0.0, time_duration_perBatch - elapsed)

		# Optional: Spawn sub-wave if there is time left in the current 6 seconds
		if remaining > 0.0:
			# You can handle mid-wave sub-spawns here if your pattern rules require it.
			pass

func _on_wave_timeout() -> void:
	current_pattern += 1
	play_pattern(current_pattern)
	
func play_pattern(number:int):
	print("PLAYING PATTERN " + str(current_pattern))
	# Count of Items in a Wave
	# [Treat, Yarn, Garbage, Camera, Shoe, Sardine, Sack, Toy]
	var item_count = []
	match number:
		1: item_count = [10,0,0,0,0,0,0,10]
		2: item_count = [0,10,0,0,0,0,0,0]
		3: item_count = [5,5,0,0,0,0,0,0]
		4: item_count = [10,0,0,0,10,0,0,0]
		
	for i in range(item_count.size()):
		var count = item_count[i]
		if count > 0:
			match i:
				0: spawn_random_pop_in_rect(Item.TREAT,count, current_parent) #Treats will Pop Spawn
				1: _spawn_drop_grid(Item.YARN,count,current_parent) #Yarns will Drop Spawn
				4: _spawn_drop_grid(Item.SHOES,count,current_parent) #Shoes will Drop Spawn
				7: spawn_random_pop_in_rect(Item.SACK,count, current_parent) #Sack will Pop Spawn

# --- NEW INDEPENDENT TIMER SETUP ---
	# Disconnect old timers by using a clean scene tree timer
	var wave_timer = get_tree().create_timer(time_duration_perBatch, true)
	wave_timer.timeout.connect(_on_wave_timeout)
