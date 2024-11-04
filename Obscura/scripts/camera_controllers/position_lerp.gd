class_name PositionLerp
extends CameraControllerBase

@export var follow_speed: float = 2.0  
@export var catchup_speed: float = 5.0  
@export var leash_distance: float = 3.0  

var is_current: bool = false

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
	print(draw_camera_logic)
	if draw_camera_logic:
		draw_logic()
	
	var desired_position = Vector3(
		target.global_position.x,
		global_position.y, 
		target.global_position.z,
	)

	var distance_to_target = global_position.distance_to(desired_position)
	
	var is_moving = target.velocity.length() > 0.001
	
	var next_camera_position: Vector3
	if is_moving:
		next_camera_position = global_position.lerp(desired_position, follow_speed * delta)
	else:
		next_camera_position = global_position.lerp(desired_position, catchup_speed * delta)
		
	if distance_to_target > leash_distance:
		next_camera_position = global_position.lerp(desired_position, (catchup_speed) * delta)
	
	global_position = next_camera_position
	
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
