extends Node3D
## Spawns NPCs on a timer and configures their FSM points.
## Expected children of this spawner node:
##   - Timer (a Timer node)
##   - PatrolPoints (a Node3D containing Node3D children used as patrol points)
##   - CheckoutPoint (a Node3D marking the checkout destination)
## This spawner node itself is used as the NPC's "leave point".

@export var npc_scenes: Array[PackedScene]

@onready var timer: Timer = $Timer
@onready var patrol_points_container: Node3D = $PatrolPoints
@onready var checkout_point: Node3D = $CheckoutPoint

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	spawn_npc()

func _on_timer_timeout() -> void:
	spawn_npc()

func spawn_npc():
	print("Spawning NPC now")

	var selected_npc := npc_scenes[randi() % npc_scenes.size()]
	
	
	var npc := selected_npc.instantiate()
	get_tree().current_scene.add_child(npc)
	npc.global_position = global_position

	var points: Array[Node3D] = []
	for child in patrol_points_container.get_children():
		if child is Node3D:
			points.append(child)

	npc.patrol_points = points
	npc.checkout_point = checkout_point
	npc.leave_point = self
