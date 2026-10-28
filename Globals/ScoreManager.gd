extends Node

signal score_changed(new_score: int)
signal multiplier_changed(new_multiplier: int)
signal high_score_changed(new_high_score: int)

var score: int = 0
var current_multiplier: int = 1 
var flawless_waves: int = 0 

# --- Dedicated Item Count Variables (Item-Specific) ---
var treat_count: int = 0
var yarn_count: int = 0
var sardine_count: int = 0    # Maps to Sardine
var rat_count: int = 0
var sack_count: int = 0
var polaroid_count: int = 0
var red_shoe_count: int = 0   # Maps to Item.RED_SHOES
var garbage_count: int = 0
var shoe_count: int = 0       # Maps to Item.SHOES
# -----------------------------------------------------

const SAVE_PATH := "user://savedata.save"
var high_score: int = 0 # Endless mode
var story_high_score: int = 0 # Story mode

var last_run_endless: bool = false
var last_run_new_record: bool = false

var point_values := {
	ItemManager.Item.TREAT: 5,
	ItemManager.Item.GARBAGE: -30,
	ItemManager.Item.RAT: 10,
	ItemManager.Item.YARN: 5,
	ItemManager.Item.SHOES: -30,
	ItemManager.Item.SACK: 25,
	ItemManager.Item.SARDINE: 5,
	ItemManager.Item.CAMERA: 0,
	ItemManager.Item.POLAROID: 20,
	ItemManager.Item.REGEN: 0,
	ItemManager.Item.GLOVES: 0,
	ItemManager.Item.PAW: 0,
	ItemManager.Item.RED_SHOES: 250,
}

func _ready() -> void:
	ItemManager.item_collected.connect(_on_item_collected)
	load_high_score()

func _on_item_collected(item_type: int) -> void:
	# Item-specific count tracking triggered automatically via ItemManager emissions
	match item_type:
		ItemManager.Item.TREAT:
			treat_count += 1
		ItemManager.Item.YARN:
			yarn_count += 1
		ItemManager.Item.GARBAGE:
			garbage_count += 1
		ItemManager.Item.SHOES:
			shoe_count += 1
		ItemManager.Item.SARDINE:
			sardine_count += 1 
		ItemManager.Item.RAT:
			rat_count += 1
		ItemManager.Item.SACK:
			sack_count += 1
		ItemManager.Item.POLAROID:
			polaroid_count += 1
		ItemManager.Item.RED_SHOES:
			red_shoe_count += 1

	if not point_values.has(item_type):
		push_warning("ScoreManager: missing point value for item %s" % item_type)
		return
		
	# Red Shoes use a custom multiplier scaling in ItemManager, so prevent double-adding base points if handled there, or let add_points manage standard items:
	if item_type != ItemManager.Item.RED_SHOES:
		add_points(point_values[item_type])

func add_points(amount: int) -> void:
	var final_amount = amount
	
	if amount > 0:
		final_amount *= current_multiplier
		
	score = max(0, score + final_amount)
	score_changed.emit(score)

# --- STREAK SYSTEM FUNCTIONS ---
func register_flawless_wave() -> void:
	flawless_waves += 1
	if flawless_waves == 3:
		current_multiplier = 2
		multiplier_changed.emit(current_multiplier)
	elif flawless_waves == 6:
		current_multiplier = 3
		multiplier_changed.emit(current_multiplier)

func reset_streak() -> void:
	flawless_waves = 0
	if current_multiplier > 1:
		current_multiplier = 1
		multiplier_changed.emit(current_multiplier)

func reset_score() -> void:
	score = 0
	current_multiplier = 1
	flawless_waves = 0
	
	# Reset all item counts on new run / retry
	treat_count = 0
	yarn_count = 0
	sardine_count = 0
	rat_count = 0
	sack_count = 0
	polaroid_count = 0
	red_shoe_count = 0
	garbage_count = 0
	shoe_count = 0
	
	score_changed.emit(score)
	multiplier_changed.emit(current_multiplier)
	
func load_high_score() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		high_score = 0
		story_high_score = 0
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("high_score"):
		high_score = int(parsed["high_score"])
		story_high_score = int(parsed.get("story_high_score", 0))
	else:
		high_score = 0
		story_high_score = 0
		
func save_high_score() -> void:
	var data := {
		"high_score": high_score,
		"story_high_score": story_high_score
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()

func get_high_score(endless: bool) -> int:
	return high_score if endless else story_high_score

func try_update_high_score(endless: bool) -> bool:
	last_run_endless = endless
	last_run_new_record = false
	
	load_high_score()
	
	if endless and score > high_score:
		high_score = score
		last_run_new_record = true
		high_score_changed.emit(high_score)
	elif not endless and score > story_high_score:
		story_high_score = score
		last_run_new_record = true
		
	if last_run_new_record:
		save_high_score()
		
	return last_run_new_record

func reset_saved_high_score() -> void:
	high_score = 0
	story_high_score = 0
	save_high_score()
	high_score_changed.emit(high_score)
