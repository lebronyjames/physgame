extends RigidBody3D

signal Capture_Item

@export var Audio_Player: AudioStreamPlayer3D
@export var Bump_Sfx: AudioStream
@export var object_name : String = ""

var currently_playing_sound : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var speed = linear_velocity.length()
	if speed >= 0.5 and currently_playing_sound == false:
		Audio_Player.stream = Bump_Sfx
		Audio_Player.play()
		currently_playing_sound = true

func _on_audio_stream_player_3d_finished() -> void:
	currently_playing_sound = false

func _on_basket_trigger_capture_item(body: Node3D) -> void:
	emit_signal("Capture_Item", body)
