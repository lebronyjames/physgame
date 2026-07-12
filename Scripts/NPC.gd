extends CharacterBody3D
## NPC shopping FSM. Requires a NavigationAgent3D child node named "NavAgent".
## Also requires an AudioStreamPlayer3D (or 2D/plain) child named "AudioPlayer"
## for the checkout sound.

enum State { SHOPPING, CHECKOUT, LEAVE }

@export var patrol_points: Array[Node3D] = []       # shopping patrol locations
@export var checkout_point: Node3D                  # single checkout destination
@export var leave_point: Node3D                     # exit destination
@export var checkout_sound: AudioStream

@export var move_speed: float = 3.0
@export var arrival_distance: float = 0.5           # how close counts as "arrived"
@export var checkout_wait_time: float = 3.0
@export var chance_to_checkout: float = 0.25        # 0.0-1.0 chance per patrol stop

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var audio_player: AudioStreamPlayer3D = $AudioPlayer

var state: State = State.SHOPPING
var _waiting: bool = false

func _ready() -> void:
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	nav_agent.path_desired_distance = arrival_distance
	nav_agent.target_desired_distance = arrival_distance
	_enter_shopping()

func _physics_process(_delta: float) -> void:
	if _waiting:
		return  # paused during checkout wait, don't move

	if nav_agent.is_navigation_finished():
		_on_arrived()
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position)
	direction.y = 0.0
	direction = direction.normalized()

	var desired_velocity := direction * move_speed

	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(desired_velocity)
	else:
		velocity = desired_velocity
		move_and_slide()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_arrived() -> void:
	match state:
		State.SHOPPING:
			_handle_shopping_arrival()
		State.CHECKOUT:
			_handle_checkout_arrival()
		State.LEAVE:
			_handle_leave_arrival()

# ---------------- SHOPPING ----------------

func _enter_shopping() -> void:
	state = State.SHOPPING
	_go_to_random_patrol_point()

func _go_to_random_patrol_point() -> void:
	if patrol_points.is_empty():
		push_warning("No patrol points assigned.")
		return
	var target := patrol_points[randi() % patrol_points.size()]
	nav_agent.target_position = target.global_position

func _handle_shopping_arrival() -> void:
	if randf() < chance_to_checkout:
		_enter_checkout()
	else:
		_go_to_random_patrol_point()

# ---------------- CHECKOUT ----------------

func _enter_checkout() -> void:
	state = State.CHECKOUT
	if checkout_point == null:
		push_warning("No checkout_point assigned.")
		return
	nav_agent.target_position = checkout_point.global_position

func _handle_checkout_arrival() -> void:
	_waiting = true
	velocity = Vector3.ZERO
	move_and_slide()

	if checkout_sound:
		audio_player.stream = checkout_sound
		audio_player.play()

	await get_tree().create_timer(checkout_wait_time).timeout

	_waiting = false
	_enter_leave()

# ---------------- LEAVE ----------------

func _enter_leave() -> void:
	state = State.LEAVE
	if leave_point == null:
		push_warning("No leave_point assigned.")
		return
	nav_agent.target_position = leave_point.global_position

func _handle_leave_arrival() -> void:
	queue_free()
