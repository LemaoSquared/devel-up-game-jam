extends CanvasLayer

@onready var transition_rect: TextureRect = $Gradient
var swipe_speed: float = 0.5

func _ready() -> void:
	# Hide it off-screen to the right by default on boot
	var screen_width = get_viewport().get_visible_rect().size.x
	transition_rect.position.x = screen_width

# Pulls the gradient IN to cover the screen
func swipe_in() -> void:
	var screen_width = get_viewport().get_visible_rect().size.x
	transition_rect.position.x = screen_width
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	# Uses your original math to center the huge texture
	tween.tween_property(transition_rect, "position:x", -1536.0, swipe_speed)
	
	# Pause whatever script called this until the tween finishes!
	await tween.finished

# Pushes the gradient OUT to reveal the screen
func swipe_out() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	var screen_width = get_viewport().get_visible_rect().size.x
	var target_x = -screen_width - 3100.0
	
	# Uses your original math to push it off the left side
	tween.tween_property(transition_rect, "position:x", target_x, swipe_speed)
	
	await tween.finished
	
# Add this to the bottom of your SceneTransition Autoload script
func change_scene(target_scene: PackedScene) -> void:
	# 1. Swipe the screen to black
	await swipe_in()
	
	# 2. Change the actual level behind the darkness
	get_tree().change_scene_to_packed(target_scene)
	
	# 3. Swipe away to reveal the new level
	await swipe_out()
