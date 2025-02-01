extends Skeleton3D

@onready var activeSkeleton = $PhysicalBoneSimulator3D
@onready var staticSkeleton = $static_PhysicalBoneSimulator3D2
@onready var topNode = $"../.."
@onready var head_bone = $"PhysicalBoneSimulator3D/Physical Bone head"
# Spring and damping constants for Hooke's Law
@export var spring_stiffness: float = 15.0
@export var damping: float = 3.0
@export var max_displacement: float = 2.0  # Maximum allowed distance for a bone to deviate
@export var reset_speed: float = 5.0  # Speed for sliding bones back to the static position
@export var max_head_displacement: float = 1.0 
@export var max_leg_displacement: float = 2.2 
@onready var body_mesh = $body

# Tracks whether the player is moving or disabled
var is_player_moving: bool = false
var is_disabled: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	is_player_moving = topNode.is_moving
	if !is_disabled:
		if is_player_moving:
			apply_hookes_law(delta)
		else:
			reset_bones_toward_static(delta)
	else:
		pass
		#print("what")
		synchronize_static_to_active()
# Apply Hooke's Law to bind the active skeleton to the static skeleton
func apply_hookes_law(delta):
	for i in range(activeSkeleton.get_child_count()):
		var active_bone = activeSkeleton.get_child(i)
		var static_bone = staticSkeleton.get_child(i)

		if active_bone is PhysicalBone3D and static_bone is PhysicalBone3D:
			# Clamp the position of the active bone to stay within max_displacement from the static bone
			var displacement = static_bone.global_transform.origin - active_bone.global_transform.origin
			if active_bone == head_bone:
				if displacement.length() > max_head_displacement:
					var clamped_position = static_bone.global_transform.origin - displacement.normalized() * max_head_displacement
					active_bone.global_transform.origin = clamped_position
			elif active_bone.name == "Physical Bone leg_l" or active_bone.name == "Physical Bone leg_r":
				if displacement.length() > max_leg_displacement:
					var clamped_position = static_bone.global_transform.origin - displacement.normalized() * max_leg_displacement
					active_bone.global_transform.origin = clamped_position
			else:
				if displacement.length() > max_displacement:
					var clamped_position = static_bone.global_transform.origin - displacement.normalized() * max_displacement
					active_bone.global_transform.origin = clamped_position

			var velocity = active_bone.linear_velocity

			# Hooke's Law: F = -kx - bv
			var spring_force = displacement * spring_stiffness
			var damping_force = -velocity * damping
			var total_force = spring_force + damping_force

			# Apply force to the active bone
			active_bone.apply_central_impulse(total_force * delta)

# Gradually reset bones to match the static skeleton when the player stops moving
func reset_bones_toward_static(delta):
	for i in range(activeSkeleton.get_child_count()):
		var active_bone = activeSkeleton.get_child(i)
		var static_bone = staticSkeleton.get_child(i)

		if active_bone is PhysicalBone3D and static_bone is PhysicalBone3D:
			# Slide position toward static bone position
			var current_position = active_bone.global_transform.origin
			var target_position = static_bone.global_transform.origin
			active_bone.global_transform.origin = current_position.lerp(target_position, reset_speed * delta)

			# Smoothly align rotation with static bone rotation
			var current_rotation = active_bone.global_transform.basis.get_rotation_quaternion()
			var target_rotation = static_bone.global_transform.basis.get_rotation_quaternion()
			var interpolated_rotation = current_rotation.slerp(target_rotation, reset_speed * delta)
			active_bone.global_transform.basis = Basis(interpolated_rotation)

# Synchronize static skeleton to active skeleton to disable it
func synchronize_static_to_active():
	for i in range(staticSkeleton.get_child_count()):
		var static_bone = staticSkeleton.get_child(i)
		var active_bone = activeSkeleton.get_child(i)

		if static_bone is PhysicalBone3D and active_bone is PhysicalBone3D:
			static_bone.global_transform = active_bone.global_transform
			#static_bone.set_simulate_physics(false)  # Stop physics simulation for static bones
			#static_bone.collision_layer = 0  # Remove collision

	#staticSkeleton.set_physics_process(false)  # Disable processing
	#print("Static skeleton synchronized to active skeleton and disabled.")

# Reset all bones to exactly match the static skeleton (for emergencies)
func reset_to_static():
	for i in range(activeSkeleton.get_child_count()):
		var active_bone = activeSkeleton.get_child(i)
		var static_bone = staticSkeleton.get_child(i)

		if active_bone is PhysicalBone3D and static_bone is PhysicalBone3D:
			active_bone.global_transform = static_bone.global_transform

	#print("Active skeleton reset to static skeleton.")
