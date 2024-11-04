class_name LeadLerp
extends CameraControllerBase

@export var lead_speed: float = target.BASE_SPEED/8  
@export var catchup_delay_duration: float = 0.2 
@export var catchup_speed: float = target.BASE_SPEED/16 
@export var leash_distance: float = 5.0 

var stop_time: float = 0.0
var leading_offset: Vector3 = Vector3.ZERO
var is_current:bool = false

func _ready() -> void:
	super()
	position = target.global_position

func _process(delta: float) -> void:
	if !current:
		is_current = false
		return
		
	if !is_current:
		position = target.global_position
		is_current = true
		
	if draw_camera_logic:
		draw_logic()
	
	# Calculate the target position for the camera with the y-axis locked.
	var target_position = Vector3(target.global_position.x, global_position.y, target.global_position.z)
	
	# Check if the target is moving.
	var is_moving = target.velocity.length() > 0
	
	if is_moving:
		# Reset stop time when moving.
		stop_time = 0.0
		
		# Calculate leading position based on velocity direction.
		leading_offset = target.velocity.normalized() * leash_distance
		var lead_target = target_position + leading_offset
		# Smoothly move camera to lead position.
		global_position.x = lerp(global_position.x, lead_target.x, lead_speed * delta)
		global_position.z = lerp(global_position.z, lead_target.z, lead_speed * delta)
	else:
		# Increase stop time while not moving.
		stop_time += delta

		# Move camera back to target position after delay.
		if stop_time >= catchup_delay_duration:
			global_position.x = lerp(global_position.x, target_position.x, catchup_speed * delta)
			global_position.z = lerp(global_position.z, target_position.z, catchup_speed * delta)
	super(delta)

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var cross_size: float = 2.5 

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	immediate_mesh.surface_add_vertex(Vector3(-cross_size, 0, 0))  
	immediate_mesh.surface_add_vertex(Vector3(cross_size, 0, 0))   

	immediate_mesh.surface_add_vertex(Vector3(0, 0, -cross_size)) 
	immediate_mesh.surface_add_vertex(Vector3(0, 0, cross_size))

	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK

	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)

	await get_tree().process_frame
	mesh_instance.queue_free()
