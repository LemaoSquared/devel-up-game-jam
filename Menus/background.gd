extends ColorRect
@onready var streak_ui: TextureRect = $"../EndlessModeUI/StreakUI"

@onready var black_panel_up: ColorRect = $"../CanvasLayer/BlackPanelUP"
@onready var black_panel_down: ColorRect = $"../CanvasLayer/BlackPanelDown"

@onready var double_streak: TextureRect = $TapStreak     # x2 Streak node
@onready var triple_streak: TextureRect = $TaptapStreak  # x3 Streak node

@export var is_endless_mode: bool = true 

const TAP_STREAK = preload("uid://dmrvpbeqkmj7s")
const TAPTAP_STREAK = preload("uid://b6xww83qxy6tq")
const STREAK_BROKEN = preload("uid://b6dg6xw7531sc")

var previous_multiplier: int = 1

func _ready() -> void:
	if not is_endless_mode:
		if triple_streak:
			triple_streak.modulate.a = 0.0
		if streak_ui:
			streak_ui.visible = false
		return

	# --- ENDLESS MODE INITIALIZATION ---
	if double_streak:
		double_streak.modulate.a = 0.0
		
	if triple_streak:
		triple_streak.modulate.a = 0.0
		
	# Connect to the multiplier signal from ScoreManager
	if ScoreManager and ScoreManager.has_signal("multiplier_changed"):
		ScoreManager.multiplier_changed.connect(_on_multiplier_changed)

func close_cinematic_bars() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(black_panel_up, "position:y", black_panel_up.position.y + black_panel_up.size.y, 0.6)
	tween.tween_property(black_panel_down, "position:y", black_panel_down.position.y - black_panel_down.size.y, 0.6)

func retreat_cinematic_bars() -> void:
	black_panel_up.visible = false
	black_panel_down.visible = false

# --- TAPTAP STREAK VISUAL & AUDIO HANDLERS ---

func _on_multiplier_changed(new_multiplier: int) -> void:
	if not is_endless_mode:
		return
		
	# --- AUDIO TRIGGERS ---
	if new_multiplier == 2 and previous_multiplier != 2:
		AudioManager.play_sound(TAP_STREAK)
	elif new_multiplier == 3 and previous_multiplier != 3:
		AudioManager.play_sound(TAPTAP_STREAK)
	elif new_multiplier < 2 and previous_multiplier >= 2:
		AudioManager.play_sound(STREAK_BROKEN)
		
	previous_multiplier = new_multiplier

	# 1. Original modulate code:
	if new_multiplier == 2:
		fade_in_streak(double_streak)
		fade_out_streak(triple_streak)
	elif new_multiplier == 3:
		fade_out_streak(double_streak)
		fade_in_streak(triple_streak)
	else:
		# Multiplier dropped back to 1 (streak reset)
		fade_out_streak(double_streak)
		fade_out_streak(triple_streak)
		
	# 2. Forward updates to StreakUI:
	if streak_ui:
		var current_streak = 0
		if ScoreManager:
			if "current_streak" in ScoreManager:
				current_streak = ScoreManager.current_streak
			elif "streak" in ScoreManager:
				current_streak = ScoreManager.streak
				
		streak_ui.update_streak_ui(current_streak, new_multiplier)

func fade_in_streak(streak_rect: TextureRect) -> void:
	if not streak_rect:
		return
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(streak_rect, "modulate:a", 0.5, 0.4)

func fade_out_streak(streak_rect: TextureRect) -> void:
	if not streak_rect:
		return
		
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(streak_rect, "modulate:a", 0.0, 0.3)

# --- TAP FLASH HELPER FOR YOUR STREAK UI ---
func flash_streak_label(custom_color: Color = Color.TRANSPARENT) -> void:
	if streak_ui and streak_ui.has_method("trigger_tap_flash"):
		streak_ui.trigger_tap_flash(custom_color)
