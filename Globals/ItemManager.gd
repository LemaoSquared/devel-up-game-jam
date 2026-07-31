extends Node

@export var object_scene: PackedScene = preload("res://Menus/object.tscn")
@export var min_spawn_distance: float = 64.0   
@export var max_placement_attempts: int = 30

var spawned_objects: Array[Node] = []

func _ready() -> void:
	pass

func spawn_random_pop_in_rect(area: Control, count: int = 3, parent: Node = null) -> void:
	var target_parent = parent if parent else get_tree().current_scene
	var placed_positions: Array[Vector2] = []

	for i in range(count):
		var pos = _find_valid_position(area, placed_positions)
		if pos == null:
			continue

		placed_positions.append(pos)

		var obj = object_scene.instantiate()
		target_parent.add_child(obj)
		obj.global_position = pos
		obj.scale = Vector2.ZERO
		
		obj.popped_out.connect(_on_object_popped_out)
		
		var pop_tween = create_tween()
		pop_tween.set_trans(Tween.TRANS_BACK)
		pop_tween.set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(obj, "scale", Vector2.ONE, 0.4).set_delay(i * 0.05)

		spawned_objects.append(obj)

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
	
func _on_object_popped_out(obj: Node) -> void:
	spawned_objects.erase(obj)
