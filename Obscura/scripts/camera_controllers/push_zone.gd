class_name PushZone
extends CameraControllerBase

@export var push_ratio: float = 1.5
@export var pushbox_top_left: Vector3
@export var pushbox_bottom_right: Vector3
@export var speedup_zone_top_left: Vector3
@export var speedup_zone_bottom_right: Vector3
@export var pushbox_size:float
@export var speedup_size:float

var target_velocity: Vector3 = Vector3.ZERO
var previous_target_position: Vector3 = Vector3.ZERO
var is_current:bool = false

func _ready():
	super()
	position = target.global_position

func _process(delta: float) -> void:
	if !current:
		is_current = false
		return

	if !is_current:
		global_position = target.global_position
		is_current = true
	
	if draw_camera_logic:
		draw_logic()
		
	calculate_bounds()
	# Check if the target is within the inner speedup zone.
	if check_inner():
		print("inside inner box")
		# Target is fully within the speedup zone; don't move the camera.
		target_velocity = Vector3.ZERO
		return

	# Check if the target is in the area between the speedup zone and the outer pushbox.
	if check_speed_up_zone():
		# Target is in the intermediate area; move the camera at reduced speed (push_ratio).
		target_velocity = target.velocity * push_ratio
	elif check_touching_pushbox():
		# Target is touching one or two edges of the pushbox.
		target_velocity = calculate_pushbox_velocity()
	else:
		# Default to target's full speed if outside the pushbox.
		target_velocity = target.velocity
	# Apply camera movement
	global_position += target_velocity * delta
	super(delta)
	
func check_inner() -> bool:
	#Function to calculate if the target is in the inner box.
	var posx = target.global_position.x
	var posz = target.global_position.z
	var left = speedup_zone_top_left.x
	var right = speedup_zone_bottom_right.x
	var up = speedup_zone_top_left.z
	var down = speedup_zone_bottom_right.z

	return posx > left and posx < right and posz < down and posz > up

func check_speed_up_zone() -> bool:
	#Function to calculate if the target is in the speedup zone.
	var posx = target.global_position.x
	var posz = target.global_position.z

	var inner_left = speedup_zone_top_left.x
	var inner_right = speedup_zone_bottom_right.x
	var inner_up = speedup_zone_top_left.z
	var inner_down = speedup_zone_bottom_right.z

	var outer_left = pushbox_top_left.x
	var outer_right = pushbox_bottom_right.x
	var outer_up = pushbox_top_left.z
	var outer_down = pushbox_bottom_right.z

	return posx < inner_left and posx > outer_left and posx > inner_right and posx < outer_right and posz > inner_down and posz < inner_up and posz < outer_down and posz > outer_up

func check_touching_pushbox() -> bool:
	#Function to check if the target is touching the outer push box. 
	var posx = target.global_position.x
	var posz = target.global_position.z

	var outer_left = pushbox_top_left.x
	var outer_right = pushbox_bottom_right.x
	var outer_up = pushbox_top_left.z
	var outer_down = pushbox_bottom_right.z

	return posx == outer_left or posx == outer_right or posz == outer_up or posz == outer_down

func calculate_pushbox_velocity() -> Vector3:
	#Function to calculate the speed at which the camera should be moving.
	var posx = target.global_position.x
	var posz = target.global_position.z

	var outer_left = pushbox_top_left.x
	var outer_right = pushbox_bottom_right.x
	var outer_up = pushbox_top_left.z
	var outer_down = pushbox_bottom_right.z

	# Detect if the target is touching two edges (corner)
	var touching_left = posx == outer_left
	var touching_right = posx == outer_right
	var touching_up = posz == outer_up
	var touching_down = posz == outer_down
	
	var velocity = Vector3.ZERO
	
	if (touching_left or touching_right) and (touching_up or touching_down):
		# Target is in a corner, move at full target speed in both x and z directions
		velocity.x = target.velocity.x
		velocity.z = target.velocity.z
	else:
		# Target is touching only one side, adjust speed based on which edge is touched
		if touching_left or touching_right:
			velocity.x = target.velocity.x
			velocity.z = target.velocity.z * push_ratio
		elif touching_up or touching_down:
			velocity.z = target.velocity.z
			velocity.x = target.velocity.x * push_ratio

	return velocity

func calculate_bounds() -> void:
	#Function to calculate the bounds of the boxes. 
	var camera_pos = global_position
	# Outer pushbox bounds
	pushbox_top_left = camera_pos - Vector3(pushbox_size, global_position.y, pushbox_size)
	pushbox_bottom_right = camera_pos + Vector3(pushbox_size, global_position.y, pushbox_size)

	# Inner speedup zone bounds
	speedup_zone_top_left = camera_pos - Vector3(speedup_size, global_position.y, speedup_size)
	speedup_zone_bottom_right = camera_pos + Vector3(speedup_size, global_position.y, speedup_size)


func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Calculate the corners of the outer pushbox
	var outer_left: float = pushbox_top_left.x
	var outer_right: float = pushbox_bottom_right.x
	var outer_top: float = pushbox_top_left.z
	var outer_bottom: float = pushbox_bottom_right.z

	# Calculate the corners of the inner speedup zone
	var inner_left: float = speedup_zone_top_left.x
	var inner_right: float = speedup_zone_bottom_right.x
	var inner_top: float = speedup_zone_top_left.z
	var inner_bottom: float = speedup_zone_bottom_right.z

	# Draw outer pushbox
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(outer_left, 0, outer_top))
	immediate_mesh.surface_add_vertex(Vector3(outer_right, 0, outer_top))
	immediate_mesh.surface_add_vertex(Vector3(outer_right, 0, outer_top))
	immediate_mesh.surface_add_vertex(Vector3(outer_right, 0, outer_bottom))
	immediate_mesh.surface_add_vertex(Vector3(outer_right, 0, outer_bottom))
	immediate_mesh.surface_add_vertex(Vector3(outer_left, 0, outer_bottom))
	immediate_mesh.surface_add_vertex(Vector3(outer_left, 0, outer_bottom))
	immediate_mesh.surface_add_vertex(Vector3(outer_left, 0, outer_top))

	# Draw inner speedup zone
	immediate_mesh.surface_add_vertex(Vector3(inner_left, 0, inner_top))
	immediate_mesh.surface_add_vertex(Vector3(inner_right, 0, inner_top))
	immediate_mesh.surface_add_vertex(Vector3(inner_right, 0, inner_top))
	immediate_mesh.surface_add_vertex(Vector3(inner_right, 0, inner_bottom))
	immediate_mesh.surface_add_vertex(Vector3(inner_right, 0, inner_bottom))
	immediate_mesh.surface_add_vertex(Vector3(inner_left, 0, inner_bottom))
	immediate_mesh.surface_add_vertex(Vector3(inner_left, 0, inner_bottom))
	immediate_mesh.surface_add_vertex(Vector3(inner_left, 0, inner_top))
	
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK  
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)


	await get_tree().process_frame
	mesh_instance.queue_free()
