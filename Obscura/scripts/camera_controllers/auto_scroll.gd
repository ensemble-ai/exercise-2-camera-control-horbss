class_name AutoScroll
extends CameraControllerBase

@export var top_left: Vector3
@export var bottom_right: Vector3
@export var autoscroll_speed: Vector3

@export var box_width: float = 20.0
@export var box_height: float = 10.0
@export var adjustment: float

var is_current:bool = false

func _ready() -> void:
	super()
	position = target.global_position
	calculate_bounds()
	
func _process(delta: float) -> void:
	if !current:
		is_current = false
		return
	
	if !is_current: 
		target.global_position = global_position
		is_current = true
	
	if draw_camera_logic:
		draw_logic()
	# Update camera position based on autoscroll speed
	global_position.x += autoscroll_speed.x * delta
	
	# Recalculate the bounds based on the updated camera position
	calculate_bounds()

	# Keep the target within the recalculated bounds
	if target.global_position.x < top_left.x: 
		target.global_position.x = top_left.x	
	
	if target.global_position.z < top_left.z: 
		target.global_position.z = top_left.z	
		
	if target.global_position.z > bottom_right.z: 
		target.global_position.z = bottom_right.z	
		
	if target.global_position.x > bottom_right.x: 
		target.global_position.x = bottom_right.x	

	# Draw the boundary box (camera logic)
	if draw_camera_logic:
		draw_logic()
	super(delta)

# Function to calculate and update the bounds around the camera's current position
func calculate_bounds() -> void:
	var viewport_size: Vector2 = get_tree().root.get_viewport().get_size()
	var camera_aspect_ratio: float = viewport_size.x / viewport_size.y
	var camera_height: float = dist_above_target  # Adjust this as needed
	top_left = position + adjustment * Vector3(-camera_height * camera_aspect_ratio / 2, 0, -camera_height / 2)
	bottom_right = position + adjustment * Vector3(camera_height * camera_aspect_ratio / 2, 0, camera_height / 2)

# Function to draw the boundary box
func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var left: float = top_left.x 
	var right: float = bottom_right.x 
	var top: float = top_left.z 
	var bottom: float = bottom_right.z
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	# Draw the box edges
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))    # Top left
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))   # Top right
	
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))   # Top right
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom)) # Bottom right
	
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))  # Bottom right
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))   # Bottom left
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))   # Bottom left
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))      # Top left
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	# Free the mesh instance after one frame
	await get_tree().process_frame
	mesh_instance.queue_free()
