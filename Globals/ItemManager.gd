extends Node

signal item_collected(item_type: int)

@export var cat_treat: PackedScene = preload("res://Menus/item_cat_treat.tscn")
@export var yarn: PackedScene = preload("res://Menus/item_yarn.tscn")
@export var shoes: PackedScene = preload("res://Menus/item_shoes.tscn")
@export var sack: PackedScene = preload("res://Menus/item_sack.tscn")
@export var sardine: PackedScene = preload("res://Menus/Can_Food.tscn")
@export var garbage: PackedScene = preload("res://Menus/item_garbage.tscn")
@export var camera: PackedScene = preload("res://Menus/item_camera.tscn")
@export var rat: PackedScene = preload("res://Menus/toy_mouse.tscn")
@export var regen: PackedScene = preload("res://Menus/item_regen.tscn")
@export var polaroid: PackedScene = preload("res://Menus/item_polaroid.tscn")
const NEXT_WAVE = preload("uid://dnvvary85k2lr")

@export var min_spawn_distance: float = 64.0
@export var max_placement_attempts: int = 30
enum Spawner { BOTTOM_RIGHT, BOTTOM_LEFT, BOTH }
var rat_corner: Spawner = Spawner.BOTTOM_RIGHT

enum SpawnType { RANDOM, GRID }
enum SpawnAnimation { POP_SCALE, DROP_IN }
enum Item {
	TREAT,
	YARN,
	GARBAGE,
	CAMERA,
	SHOES,
	SARDINE,
	RAT,
	SACK,
	REGEN,
	POLAROID
}

@export_group("Animation Settings")
@export var spawn_animation: SpawnAnimation = SpawnAnimation.POP_SCALE
@export var drop_start_height: float = 100.0
@export var drop_duration: float = 0.5

@export_group("Spawn Settings")
@export var spawn_type: SpawnType = SpawnType.GRID
@export var pattern_columns: int = 15
@export var pattern_rows: int = 5
@export var enable_drop_wave: bool = true
@export var spawn_count: int = 10

var time_duration_perBatch: float = 6.0
var spawned_objects: Array[Node] = []
var wave_one_objects: Array[Node] = []
var drop_wave_triggered: bool = false
var batch_start_time: float = 0.0					
var current_area: Control
var current_parent: Node
var scored_objects: Array[Node] = []
var area

# Game State & Wave Tracking
var is_game_over: bool = false
var active_wave_timer: SceneTreeTimer = null
var missed_items_in_current_wave: int = 0

# Pity System for HP Regen
var regen_pity_counter: int = 0

class WaveBatch:
	var has_missed_item: bool = false
	var is_finished: bool = false

var current_wave_batch: WaveBatch = null

# --- STORY MODE TRACKING ---
var current_pattern: int = 1

# --- ENDLESS MODE BATCH, BAG & SPEED SYSTEM ---
class BatchData:
	var batch_name: String
	var waves: Array = []

var is_endless: bool = false
var base_time_duration_perBatch: float = 6.0  
@export var batch_speed_step: float = 0.5     
@export var max_timer_reduction: float = 3.0  

var total_batches_played: int = 0
var current_wave_in_batch: int = 0
var current_batch_data: BatchData = null
var current_wave_queue: Array = []

# Guaranteed first batch
var beginner_batch: BatchData = null

# Pool of succeeding batches & runtime shuffle bag
var batch_pool: Array[BatchData] = []
var batch_bag: Array[BatchData] = []

# --- Shared Grid & Distance Tracking ---
var occupied_cells: Array[Vector2i] = []

func _ready() -> void:
	current_pattern = 1 + randi_range(0, 1)
	current_parent = get_tree().current_scene
	base_time_duration_perBatch = time_duration_perBatch
	_initialize_endless_batches()

func _exit_tree() -> void:
	clear_objects()

