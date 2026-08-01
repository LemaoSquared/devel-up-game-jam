extends Node

@export var object_scene: PackedScene = preload("res://Menus/object.tscn")
@export var min_spawn_distance: float = 64.0
@export var max_placement_attempts: int = 30

enum SpawnPattern { RANDOM, GRID }
enum SpawnAnimation { POP_SCALE, DROP_IN }

@export_group("Pattern Settings")
@export var spawn_pattern_type: SpawnPattern = SpawnPattern.GRID
@export var spawn_count: int = 5
@export var pattern_columns: int = 7
@export var pattern_rows: int = 5

@export_group("Animation Settings")
@export var spawn_animation: SpawnAnimation = SpawnAnimation.POP_SCALE
@export var drop_start_height: float = 100.0
@export var drop_duration: float = 0.5

@export_group("Sequential Yarn Wave")
@export var enable_yarn_wave: bool = true
@export var yarn_scene: PackedScene = preload("uid://cgbbkrcpsj0dq")
@export var yarn_count: int = 5
@export var time_duration_perBatch: float = 6.0   # minimum total time this batch must occupy

var spawned_objects: Array[Node] = []
var wave_one_objects: Array[Node] = []
var yarn_wave_triggered: bool = false
var batch_start_time: float = 0.0                 
var current_area: Control
var current_parent: Node


func _ready() -> void:
	pass


func spawn_random_pop_in_rect(area: Control, count: int = -1, parent: Node = null) -> void:
	var target_parent = parent if parent else get_tree().current_scene
	var final_count = count if count >= 0 else spawn_count

	current_area = area
	current_parent = target_parent
	wave_one_objects.clear()
	yarn_wave_triggered = false
	batch_start_time = Time.get_ticks_msec() / 1000.0   # record batch start, in seconds

	match spawn_pattern_type:
		SpawnPattern.RANDOM:
			_spawn_random(area, final_count, target_parent)
		SpawnPattern.GRID:
			_spawn_grid(area, final_count, target_parent)


func _spawn_yarn_grid(area: Control, count: int, target_parent: Node) -> void:
	if not yarn_scene:
		push_warning("ItemManager: yarn_scene is not assigned, skipping yarn wave.")
		return

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

		var obj = yarn_scene.instantiate()
		target_parent.add_child(obj)
		obj.popped_out.connect(_on_object_popped_out)
		spawned_objects.append(obj)

		if obj.has_method("spawn_drop_and_hang"):
			obj.spawn_drop_and_hang(pos, anchor_pos, index * 0.05)
		else:
			push_warning("ItemManager: yarn_scene has no spawn_drop_and_hang method.")


func _spawn_random(area: Control, count: int, target_parent: Node) -> void:
	var placed_positions: Array[Vector2] = []
	for i in range(count):
		var pos = _find_valid_position(area, placed_positions)
		if pos == null:
			continue
		placed_positions.append(pos)
		_instantiate_object(pos, target_parent, i)


func _spawn_grid(area: Control, count: int, target_parent: Node) -> void:
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
		_instantiate_object(pos, target_parent, index)


func _instantiate_object(pos: Vector2, target_parent: Node, delay_index: int) -> void:
	var obj = object_scene.instantiate()
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


func _find_valid_position(area: Control, existing: Array[Vector2]) -> Variant:
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

	if enable_yarn_wave and not yarn_wave_triggered and wave_one_objects.is_empty():
		yarn_wave_triggered = true

		var elapsed = (Time.get_ticks_msec() / 1000.0) - batch_start_time
		var remaining = max(0.0, time_duration_perBatch - elapsed)

		if remaining > 0.0:
			var timer = get_tree().create_timer(remaining, true)   # pause-aware wait
			timer.timeout.connect(func(): _spawn_yarn_grid(current_area, yarn_count, current_parent))
		else:
			_spawn_yarn_grid(current_area, yarn_count, current_parent)
