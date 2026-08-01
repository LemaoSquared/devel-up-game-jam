extends Node2D

@export var random_textures: Array[Texture2D]
@export var base_speed: float = 25
@export var depth_multiplier: float = 1.0

var pool: Array[Sprite2D] = []
var wrap_distance: float
var left_bound: float

func _ready():
	# 1. Gather all the Sprite2D children
	for child in get_children():
		if child is Sprite2D:
			pool.append(child)
			
	if pool.is_empty():
		push_error("No Sprite2D nodes found in this layer!")
		return 
		
	# 2. Randomize all sprites before we calculate the width
	for sprite in pool:
		_randomize_sprite(sprite)
		
	if pool[0].texture == null:
		push_error("Sprites have no texture! Add some to the random_textures array.")
		return
		
	# 3. Get the exact width of your image (accounting for scale)
	var texture_width = pool[0].texture.get_size().x * pool[0].scale.x
	
	# 4. AUTO-ALIGN: Automatically snap them shoulder-to-shoulder!
	for i in range(pool.size()):
		pool[i].position.x = i * texture_width
		pool[i].position.y = 0 # Keeps them perfectly level
	
	# 5. Set the teleport line DEEP off-screen so you never see it vanish
	left_bound = -(texture_width) - 200.0 
	
	# 6. Total distance to jump back to the end of the line
	wrap_distance = texture_width * pool.size()

func _process(delta):
	var move_amount = base_speed * depth_multiplier * delta
	
	for sprite in pool:
		sprite.position.x -= move_amount
		
		# When the sprite crosses the deep off-screen line...
		if sprite.position.x < left_bound:
			# Teleport it to the back of the line, keeping perfect spacing
			sprite.position.x += wrap_distance
			
			# Swap to a new random texture for its next cycle!
			_randomize_sprite(sprite)

func _randomize_sprite(sprite: Sprite2D):
	if random_textures.size() > 0:
		sprite.texture = random_textures.pick_random()
