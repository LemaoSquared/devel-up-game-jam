extends TextureButton

@export var off_texture: Texture2D
@export var off_hovered_texture: Texture2D
@export var on_texture: Texture2D
@export var on_hovered_texture: Texture2D

var is_hovering: bool = false

func _ready() -> void:
	texture_hover = null
	texture_pressed = null
	
	toggled.connect(_on_toggled)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	_update_visuals()

func _on_toggled(_is_on: bool) -> void:
	_update_visuals()

func _on_mouse_entered() -> void:
	is_hovering = true
	_update_visuals()

func _on_mouse_exited() -> void:
	is_hovering = false
	_update_visuals()

func _update_visuals() -> void:
	if button_pressed: 
		if is_hovering:
			texture_normal = on_hovered_texture
		else:
			texture_normal = on_texture
	else:
		if is_hovering:
			texture_normal = off_hovered_texture
		else:
			texture_normal = off_texture
