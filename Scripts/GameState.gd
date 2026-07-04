extends Node3D

enum CameraMode {
	Free,
	TopDown,
	YAxis
}

enum ObjectMode {
	SelectObject,
	SelectTrajectory
}

@export var trajectory_cursor_type: PackedScene

var camera_root: Node3D
var camera: Camera3D
var current_camera_mode: CameraMode
var object_mode: ObjectMode
var selected_object: Node3D
var drag_plane: Plane
var trajectory_pointer: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_root = find_child("CameraRoot")
	camera = find_child("Camera3D")
	current_camera_mode = CameraMode.Free
	object_mode = ObjectMode.SelectObject
	selected_object = null
	trajectory_pointer = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var recalculate_plane = false
	if Input.is_action_pressed("pan_camera_down"):
		var next_x_axis_angle = camera_root.rotation.x + 1 * delta
		if next_x_axis_angle < 0:
			camera_root.rotation.x = next_x_axis_angle
			recalculate_plane = true
	if Input.is_action_pressed("pan_camera_up"):
		var next_axis_x_angle = camera_root.rotation.x - 1 * delta
		if next_axis_x_angle > deg_to_rad(-90):
			camera_root.rotation.x = next_axis_x_angle
			recalculate_plane = true
	if Input.is_action_pressed("pan_camera_left"):
		camera_root.rotation.y -= 1 * delta
		recalculate_plane = true
	if Input.is_action_pressed("pan_camera_right"):
		camera_root.rotation.y += 1 * delta
		recalculate_plane = true
	if Input.is_action_pressed("zoom_back"):
		camera.position.z += 1 * delta
	if Input.is_action_pressed("zoom_forward"):
		camera.position.z -= 1 * delta
	
	if recalculate_plane:
		calculate_plane()
	
	if Input.is_action_pressed("click"):
		if object_mode == ObjectMode.SelectTrajectory:  
			drag_cursor()
	if Input.is_action_pressed("esc"):
		if object_mode == ObjectMode.SelectTrajectory:
			switch_to_select_object()

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("click")):
		cast_for_item(event)

# --------------- HELPERS -----------------------------------------

func drag_cursor() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var drag_ray = camera.project_ray_normal(mouse_pos)
	var new_cursor_point = drag_plane.intersects_ray(from, drag_ray)
	#var cursor_distance = drag_plane.distance_to(from)
	print(drag_plane.distance_to(from))
	if new_cursor_point != null:
		trajectory_pointer.position = new_cursor_point

func switch_to_select_object():
	selected_object = null
	trajectory_pointer.queue_free()
	trajectory_pointer = null
	object_mode = ObjectMode.SelectObject

func calculate_plane():
	if trajectory_pointer != null:
		drag_plane = Plane(-camera.global_transform.basis.z, selected_object.global_position)

func cast_for_item(event: InputEvent) -> void:
	if object_mode == ObjectMode.SelectObject:
		var mouse_pos = event.position
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 1000
		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
		
		if result:
			var clicked_object = result.collider
			if clicked_object.is_in_group("Interactible"):
				print("Clicked on " + clicked_object.object_name)
				selected_object = clicked_object
				object_mode = ObjectMode.SelectTrajectory
				
				trajectory_pointer = trajectory_cursor_type.instantiate()
				trajectory_pointer.global_position = selected_object.get_global_transform().origin
				add_child(trajectory_pointer)
				calculate_plane()
