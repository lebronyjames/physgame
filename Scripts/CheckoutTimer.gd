extends Area3D
## Attach this script to your Area3D.
## Fires a signal once `target_body` has remained inside continuously
## for at least `required_time` seconds.
 
@export var required_time: float = 3.0   # seconds it must stay inside
@export var CashierDialogue: Label3D
@export var CashierDialogueTimer: Timer
@export var GameState: Node3D
@export var CashierSound: AudioStreamPlayer3D
 
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
		if GameState.done_shopping and GameState.checked_out == false:
			_is_inside = true
			_timer = 0.0
			_already_fired = false
			_active_body = body
			CashierDialogue.text = "Gimme 3 seconds to scan you groceries"
			CashierDialogue.visible = true
			CashierDialogueTimer.stop()
			CashierDialogueTimer.start()
			CashierSound.play()
		elif GameState.checked_out == true:
			CashierDialogue.text = "Why are you still here?"
			CashierDialogue.visible = true
			CashierDialogueTimer.stop()
			CashierDialogueTimer.start()
		else:
			CashierDialogue.text = "Aren't you missing some more baked beans?"
			CashierDialogue.visible = true
			CashierDialogueTimer.stop()
			CashierDialogueTimer.start()
 
func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player") and _is_inside and _already_fired == false:
		_is_inside = false
		_timer = 0.0
		_already_fired = false
		_active_body = null
		CashierDialogue.text = "Where are you going?"
		CashierDialogue.visible = true
		CashierDialogueTimer.stop()
		CashierDialogueTimer.start()
 
func _process(delta: float) -> void:
	if not _is_inside or _already_fired:
		return
 
	_timer += delta
 
	if _timer >= required_time:
		_already_fired = true
		target_stayed.emit(_active_body)
		CashierDialogue.text = "If you don't mind, please press the 67% tip button"
		CashierDialogue.visible = true
		CashierDialogueTimer.stop()
		CashierDialogueTimer.start()


func _on_cashier_dialogue_timer_timeout() -> void:
	CashierDialogue.text = ""
	CashierDialogue.visible = false
