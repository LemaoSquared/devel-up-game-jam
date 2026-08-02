extends Node

@export var cat_treat: PackedScene = preload("res://Menus/item_cat_treat.tscn")
@export var yarn: PackedScene = preload("res://Menus/item_yarn.tscn")
@export var shoes: PackedScene = preload("res://Menus/item_shoes.tscn")
@export var sack: PackedScene = preload("res://Menus/item_sack.tscn")
@export var sardine: PackedScene = preload("res://Menus/Can_Food.tscn")
@export var garbage: PackedScene = preload("res://Menus/item_garbage.tscn")
@export var camera: PackedScene = preload("res://Menus/item_camera.tscn")
@export var rat: PackedScene = preload("res://Menus/toy_mouse.tscn")

@export var min_spawn_distance: float = 64.0
@export var max_placement_attempts: int = 30
enum Spawner {BOTTOM_RIGHT,BOTTOM_LEFT,BOTH}
var rat_corner: Spawner = Spawner.BOTTOM_RIGHT

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
@export var pattern_rows: int = 4
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
	current_parent = get_tree().current_scene
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


		
func _spawn_drop_grid(obj_type, count: int = -1, parent: Node = null) -> void:
	var target_parent: Node = parent if parent != null else get_tree().current_scene

	if target_parent == null:
		push_error("ItemManager: No valid parent was found for drop items.")
		return

	if area == null:
		push_error("ItemManager: Spawn area has not been assigned.")
		return

	var final_count: int = count if count >= 0 else spawn_count
	var cell_size = Vector2(
		area.size.x / pattern_columns,
		area.size.y / pattern_rows
	)
	var anchor_y = area.global_position.y - drop_start_height

	# 1. Calculate max safe limit based on total grid capacity
	var total_cells = pattern_columns * pattern_rows
	var spawn_total = min(final_count, total_cells)

	# 2. Build a flat pool of all grid coordinates
	var cell_pool: Array[Vector2i] = []
	for r in range(pattern_rows):
		for c in range(pattern_columns):
			cell_pool.append(Vector2i(c, r))
			
	# 3. Shuffle the grid pool for true randomization
	cell_pool.shuffle()

	# 4. Pull unique coordinates from the shuffled grid pool
	for index in range(spawn_total):
		var cell = cell_pool[index]
		var c = cell.x
		var r = cell.y

		var cell_origin = area.global_position + Vector2(
			c * cell_size.x,
			r * cell_size.y
		)

		var pos = cell_origin + cell_size / 2.0
		
		# Optional: Add organic random offsets here if you want them slightly off-center:
		# pos.x += randi_range(-15, 15)
		# pos.y += randi_range(-15, 15)
		
		var anchor_pos = Vector2(pos.x, anchor_y)
		var obj: Node
		
		match obj_type:
			Item.YARN:
				obj = yarn.instantiate()
			Item.SHOES:
				obj = shoes.instantiate()
			_:
				push_warning("ItemManager: Unsupported drop item: " + str(obj_type))
				continue
				
		target_parent.add_child(obj)

		if obj.has_signal("popped_out"):
			obj.popped_out.connect(_on_object_popped_out)

		spawned_objects.append(obj)
		wave_one_objects.append(obj)

		if obj.has_method("spawn_drop_and_hang"):
			obj.spawn_drop_and_hang(
				pos,
				anchor_pos,
				index * 0.05
			)
		else:
			push_warning(
				"ItemManager: Drop item has no spawn_drop_and_hang method."
			)

func _spawn_grid(area: Control, count: int, target_parent: Node, obj_type) -> void:
	var cell_size = Vector2(area.size.x / pattern_columns, area.size.y / pattern_rows)
	if obj_type == Item.RAT:
		_spawn_rats(count, cell_size, target_parent)
		return
	
	var total_cells = pattern_columns * pattern_rows
	var spawn_total = min(count, total_cells)

	# 1. Build a pool containing all grid cell positions
	var cell_pool: Array[Vector2i] = []
	for r in range(pattern_rows):
		for c in range(pattern_columns):
			cell_pool.append(Vector2i(c, r))
			
	# 2. Shuffle the entire pool once to randomize cell selection
	cell_pool.shuffle()

	# 3. Pull from the shuffled pool sequentially
	for index in range(spawn_total):
		var cell = cell_pool[index]
		var c = cell.x
		var r = cell.y

		# Calculate the core point centered inside the chosen cell
		var cell_origin = area.global_position + Vector2(c * cell_size.x, r * cell_size.y)
		var pos = cell_origin + cell_size / 2.0
		
		# Apply a slight organic coordinate offset so it doesn't look perfectly aligned
		pos.x += randi_range(-20, 20)
		pos.y += randi_range(-20, 20)
		
		_instantiate_object(pos, target_parent, index, obj_type)

