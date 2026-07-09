extends Node

signal Capture_Item

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if "object_name" in body:
		emit_signal("Capture_Item", body)
		body.queue_free()