# Defines the beginner batch and succeeding modular batches focused on Yarns and Hazards
func _initialize_endless_batches() -> void:
	batch_pool.clear()

	# 1. GUARANTEED BEGINNER BATCH (Total Max Score: 75 pts | 15 pts/wave)
	beginner_batch = BatchData.new()
	beginner_batch.batch_name = "Beginner Warmup"
	beginner_batch.waves = [
		[15, 0, 0, 0, 0, 0, 0, 0, 0, 0], # Wave 1: 15 Treats (15 pts)
		[11, 2, 0, 0, 0, 0, 0, 0, 0, 0], # Wave 2: 11 Treats + 2 Yarns (15 pts)
		[9, 3, 3, 0, 0, 0, 0, 0, 0, 0],  # Wave 3: 9 Treats + 3 Yarns (15 pts)
		[7, 4, 2, 0, 0, 0, 0, 0, 0, 0],  # Wave 4: 7 Treats + 4 Yarns (15 pts)
		[5, 5, 1, 0, 0, 0, 0, 0, 0, 0]   # Wave 5: 5 Treats + 5 Yarns (15 pts)
	]

	# 2. BATCH 1: Yarn Frenzy (Total Max Score: 100 pts | 20 pts/wave)
	var b1 = BatchData.new()
	b1.batch_name = "Yarn Frenzy"
	b1.waves = [
		[10, 5, 0, 0, 0, 0, 0, 0, 0, 0], # Wave 1: 10 Treats + 5 Yarns (20 pts)
		[0, 10, 0, 0, 0, 0, 0, 0, 0, 0], # Wave 2: 10 Yarns (20 pts)
		[4, 8, 2, 0, 0, 0, 0, 0, 0, 0],  # Wave 3: 4 Treats + 8 Yarns (20 pts)
		[2, 9, 0, 0, 3, 0, 0, 0, 0, 0],  # Wave 4: 2 Treats + 9 Yarns (20 pts)
		[6, 7, 0, 0, 0, 0, 0, 0, 0, 0]   # Wave 5: 6 Treats + 7 Yarns (20 pts)
	]
	batch_pool.append(b1)

	# 3. BATCH 2: Yarn & Hazard Mix (Total Max Score: 100 pts | 20 pts/wave)
	var b2 = BatchData.new()
	b2.batch_name = "Yarn Blitz"
	b2.waves = [
		[8, 6, 0, 0, 0, 0, 0, 0, 0, 0],  # Wave 1: 8 Treats + 6 Yarns (20 pts)
		[4, 8, 2, 0, 0, 0, 0, 0, 0, 0],  # Wave 2: 4 Treats + 8 Yarns (20 pts)
		[10, 5, 0, 0, 2, 0, 0, 0, 0, 0], # Wave 3: 10 Treats + 5 Yarns (20 pts)
		[2, 9, 3, 0, 0, 0, 0, 0, 0, 0],  # Wave 4: 2 Treats + 9 Yarns (20 pts)
		[6, 7, 0, 0, 0, 0, 0, 0, 0, 0]   # Wave 5: 6 Treats + 7 Yarns (20 pts)
	]
	batch_pool.append(b2)

func _refill_batch_bag() -> void:
	if batch_pool.is_empty():
		push_error("ItemManager: No succeeding batches defined in batch_pool!")
		return
	batch_bag = batch_pool.duplicate()
	batch_bag.shuffle()

func _setup_batch_wave_queue() -> void:
	if current_batch_data and current_batch_data.waves.size() > 0:
		current_wave_queue = current_batch_data.waves.duplicate()
		current_wave_queue.shuffle()

func start_endless() -> void:
	is_endless = true
	is_game_over = false
	total_batches_played = 0
	current_wave_in_batch = 0
	regen_pity_counter = 0
	time_duration_perBatch = base_time_duration_perBatch
	
	clear_objects()
	_refill_batch_bag()
	
	current_batch_data = beginner_batch
	_setup_batch_wave_queue()
	_spawn_next_endless_wave()

