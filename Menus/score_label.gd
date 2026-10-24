extends Label

var last_score: int = 0
var score_tween: Tween = null

func _ready() -> void:
	# Initialize with the current score from ScoreManager if it exists
	if "score" in ScoreManager:
		last_score = ScoreManager.score
		text = str(last_score)

	# Connect to the score change signal if your ScoreManager uses one, 
	# otherwise it will safely fall back to checking in _process.
	if ScoreManager.has_signal("score_changed"):
		ScoreManager.score_changed.connect(_on_score_changed)

func _process(_delta: float) -> void:
	# Fallback safety check if ScoreManager doesn't use signals
	if "score" in ScoreManager:
		var current_score = ScoreManager.score
		if current_score != last_score:
			update_score(current_score)

func _on_score_changed(new_score: int) -> void:
	update_score(new_score)

func update_score(new_score: int) -> void:
	var increased = new_score > last_score
	last_score = new_score
	text = str(new_score)

	# Stop any ongoing tween so effects don't overlap awkwardly
	if score_tween and score_tween.is_valid():
		score_tween.kill()

	# Ensure the label scales from its center instead of top-left
	pivot_offset = size / 2

	score_tween = create_tween()

	if increased:
		# --- SCORE INCREASE: Bounce + White/Bright Flash ---
		modulate = Color(2.0, 2.0, 2.0, 1.0) # Flash bright white
		score_tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.08)
		score_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.2)
		
		score_tween.chain().tween_property(self, "scale", Vector2.ONE, 0.15) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)
	else:
		# --- SCORE DECREASE: Green Tint + Subtle Shrink ---
		modulate = Color(0.607, 0.147, 0.0, 1.0) # Green tint for reduction
		score_tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.08)
		score_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.3)
		
		score_tween.chain().tween_property(self, "scale", Vector2.ONE, 0.15)
