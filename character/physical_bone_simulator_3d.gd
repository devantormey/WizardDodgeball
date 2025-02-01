extends PhysicalBoneSimulator3D

# Export parameters for uniform damping
@export var linear_damping: float = 1.0
@export var angular_damping: float = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	# Apply damping to all physical bones
	apply_damping_to_bones()
	physical_bones_start_simulation()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Apply uniform damping to all physical bones
func apply_damping_to_bones():
	for i in range(get_child_count()):
		var physical_bone = get_child(i)
		if physical_bone is PhysicalBone3D:
			physical_bone.linear_damp = linear_damping
			physical_bone.angular_damp = angular_damping

# Custom function to reset the physical bones
func reset_physical_bones(animated_skeleton: Skeleton3D):
	# Stop the simulation first
	physical_bones_stop_simulation()

	# Reset each physical bone to match the animated skeleton
	for i in range(get_child_count()):
		var physical_bone = get_child(i)
		if physical_bone is PhysicalBone3D:
			var bone_name = physical_bone.name.replace("Physical ", "")  # Adjust naming convention
			if animated_skeleton.has_bone(bone_name):
				var bone_transform = animated_skeleton.get_bone_global_transform(animated_skeleton.find_bone(bone_name))
				physical_bone.global_transform = bone_transform

	# Reapply damping to ensure consistency
	apply_damping_to_bones()

	# Restart the simulation
	physical_bones_start_simulation()
	#print("PhysicalBoneSimulator3D has been reset.")