func stop_endless() -> void:
	is_endless = false
	is_game_over = true
	clear_objects()

# --- ENDLESS MODE SPAWN FLOW ---

func _start_next_endless_batch() -> void:
	if is_game_over or not is_endless:
		return

	if batch_bag.is_empty():
		_refill_batch_bag()

	total_batches_played += 1
	var current_reduction: float = min(max_timer_reduction, total_batches_played * batch_speed_step)
	time_duration_perBatch = base_time_duration_perBatch - current_reduction

	current_batch_data = batch_bag.pop_front()
	_setup_batch_wave_queue()
	current_wave_in_batch = 0
	_spawn_next_endless_wave()

func _spawn_next_endless_wave() -> void:
	if is_game_over or not is_endless or current_batch_data == null:
		return

	if current_wave_in_batch >= current_wave_queue.size():
		_start_next_endless_batch()
		return

	_isolate_previous_wave()
	_prepare_wave_state()
	
	var wave_encoded_counts: Array = current_wave_queue[current_wave_in_batch].duplicate()

	if current_wave_in_batch == 4:
		_inject_fifth_wave_powerup(wave_encoded_counts)

	_spawn_encoded_array(wave_encoded_counts)
	_start_wave_timer()

func _inject_fifth_wave_powerup(wave_counts: Array) -> void:
	var current_hp: int = 3
	var max_hp: int = 3

	if LivesManager:
		if "lives" in LivesManager:
			current_hp = LivesManager.lives
		if "max_lives" in LivesManager:
			max_hp = LivesManager.max_lives

	var selected_powerup: int = Item.CAMERA

	if current_hp >= max_hp:
		selected_powerup = Item.CAMERA
		regen_pity_counter = 0 # Reset pity since full health
	elif current_hp == 2:
		var base_chance: float = 0.25
		var modified_chance: float = base_chance + (regen_pity_counter * 0.10)
		if randf() < modified_chance:
			selected_powerup = Item.REGEN
			regen_pity_counter = 0 # Reset on success
		else:
			selected_powerup = Item.CAMERA
			regen_pity_counter += 1 # Increase pity
	elif current_hp == 1:
		var base_chance: float = 0.50
		var modified_chance: float = base_chance + (regen_pity_counter * 0.10)
		if randf() < modified_chance:
			selected_powerup = Item.REGEN
			regen_pity_counter = 0 # Reset on success
		else:
			selected_powerup = Item.CAMERA
			regen_pity_counter += 1 # Increase pity
	else:
		selected_powerup = Item.CAMERA

	var target_index: int = -1
	match selected_powerup:
		Item.CAMERA: target_index = 3
		Item.REGEN: target_index = 8

	if target_index >= 0 and target_index < wave_counts.size():
		wave_counts[target_index] += 1

func _spawn_encoded_array(item_count: Array) -> void:
	current_parent = get_tree().current_scene
	for i in range(item_count.size()):
		var count = item_count[i]
		if count > 0:
			match i:
				0: spawn_random_pop_in_rect(Item.TREAT, count, current_parent)
				1: _spawn_drop_grid(Item.YARN, count, current_parent)
				2: spawn_random_pop_in_rect(Item.GARBAGE, count, current_parent)
				3: spawn_random_pop_in_rect(Item.CAMERA, count, current_parent)
				4: _spawn_drop_grid(Item.SHOES, count, current_parent)
				5: spawn_random_pop_in_rect(Item.SARDINE, count, current_parent)
				6: spawn_random_pop_in_rect(Item.RAT, count, current_parent)
				7: spawn_random_pop_in_rect(Item.SACK, count, current_parent)
				8: spawn_random_pop_in_rect(Item.REGEN, count, current_parent)
				9: spawn_random_pop_in_rect(Item.POLAROID, count, current_parent)

