class_name PositionLock
extends CameraControllerBase


@export var box_width:float = 5.0
@export var box_height:float = 5.0


func _ready() -> void:
	super()
	position = target.position
	

func _process(delta: float) -> void:
	if !current:
		return
	print(draw_camera_logic)
	if draw_camera_logic:
		draw_logic()
	
	#Setting position to target position.
	position = target.position
	global_position = target.global_position
		
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
