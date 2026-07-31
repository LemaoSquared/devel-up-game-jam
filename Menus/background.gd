extends ColorRect

@onready var black_panel_up: ColorRect = $BlackPanelUP
@onready var black_panel_down: ColorRect = $BlackPanelDown

func close_cinematic_bars() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(black_panel_up, "position:y", black_panel_up.position.y + black_panel_up.size.y, 1.2)

	tween.tween_property(black_panel_down, "position:y", black_panel_down.position.y - black_panel_down.size.y, 1.2)