# --- STORY MODE SPAWNING ---

func play_story_pattern(number: int):
	if is_game_over or is_endless:
		return
		
	# --- BUG FIX: Guarantee a strict 6-second timer for Story Mode ---
	time_duration_perBatch = base_time_duration_perBatch
	# -----------------------------------------------------------------
		
	_isolate_previous_wave()
	_prepare_wave_state()
	current_parent = get_tree().current_scene 
	if number > 30:
		return

	var item_count = []
	match number:
			1: item_count = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0]
			2: item_count = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0]
			3: item_count = [15, 0, 4, 0, 0, 0, 0, 0, 0, 0]
			4: item_count = [15, 0, 4, 0, 0, 0, 0, 0, 0, 0]
			5: item_count = [0, 15, 0, 0, 0, 0, 0, 0, 0, 0]
			6: item_count = [10, 5, 0, 0, 0, 0, 0, 0, 0, 0]
			7: item_count = [12, 12, 3, 0, 0, 0, 0, 0, 0, 0]
			8: item_count = [0, 24, 3, 0, 0, 0, 0, 0, 0, 0]
			9: item_count = [0, 0, 15, 1, 0, 0, 0, 0, 0, 0]
			10: item_count = [0, 0, 15, 1, 0, 0, 0, 0, 0, 0]
			11: item_count = [8, 0, 0, 0, 0, 3, 0, 0, 0, 0]
			12: item_count = [0, 8, 0, 0, 0, 3, 0, 0, 0, 0]
			13: item_count = [0, 16, 0, 0, 4, 0, 0, 0, 0, 0]
			14: item_count = [16, 0, 0, 0, 4, 0, 0, 0, 0, 0]
			15: item_count = [0, 4, 0, 0, 4, 4, 0, 0, 0, 0]
			16: item_count = [4, 0, 4, 0, 0, 4, 0, 0, 0, 0]
			17: item_count = [10, 0, 0, 0, 0, 0, 2, 0, 0, 0]
			18: item_count = [0, 10, 0, 0, 0, 0, 2, 0, 0, 0]
			19: item_count = [0, 0, 0, 1, 0, 25, 0, 0, 0, 0]
			20: item_count = [0, 0, 0, 1, 15, 0, 10, 0, 0, 0]
			21: item_count = [0, 0, 6, 0, 0, 6, 0, 0, 0, 0]
			22: item_count = [10, 0, 0, 0, 8, 0, 2, 0, 0, 0]
			23: item_count = [10, 0, 0, 0, 0, 0, 0, 1, 0, 0]
			24: item_count = [0, 10, 0, 0, 0, 0, 0, 1, 0, 0]
			25: item_count = [15, 0, 15, 1, 0, 0, 0, 0, 0, 0]
			26: item_count = [0, 15, 0, 1, 15, 0, 0, 0, 0, 0]
			27: item_count = [8, 0, 8, 0, 0, 0, 0, 2, 0, 0]
			28: item_count = [0, 8, 0, 0, 8, 0, 0, 2, 0, 0]
			29: item_count = [0, 10, 10, 0, 0, 7, 0, 0, 0, 0]
			30: item_count = [11, 0, 0, 0, 10, 0, 5, 0, 0, 0]

	_spawn_encoded_array(item_count)
	_start_wave_timer()

# --- HELPER SPAWNERS & UTILS ---

func _isolate_previous_wave() -> void:
	if current_wave_batch:
		current_wave_batch.is_finished = true
		current_wave_batch = null
	
	for obj in wave_one_objects:
		if is_instance_valid(obj) and obj is Node2D:
			if obj.has_method("despawn"):
				obj.despawn()
				continue
			
			var tween = create_tween()
			tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
			tween.set_trans(Tween.TRANS_BACK)
			tween.set_ease(Tween.EASE_IN)
			
			var target_pos = obj.global_position + Vector2(0, 300)
			tween.tween_property(obj, "global_position", target_pos, 0.3)
			tween.parallel().tween_property(obj, "scale", Vector2.ZERO, 0.3)
			tween.tween_callback(obj.queue_free)
		elif is_instance_valid(obj):
			obj.queue_free()
			
	wave_one_objects.clear()

