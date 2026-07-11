extends Area3D
## Attach this script to your Area3D.
## Fires a signal once `target_body` has remained inside continuously
## for at least `required_time` seconds.
 
@export var required_time: float = 3.0   # seconds it must stay inside
@export var ButcherDialogue: Label3D
@export var ButcherDialogueTimer: Timer
@export var DisgustSound: AudioStreamPlayer3D
 
signal target_stayed(body: Node3D)        # fired once, when the threshold is hit
 
var _timer: float = 0.0
var _is_inside: bool = false
var _already_fired: bool = false
var _active_body: Node3D 

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
 
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		_is_inside = true
		_timer = 0.0
		_already_fired = false
		_active_body = body
		ButcherDialogue.text = "You looking to buy any meat?"
		ButcherDialogue.visible = true
		ButcherDialogueTimer.stop()
		ButcherDialogueTimer.start()
 
func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		_is_inside = false
		_timer = 0.0
		_already_fired = false
		_active_body = null
		ButcherDialogue.text = "Yo come back!"
		ButcherDialogue.visible = true
		ButcherDialogueTimer.stop()
		ButcherDialogueTimer.start()
 
func _process(delta: float) -> void:
	if not _is_inside or _already_fired:
		return
 
	_timer += delta
 
	if _timer >= required_time:
		_already_fired = true
		target_stayed.emit(_active_body)
		ButcherDialogue.text = "I got the butcher's special just for you, cozies.\nStraight from between the big Z's legs."
		ButcherDialogue.visible = true
		ButcherDialogueTimer.stop()
		ButcherDialogueTimer.start()
		DisgustSound.play()


func _on_butcher_dialogue_timer_timeout() -> void:
	ButcherDialogue.text = ""
	ButcherDialogue.visible = false
