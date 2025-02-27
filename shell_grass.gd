extends Node3D

var num_layers = 64
var layer_spacing = 0.005
var layer_count = 1

func _ready():	
	# Spawn first plane manually
	spawn_plane(0)
	spawn_a_bunch()

func _process(delta):
	if Input.is_action_just_pressed("num1"):
		spawn_plane(layer_count * layer_spacing)
		layer_count += 1

func spawn_a_bunch():
	for i in range(1,num_layers):
		spawn_plane(layer_count*layer_spacing)
		layer_count+=1

func spawn_plane(y_pos: float):
	var plane = preload("res://grass_layer.tscn").instantiate()
	plane.position.y = y_pos
	add_child(plane)

	# Get the ShaderMaterial and create a unique instance per plane
	var original_material = plane.get_surface_override_material(0)
	if original_material:
		var material_instance = original_material.duplicate()  # Clone material
		plane.set_surface_override_material(0, material_instance)  # Apply unique material
		material_instance.set_shader_parameter("layer_height", y_pos)

		print("Plane pos: ", y_pos)
		print("Shader Height: ", material_instance.get_shader_parameter("layer_height"))