func _prepare_wave_state() -> void:
	current_wave_batch = WaveBatch.new()
	occupied_cells.clear()
	drop_wave_triggered = false
	missed_items_in_current_wave = 0 
	batch_start_time = Time.get_ticks_msec() / 1000.0

func _start_wave_timer() -> void:
	if active_wave_timer and active_wave_timer.timeout.is_connected(_on_wave_timeout):
		active_wave_timer.timeout.disconnect(_on_wave_timeout)

	active_wave_timer = get_tree().create_timer(time_duration_perBatch, false)
	active_wave_timer.timeout.connect(_on_wave_timeout)

func _get_available_cells(min_cell_distance: int = 1) -> Array[Vector2i]:
	var available: Array[Vector2i] = []
	for r in range(pattern_rows):
		for c in range(pattern_columns):
			var candidate = Vector2i(c, r)
			if occupied_cells.has(candidate):
				continue
			var is_too_close: bool = false
			for occupied in occupied_cells:
				var dist_x = abs(candidate.x - occupied.x)
				var dist_y = abs(candidate.y - occupied.y)
				if dist_x <= min_cell_distance and dist_y <= min_cell_distance:
					is_too_close = true
					break
			if not is_too_close:
				available.append(candidate)
	available.shuffle()
	return available

func spawn_random_pop_in_rect(obj_type, count: int = -1, parent: Node = null) -> void:
	var target_parent = parent if parent else get_tree().current_scene
	var final_count = count if count >= 0 else spawn_count

	current_area = area
	current_parent = target_parent
	match spawn_type:
		SpawnType.RANDOM:
			pass
		SpawnType.GRID:
			_spawn_grid(area, final_count, target_parent, obj_type)

func _spawn_drop_grid(obj_type, count: int = -1, parent: Node = null) -> void:
	var target_parent: Node = parent if parent != null else get_tree().current_scene

	if target_parent == null or area == null:
		return

	var final_count: int = count if count >= 0 else spawn_count
	var cell_size = Vector2(area.size.x / pattern_columns, area.size.y / pattern_rows)
	var anchor_y = area.global_position.y - drop_start_height

	var available_cells = _get_available_cells(1)
	if available_cells.size() < final_count:
		available_cells = _get_available_cells(0)

	var spawn_total = min(final_count, available_cells.size())

	for index in range(spawn_total):
		var cell = available_cells[index]
		occupied_cells.append(cell)
		var cell_origin = area.global_position + Vector2(cell.x * cell_size.x, cell.y * cell_size.y)
		var pos = cell_origin + cell_size / 2.0
		var anchor_pos = Vector2(pos.x, anchor_y)
		var obj: Node
		
		match obj_type:
			Item.YARN: 
				obj = yarn.instantiate()
				if "pop_duration_seconds" in obj:
					obj.pop_duration_seconds = time_duration_perBatch
				elif "lifetime" in obj:
					obj.lifetime = time_duration_perBatch
			Item.SHOES: 
				obj = shoes.instantiate()
				if "pop_duration_seconds" in obj:
					obj.pop_duration_seconds = time_duration_perBatch
				elif "lifetime" in obj:
					obj.lifetime = time_duration_perBatch
			_: continue
			
		obj.set_meta("item_type", obj_type)
		target_parent.add_child(obj)

		if obj.has_signal("popped_out"):
			obj.popped_out.connect(_on_object_popped_out.bind(obj_type))

		spawned_objects.append(obj)
		wave_one_objects.append(obj)

		if obj.has_method("spawn_drop_and_hang"):
			obj.spawn_drop_and_hang(pos, anchor_pos, index * 0.05)

