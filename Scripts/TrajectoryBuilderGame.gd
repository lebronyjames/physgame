extends Node3D

signal Update_Shopping_Notify_Exit
signal Update_Pull_Force
signal Update_Shopping_List
signal Update_Ending

enum CameraMode {
	Free,
	XZAxis,
	YAxis
}

enum ObjectMode {
	SelectObject,
	SelectTrajectory
}

@export var shopping_list: Dictionary[String, int]

@export var trajectory_cursor_type: PackedScene
@export var max_dist_from_obj: float = 1
@export var max_zoomout: float = 3.5
@export var zoom_rate: float = 3
@export var max_force: float = 10

var camera_root: Node3D
var camera: Camera3D
var object_mode: ObjectMode
var selected_object: Node3D
var drag_plane: Plane
var trajectory_pointer: Node3D
var cached_free_camera_angle: Vector3
var current_line: Node3D
var Force_Modifier: float
var items_taken: bool
var done_shopping: bool
var checked_out: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_root = find_child("CameraRoot")
	camera = find_child("Camera3D")
	object_mode = ObjectMode.SelectObject
	selected_object = null
	trajectory_pointer = null
	cached_free_camera_angle = camera_root.rotation
	Force_Modifier = 6
	emit_signal("Update_Pull_Force", Force_Modifier)
	emit_signal("Update_Shopping_List", shopping_list)
	items_taken = false
	done_shopping = false
	checked_out = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("xz_mode"):
		camera_root.rotation = Vector3(deg_to_rad(-90), 0, 0)
		calculate_plane()
	elif Input.is_action_pressed("y_mode"):
		camera_root.rotation = Vector3(0, 0, 0)
		calculate_plane()
	elif Input.is_action_pressed("free_mode"):
		camera_root.rotation = cached_free_camera_angle
		calculate_plane()
	
	pan_free_camera(delta)
	
	if Input.is_action_just_pressed("add_force"):
		Force_Modifier += 1
		if Force_Modifier > max_force:
			Force_Modifier = max_force
		emit_signal("Update_Pull_Force", Force_Modifier)
	if Input.is_action_just_pressed("reduce_force"):
		Force_Modifier -= 1
		if Force_Modifier < 0.5:
			Force_Modifier = 0.5
		emit_signal("Update_Pull_Force", Force_Modifier)
	if Input.is_action_pressed("click"):
		if object_mode == ObjectMode.SelectTrajectory:
			drag_cursor()
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
			
	if Input.is_action_pressed("launch"):
		if object_mode == ObjectMode.SelectTrajectory:
			launch_object()

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
	calculate_plane()

func drag_cursor():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var drag_ray = camera.project_ray_normal(mouse_pos)
	var new_cursor_point = drag_plane.intersects_ray(from, drag_ray)
	
	if new_cursor_point != null:
		var distance_from_obj = abs(selected_object.global_position.distance_to(new_cursor_point))
		if distance_from_obj <= max_dist_from_obj:
			trajectory_pointer.global_position = new_cursor_point
		else:
			var ray = ((new_cursor_point as Vector3) - selected_object.global_position).normalized()
			trajectory_pointer.global_position = (selected_object.global_position + ray * max_dist_from_obj)
		
		# generate line
		if current_line != null:
			current_line.queue_free()
		var mesh_instance = generate_line(selected_object.global_position, trajectory_pointer.global_position)	
		current_line = mesh_instance
		get_tree().get_root().add_child(mesh_instance)

func launch_object():
	var Explosion_Dir = (trajectory_pointer.global_position - selected_object.global_position)
	selected_object.apply_impulse(Explosion_Dir * Force_Modifier)
	switch_to_select_object()

func switch_to_select_object():
	selected_object = null
	trajectory_pointer.queue_free()
	trajectory_pointer = null
	current_line.queue_free()
	current_line = null
	object_mode = ObjectMode.SelectObject

func calculate_plane():
	if trajectory_pointer != null:
		drag_plane = Plane(-camera.global_transform.basis.z, trajectory_pointer.global_position)

func generate_line(from: Vector3, to: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var draw_mesh = ImmediateMesh.new()
	var material = ORMMaterial3D.new()
	
	mesh_instance.mesh = draw_mesh
	mesh_instance.cast_shadow = false
	
	draw_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	draw_mesh.surface_add_vertex(from)
	draw_mesh.surface_add_vertex(to)
	draw_mesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.RED

	return mesh_instance

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
				selected_object = clicked_object
				object_mode = ObjectMode.SelectTrajectory
				
				trajectory_pointer = trajectory_cursor_type.instantiate()
				trajectory_pointer.global_position = selected_object.get_global_transform().origin
				add_child(trajectory_pointer)
				calculate_plane()

func _on_player_capture_item(body: Node3D) -> void:
	if done_shopping:
		return
	
	if body == selected_object:
		switch_to_select_object()
	
	var object_name = body.object_name
	if object_name in shopping_list:
		items_taken = true
		shopping_list[object_name] -= 1
		if shopping_list[object_name] == 0:
			shopping_list.erase(object_name)
		emit_signal("Update_Shopping_List", shopping_list)
		body.queue_free()
		
	if len(shopping_list.keys()) == 0:
		done_shopping = true


func _on_end_game_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if items_taken == false:
			emit_signal("Update_Ending", "BadEnding")
		elif checked_out == false:
			emit_signal("Update_Ending", "RetardEnding")
		elif checked_out == true:
			emit_signal("Update_Ending", "GoodEnding")

func _on_checkout_area_target_stayed(body: Node3D) -> void:
	if done_shopping:
		checked_out = true
		emit_signal("Update_Shopping_Notify_Exit")
