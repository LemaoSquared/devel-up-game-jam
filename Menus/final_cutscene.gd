extends Node2D

@onready var kath: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	kath_walk_to_grave()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func kath_walk_to_grave() -> void:
	kath.play("default")
	var walk_tween = create_tween()
	walk_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	walk_tween.tween_property(kath,"position:x",896.0, 3.0)