func _spawn_grid(area: Control, count: int, target_parent: Node, obj_type) -> void:
	var cell_size = Vector2(area.size.x / pattern_columns, area.size.y / pattern_rows)
	if obj_type == Item.RAT:
		_spawn_rats(count, cell_size, target_parent)
		return
		
	var available_cells = _get_available_cells(1)
	if available_cells.size() < count:
		available_cells = _get_available_cells(0)
	var spawn_total = min(count, available_cells.size())

	for index in range(spawn_total):
		var cell = available_cells[index]
		occupied_cells.append(cell)
		var cell_origin = area.global_position + Vector2(cell.x * cell_size.x, cell.y * cell_size.y)
		var pos = cell_origin + cell_size / 2.0
		pos.x += randi_range(-10, 10)
		pos.y += randi_range(-10, 10)
		_instantiate_object(pos, target_parent, index, obj_type)

func _spawn_rats(count: int, cell_size: Vector2, target_parent: Node) -> void:
	if count <= 0:
		return
	var left_count = int(ceil(count / 2.0))
	var right_count = count - left_count

	left_count = min(left_count, pattern_columns)
	right_count = min(right_count, pattern_columns)

	for i in range(left_count):
		_spawn_rat_at(Spawner.BOTTOM_LEFT, cell_size, target_parent, min(i, pattern_columns - 1), i)

	for i in range(right_count):
		_spawn_rat_at(Spawner.BOTTOM_RIGHT, cell_size, target_parent, max(pattern_columns - 1 - i, 0), i)

func _instantiate_object(pos: Vector2, target_parent: Node, delay_index: int, obj_type) -> void:
	var obj
	match obj_type:
		Item.TREAT: obj = cat_treat.instantiate()
		Item.GARBAGE: obj = garbage.instantiate()
		Item.CAMERA: obj = camera.instantiate()
		Item.SARDINE: obj = sardine.instantiate()
		Item.RAT: obj = rat.instantiate()
		Item.SACK: obj = sack.instantiate()
		Item.REGEN: obj = regen.instantiate()
		Item.POLAROID: obj = polaroid.instantiate()
	
	if obj_type == Item.SACK and is_endless:
		if "lifetime" in obj:
			obj.lifetime = time_duration_perBatch
		elif "Duration" in obj:
			obj.set("Duration", time_duration_perBatch)
		elif "pop_duration_seconds" in obj:
			obj.pop_duration_seconds = time_duration_perBatch
	elif obj_type != Item.SACK:
		if "lifetime" in obj:
			obj.lifetime = time_duration_perBatch
		elif "Duration" in obj:
			obj.set("Duration", time_duration_perBatch)
		elif "pop_duration_seconds" in obj:
			obj.pop_duration_seconds = time_duration_perBatch
	
	obj.set_meta("item_type", obj_type)

	target_parent.add_child(obj)
	if obj.has_method("launch"):
		obj.launch()
	if obj.has_signal("camera_activated"):
		var camera_effects := get_tree().get_first_node_in_group("camera_effects")
		if camera_effects != null:
			obj.camera_activated.connect(camera_effects.activate_camera_effect)
			
	obj.popped_out.connect(_on_object_popped_out.bind(obj_type))
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

func clear_objects() -> void:
	if active_wave_timer and active_wave_timer.timeout.is_connected(_on_wave_timeout):
		active_wave_timer.timeout.disconnect(_on_wave_timeout)
		active_wave_timer = null

	for obj in spawned_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	spawned_objects.clear()
	wave_one_objects.clear()
	scored_objects.clear()
	occupied_cells.clear()
	missed_items_in_current_wave = 0
	current_wave_batch = null