func _spawn_rats(count: int, cell_size: Vector2, target_parent: Node) -> void:
	if count <= 0:
		return
	var left_count = int(ceil(count / 2.0))
	var right_count = count - left_count

	left_count = min(left_count, pattern_columns)
	right_count = min(right_count, pattern_columns)

	for i in range(left_count):
		var col = min(i, pattern_columns - 1)
		_spawn_rat_at(Spawner.BOTTOM_LEFT, cell_size, target_parent, col, i)

	for i in range(right_count):
		var col = max(pattern_columns - 1 - i, 0)
		_spawn_rat_at(Spawner.BOTTOM_RIGHT, cell_size, target_parent, col, i)
		
func _instantiate_object(pos: Vector2, target_parent: Node, delay_index: int, obj_type) -> void:
	#THIS FUNCTION IS FOR POP ITEMS ONLY
	# DROP ITEMS ARE ON _SPAWN_DROP_GRID FUNCTION
	var obj
	match obj_type:
		Item.TREAT: obj = cat_treat.instantiate()
		Item.GARBAGE: obj = garbage.instantiate()
		Item.CAMERA: obj = camera.instantiate()
		Item.SARDINE: obj = sardine.instantiate()
		Item.RAT: obj = rat.instantiate()
		Item.SACK: obj = sack.instantiate()
	target_parent.add_child(obj)
	
	#Camera signal
	if obj.has_signal("camera_activated"):
		var camera_effects := get_tree().get_first_node_in_group(
		"camera_effects"
	)

		if camera_effects != null:
			obj.camera_activated.connect(
			camera_effects.activate_camera_effect
		)
		else:
			push_warning(
		"ItemManager: CameraEffects node was not found."
	)
	
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
	

func register_spawned_object(obj: Node) -> void:
	if obj == null:
		return

	if obj.has_signal("popped_out"):
		obj.popped_out.connect(_on_object_popped_out)

	spawned_objects.append(obj)
	
func _spawn_rat_at(corner: Spawner, cell_size: Vector2, target_parent: Node, col: int, delay_index: int) -> void:
	var r: int = pattern_rows - 1
	var dir: int
	var target_end_x: float

	match corner:
		Spawner.BOTTOM_LEFT:
			dir = 1
			target_end_x = area.global_position.x + area.size.x
		Spawner.BOTTOM_RIGHT:
			dir = -1
			target_end_x = area.global_position.x

	var cell_origin = area.global_position + Vector2(col * cell_size.x, r * cell_size.y)
	var pos = cell_origin + cell_size / 2.0

	var obj = rat.instantiate()
	target_parent.add_child(obj)
	obj.popped_out.connect(_on_object_popped_out)
	spawned_objects.append(obj)
	wave_one_objects.append(obj)
	obj.set_direction(dir, target_end_x)

	match spawn_animation:
		SpawnAnimation.POP_SCALE:
			_animate_pop_scale(obj, pos, delay_index)
		SpawnAnimation.DROP_IN:
			_animate_drop_in(obj, pos, delay_index)
	
func play_pattern(number:int):
	current_parent = get_tree().current_scene 
	print("PLAYING PATTERN " + str(current_pattern))
	# Count of Items in a Wave
	# [Treat, Yarn, Garbage, Camera, Shoe, Sardine, Rat, Sack]
	var item_count = []
	match number:
		1: item_count = [0,0,0,1,0,0,0,10]
		2: item_count = [0,10,0,1,0,0,0,0]
		3: item_count = [0,0,0,1,0,0,1,0]
		4: item_count = [10,0,0,0,5,0,1,0]
		5: item_count = [0,0,0,0,0,5,3,0]
		
	for i in range(item_count.size()):
		var count = item_count[i]
		if count > 0:
			match i:
				0: spawn_random_pop_in_rect(Item.TREAT,count, current_parent) #Treats will Pop Spawn
				1: _spawn_drop_grid(Item.YARN,count,current_parent) #Yarns will Drop Spawn
				2: spawn_random_pop_in_rect(Item.GARBAGE,count, current_parent) #Garbage will Pop Spawn
				3: spawn_random_pop_in_rect(Item.CAMERA,count, current_parent) # Camera
				4: _spawn_drop_grid(Item.SHOES,count,current_parent) #Shoes will Drop Spawn
				5: spawn_random_pop_in_rect(Item.SARDINE,count, current_parent) #Treats will Pop Spawn
				6: spawn_random_pop_in_rect(Item.RAT,count, current_parent)
				7: spawn_random_pop_in_rect(Item.SACK,count, current_parent) #Sack will Pop Spawn

# --- NEW INDEPENDENT TIMER SETUP ---
	# Disconnect old timers by using a clean scene tree timer
	var wave_timer = get_tree().create_timer(time_duration_perBatch, true)
	wave_timer.timeout.connect(_on_wave_timeout)
