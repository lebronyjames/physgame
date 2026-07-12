extends RigidBody3D

@export var Audio_Player: AudioStreamPlayer3D
@export var Bump_Sfx: AudioStreamMP3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node) -> void:
	if body is RigidBody3D and body.linear_velocity.length() > 0.2:
		Audio_Player.stream = Bump_Sfx
		Audio_Player.play()
