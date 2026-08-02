extends Node2D

@onready var kath: AnimatedSprite2D = $AnimatedSprite2D

signal cutscene_finished

var front_facing_scale: float = 2.25
var back_facing_scale: float = 2.375
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	kath_walk_to_grave()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func kath_walk_to_grave() -> void:
	# Set the initial scale for the walking animation
	kath.scale = Vector2(front_facing_scale, front_facing_scale)
	kath.play("default") 
	
	var sequence = create_tween()
	
	# 1. The main walk
	sequence.tween_property(kath, "position:x", 900.0, 2.5).set_trans(Tween.TRANS_LINEAR)
	
	# 2. Swap to the slow-down animation
	sequence.tween_callback(func():
		kath.play("walk_to_stand")
	)
	
	# 3. Final slide to a smooth halt
	sequence.tween_property(kath, "position:x", 967.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 4. DRAMATIC PAUSE
	sequence.tween_interval(0.9) 
	
	# 5. Snap the animation AND the scale at the exact same time!
	sequence.tween_callback(func():
		kath.play("back_turned")
		kath.scale = Vector2(back_facing_scale, back_facing_scale)
	)
	
	await sequence.finished
	cutscene_finished.emit()
	
