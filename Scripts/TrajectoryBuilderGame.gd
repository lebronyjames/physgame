extends Node3D

enum CameraMode {
	Free,
	XZAxis,
	YAxis
}

enum ObjectMode {
	SelectObject,
	SelectTrajectory
}

@export var trajectory_cursor_type: PackedScene
@export var max_dist_from_obj: float = 1
@export var max_zoomout: float = 3.5
@export var zoom_rate: float = 3

var camera_root: Node3D
var camera: Camera3D
var current_camera_mode: CameraMode
var object_mode: ObjectMode
var selected_object: Node3D
var drag_plane: Plane
var trajectory_pointer: Node3D
var cached_free_camera_angle: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_root = find_child("CameraRoot")
	camera = find_child("Camera3D")
	current_camera_mode = CameraMode.Free
	object_mode = ObjectMode.SelectObject
	selected_object = null
	trajectory_pointer = null
	cached_free_camera_angle = camera_root.rotation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("xz_mode"):
		current_camera_mode = CameraMode.XZAxis
		camera_root.rotation = Vector3(deg_to_rad(-90), 0, 0)
		calculate_plane()
	elif Input.is_action_pressed("y_mode"):
		current_camera_mode = CameraMode.YAxis
		camera_root.rotation = Vector3(0, 0, 0)
		calculate_plane()
	elif Input.is_action_pressed("free_mode"):
		current_camera_mode = CameraMode.Free
		camera_root.rotation = cached_free_camera_angle
	
	if current_camera_mode == CameraMode.Free:
		pan_free_camera(delta)
	else:
		if Input.is_action_pressed("click"):
			if object_mode == ObjectMode.SelectTrajectory:  
				if current_camera_mode == CameraMode.XZAxis:
					drag_cursor_xz()
				elif current_camera_mode == CameraMode.YAxis:
					drag_cursor_y()
			
	if Input.is_action_just_released("zoom_back"):
		var next_zoom_pos = camera.position.z + zoom_rate * delta
		if next_zoom_pos < max_zoomout:
			camera.position.z = next_zoom_pos
	if Input.is_action_just_released("zoom_forward"):
		var next_zoom_pos = camera.position.z - zoom_rate * delta
		if next_zoom_pos > 0.5:
			camera.position.z = next_zoom_pos
	
	if Input.is_action_pressed("esc"):
		if object_mode == ObjectMode.SelectTrajectory:
			switch_to_select_object()

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("click")):
		cast_for_item(event)

# --------------- HELPERS -----------------------------------------

func pan_free_camera(delta):
	if Input.is_action_pressed("pan_camera_down"):
		var next_x_axis_angle = camera_root.rotation.x + 1 * delta
		if next_x_axis_angle < 0:
			camera_root.rotation.x = next_x_axis_angle
	if Input.is_action_pressed("pan_camera_up"):
		var next_axis_x_angle = camera_root.rotation.x - 1 * delta
		if next_axis_x_angle > deg_to_rad(-90):
			camera_root.rotation.x = next_axis_x_angle
	if Input.is_action_pressed("pan_camera_left"):
		camera_root.rotation.y -= 1 * delta
	if Input.is_action_pressed("pan_camera_right"):
		camera_root.rotation.y += 1 * delta
	cached_free_camera_angle = camera_root.rotation

func drag_cursor_xz():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var drag_ray = camera.project_ray_normal(mouse_pos)
	var new_cursor_point = drag_plane.intersects_ray(from, drag_ray)
	
	var selected_object_point_xz = selected_object.position * Vector3(1,0,1)
	var new_cursor_point_xz = new_cursor_point * Vector3(1,0,1)
	var distance_from_obj = abs(selected_object_point_xz.distance_to(new_cursor_point_xz))
	if new_cursor_point != null:
		if distance_from_obj <= max_dist_from_obj:
			trajectory_pointer.position = new_cursor_point
		else:
			var ray = ((new_cursor_point as Vector3) - selected_object.position).normalized()
			var diff = ((selected_object.position + ray * max_dist_from_obj) - trajectory_pointer.position) * Vector3(1,0,1)
			trajectory_pointer.position += diff

func drag_cursor_y():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var drag_ray = camera.project_ray_normal(mouse_pos)
	var new_cursor_point = drag_plane.intersects_ray(from, drag_ray)
	var distance_from_obj = abs(selected_object.position.y - new_cursor_point.y)
	if new_cursor_point != null:
		if distance_from_obj <= max_dist_from_obj:
			trajectory_pointer.position.y = new_cursor_point.y
		else:
			trajectory_pointer.position.y = selected_object.position.y + max_dist_from_obj

func switch_to_select_object():
	selected_object = null
	trajectory_pointer.queue_free()
	trajectory_pointer = null
	object_mode = ObjectMode.SelectObject

func calculate_plane():
	if trajectory_pointer != null:
		drag_plane = Plane(-camera.global_transform.basis.z, trajectory_pointer.global_position)

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
