extends Node

@onready var PullStrengthStatsBox = $VBoxContainer3/VBoxContainer/PullStrengthLabel
@onready var ShoppingListContainer = $VBoxContainer3/ShoppingListContainer
@onready var BadEnding = $BadEnding
@onready var GoodEnding = $GoodEnding
@onready var RetardEnding = $RetardEnding

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_trajectory_builder_game_update_pull_force(Force_Modifier):
	PullStrengthStatsBox.set_text("Pull strength: " + str(Force_Modifier))


func _on_node_3d_update_shopping_list(shopping_list: Dictionary[String, int]) -> void:
	for child in ShoppingListContainer.get_children():
		child.queue_free()
	
	if len(shopping_list.keys()) == 0:
		var label := Label.new()
		label.text = "Go check out now!"
		ShoppingListContainer.add_child(label)
	
	for item in shopping_list:
		var label := Label.new()
		label.text = item + ": " + str(shopping_list[item])
		ShoppingListContainer.add_child(label)


func _on_node_3d_update_ending(ending: String) -> void:
	if ending == "BadEnding":
		BadEnding.visible = true
	if ending == "RetardEnding":
		RetardEnding.visible = true
	if ending == "GoodEnding":
		GoodEnding.visible = true


func _on_node_3d_update_shopping_notify_exit() -> void:
	for child in ShoppingListContainer.get_children():
		child.queue_free()

	var label := Label.new()
	label.text = "You may leave the store now."
	ShoppingListContainer.add_child(label)
