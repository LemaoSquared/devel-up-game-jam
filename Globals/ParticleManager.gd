extends Node2D

var particles_enabled: bool = true
const CLICK_PARTICLE = preload("uid://d3v5eteyxeame")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func spawn_particle(p,pos):
	if !particles_enabled: return 
	if is_instance_valid(p):
		var particle = p.instantiate()
		particle.get_node("GPUParticles2D").global_position = pos
		add_child(particle)

func spawn_emitting_particle(p,pos):
	if !particles_enabled: return 
	if is_instance_valid(p):
		var particle = p.instantiate()
		particle.global_position = pos
		particle.add_to_group("particles")
		add_child(particle)

func despawn_emitting_particles():
	var particles = get_tree().get_nodes_in_group("particles")
	if particles.size() > 0:
		for p in particles:
			p.get_child(0).emitting = false
		await get_tree().create_timer(2.0).timeout
		for p in particles:
			p.queue_free()
