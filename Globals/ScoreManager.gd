extends Node

signal score_changed(new_score: int)
signal multiplier_changed(new_multiplier: int) # <--- Crucial for the background script!
signal high_score_changed(new_high_score: int)

var score: int = 0
var current_multiplier: int = 1 
var flawless_waves: int = 0 

const SAVE_PATH := "user://savedata.save"
var high_score: int = 0

var point_values := {
	ItemManager.Item.TREAT: 5,
	ItemManager.Item.GARBAGE: -30,
	ItemManager.Item.RAT: 20,
	ItemManager.Item.YARN: 5,
	ItemManager.Item.SHOES: -30,
	ItemManager.Item.SACK: 0,
	ItemManager.Item.SARDINE: 5,
	ItemManager.Item.CAMERA: 0,
	ItemManager.Item.POLAROID: 20,
	ItemManager.Item.REGEN: 0,
}

func _ready():
	ItemManager.item_collected.connect(_on_item_collected)
	load_high_score()

func _on_item_collected(item_type: int) -> void:
	if not point_values.has(item_type):
		push_warning("ScoreManager: missing point value for item %s" % item_type)
		return
	add_points(point_values[item_type])

func add_points(amount: int) -> void:
	var final_amount = amount
	
	# Only multiply positive points (hazards/penalties stay unmultiplied)
	if amount > 0:
		final_amount *= current_multiplier
		
	score = max(0, score + final_amount)
	score_changed.emit(score)
	print("Score changed by %+d (total: %d) [Multiplier: x%d]" % [final_amount, score, current_multiplier])

# --- STREAK SYSTEM FUNCTIONS ---
func register_flawless_wave() -> void:
	flawless_waves += 1
	print("Flawless wave registered! Total flawless waves: ", flawless_waves)
	
	if flawless_waves == 3:
		current_multiplier = 2
		multiplier_changed.emit(current_multiplier)
		print("Tap Streak! x2 Multiplier Active")
	elif flawless_waves == 6:
		current_multiplier = 3
		multiplier_changed.emit(current_multiplier)
		print("Taptap Streak! x3 Multiplier Active")

func reset_streak() -> void:
	flawless_waves = 0
	if current_multiplier > 1:
		current_multiplier = 1
		multiplier_changed.emit(current_multiplier)
		print("Streak lost! Multiplier reset to x1")

func reset_score() -> void:
	score = 0
	current_multiplier = 1
	flawless_waves = 0
	score_changed.emit(score)
	multiplier_changed.emit(current_multiplier)
	
func load_high_score() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		high_score = 0
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("ScoreManager: failed to open save file for reading.")
		return

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("high_score"):
		high_score = int(parsed["high_score"])
	else:
		high_score = 0
		
func save_high_score() -> void:
	var data := {
		"high_score": high_score
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ScoreManager: failed to open the save file to load.")
		return
	file.store_string(JSON.stringify(data))
	file.close()

func try_update_high_score() -> bool:
	if score > high_score:
		high_score = score
		high_score_changed.emit(high_score)
		save_high_score()
		return true
	return false