func _on_object_popped_out(obj: Node, was_clicked: bool, item_type: int) -> void:
	if is_game_over or obj in scored_objects:
		return  
	scored_objects.append(obj)
	spawned_objects.erase(obj)
	wave_one_objects.erase(obj)

	if was_clicked:
		item_collected.emit(item_type)
		
		var is_hazard: bool = (item_type == Item.GARBAGE or item_type == Item.SHOES)
		if is_hazard:
			if LivesManager.has_method("lose_life"):
				LivesManager.lose_life()
	else:
		var is_excluded_from_miss: bool = (
			item_type == Item.GARBAGE or
			item_type == Item.SHOES or
			item_type == Item.CAMERA or
			item_type == Item.REGEN or
			item_type == Item.POLAROID
		)
		if is_endless and not is_excluded_from_miss:
			if current_wave_batch and not current_wave_batch.is_finished:
				current_wave_batch.has_missed_item = true

	if enable_drop_wave and not drop_wave_triggered and wave_one_objects.is_empty():
		drop_wave_triggered = true

func _on_wave_timeout() -> void:
	if not is_inside_tree() or is_game_over:
		return

	if current_wave_batch:
		current_wave_batch.is_finished = true

	if is_endless:
		var uncollected_valid_gifts_exist: bool = false
		
		for obj in wave_one_objects:
			if is_instance_valid(obj):
				# --- BUG FIX: Ignore items that are already clicked and animating ---
				if "is_popping" in obj and obj.is_popping:
					continue
				if "is_finished" in obj and obj.is_finished:
					continue
				# --------------------------------------------------------------------

				var obj_type = obj.get_meta("item_type", -1)
				if (
					obj_type == Item.GARBAGE or 
					obj_type == Item.SHOES or 
					obj_type == Item.POLAROID or 
					obj_type == Item.CAMERA or 
					obj_type == Item.REGEN
				):
					continue
				
				uncollected_valid_gifts_exist = true
				break
		
		if uncollected_valid_gifts_exist or (current_wave_batch and current_wave_batch.has_missed_item):
			if LivesManager.has_method("lose_life"):
				LivesManager.lose_life()

		_handle_endless_mode_timeout()
	else:
		_handle_story_mode_timeout()

func _handle_endless_mode_timeout() -> void:
	if LivesManager.lives <= 0:
		return
		
	# Play the next wave SFX
	AudioManager.play_sound(NEXT_WAVE)
		
	current_wave_in_batch += 1
	_spawn_next_endless_wave()

func _handle_story_mode_timeout() -> void:
	current_pattern += 1
	var pattern_base = ((current_pattern - 1) * 2) + 1
	var chosen_pattern = pattern_base + randi_range(0, 1)

	if current_pattern >= 29:
		current_pattern = 1
		return
	play_story_pattern(chosen_pattern)

func register_spawned_object(obj: Node, obj_type = null) -> void:
	if obj == null:
		return
	if obj.has_signal("popped_out"):
		if obj_type != null:
			obj.popped_out.connect(_on_object_popped_out.bind(obj_type))
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

	var cell = Vector2i(col, r)
	occupied_cells.append(cell)

	var cell_origin = area.global_position + Vector2(col * cell_size.x, r * cell_size.y)
	var pos = cell_origin + cell_size / 2.0

	var obj = rat.instantiate()
	if "lifetime" in obj:
		obj.lifetime = time_duration_perBatch
	elif "pop_duration_seconds" in obj:
		obj.pop_duration_seconds = time_duration_perBatch
		
	obj.set_meta("item_type", Item.RAT)
		
	target_parent.add_child(obj)
	obj.popped_out.connect(_on_object_popped_out.bind(Item.RAT))
	spawned_objects.append(obj)
	wave_one_objects.append(obj)
	obj.set_direction(dir, target_end_x)

	match spawn_animation:
		SpawnAnimation.POP_SCALE:
			_animate_pop_scale(obj, pos, delay_index)
		SpawnAnimation.DROP_IN:
			_animate_drop_in(obj, pos, delay_index)
