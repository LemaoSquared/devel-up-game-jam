extends Node
signal score_changed(new_score: int)
var score: int = 0
var point_values := {
	ItemManager.Item.TREAT: 5,
	ItemManager.Item.GARBAGE: -5,
	ItemManager.Item.RAT: 10,
	ItemManager.Item.YARN: 15,
	ItemManager.Item.SHOES: -30,
	ItemManager.Item.SACK: 0,
	ItemManager.Item.SARDINE: 0,  
	ItemManager.Item.CAMERA: 0,
}

func _ready():
	ItemManager.item_collected.connect(_on_item_collected)

func _on_item_collected(item_type: int) -> void:
	if not point_values.has(item_type):
		push_warning("ScoreManager: missing point value for item %s" % item_type)
		return
	add_points(point_values[item_type])

func add_points(amount: int) -> void:
	score = max(0, score + amount)
	score_changed.emit(score)
	print("Score changed by %+d (total: %d)" % [amount, score])

func reset_score() -> void:
	score = 0
	score_changed.emit(score)
