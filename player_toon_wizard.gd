extends Node3D

#Player ID:
@export var player_id: int
@export var camera_toggle: bool = false

#~~~~ Skeletons
@onready var physical_skel = $ActiveArmature/Armature/Skeleton3D
@onready var static_skel = $PassiveArmature/Armature/Skeleton3D
@onready var physics_bones = []

#~~~~ Physics Bones Settings
@onready var bone_angular_damping = 40.0
@onready var bone_linear_damping = 0.4

#~~~~ Ragdoll Mode (for when you get hit)
@onready var ragdoll_mode = false

#~~~~ Spring constants
@export var angular_spring_stiffness: float = 4500.0
@export var angular_spring_damping: float = 90.0
@export var max_angular_force: float = 9999.0
@export var current_delta = 0.0

#~~~~ Key Bones that we will specifically need
@onready var head_pin = $HeadPin #pins the head to a spot within the player character for movement
@onready var head_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone head"
@onready var body_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone Body"
@onready var leftHip_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone hip_l"
@onready var rightHip_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone hip_r"
@onready var leftShoulder_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone shoulder_l"
@onready var rightShoulder_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone shoulder_r"
@onready var left_leg_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone leg_l"
@onready var right_leg_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone leg_r"
@onready var left_arm_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone arm_l"
@onready var right_arm_bone = $"ActiveArmature/Armature/Skeleton3D/Physical Bone arm_r"

#~~~~ Body Pin Points to avoid weird behavior
@onready var left_leg_pin = $PassiveArmature/LeftLegPin
@onready var right_leg_pin = $PassiveArmature/RightLegPin
@onready var left_hip_pin = $PassiveArmature/LeftHipPin
@onready var right_hip_pin = $PassiveArmature/RightHipPin
@onready var left_shoulder_pin = $PassiveArmature/LeftShoulderPin
@onready var right_shoulder_pin = $PassiveArmature/RightShoulderPin
@onready var left_arm_pin = $PassiveArmature/LeftArmPin
@onready var right_arm_pin = $PassiveArmature/RightArmPin

#~~~~ Specific Spring Values
@onready var neck_spring_stiffness = 4500
@onready var neck_spring_damping = 90.0
@onready var pin_spring_stiffness = 4500
@onready var pin_spring_damping = 90.0

#~~~~ Variables to track movement
var is_moving = false
var velocity: Vector3 = Vector3.ZERO
var is_dodging: bool = false
var dodge_timer: float = 0.0
@export var dodge_duration: float = 0.3  # Duration of the dodge in seconds

#~~~~ Movement speed parameters
@export var move_speed: float = 8.0
@export var dodge_speed: float = 25.0
@export var movethreshold: float = 0.1

#~~~~ Camera Variables
@onready var camera_pivot = $CameraPivot

#~~~~ Combat Variables
#constants
var current_offset_transform #offset transform for ball
const RAY_LENGTH = 1000
const THROW_FORCE = 40.0
const SLIDE_BACK_SPEED = 2.4  # Speed of the ball sliding back
const SLIDE_BACK_DIST = 2
var pull_back_progress: float = 0.0  # Tracks the progress of the pull-back
var aim_direction 
var initial_player_position: Vector3 = Vector3.ZERO


@onready var is_throwing: bool = false
#variable to track picked dodgeball
@onready var picked_dodgeball: RigidBody3D = null
@onready var has_ball: bool = false
@onready var dodgeball_marker = $DodgeballMarker

#~~~~ Camera Rotation Variables
@export var rotation_speed: float = 20.0  # Degrees per second
@export var vertical_rotation_speed: float = 10.0  # Degrees per second
@export var vertical_rotation_limit: float = 45.0  # Maximum vertical rotation in degrees
var vertical_rotation: float = 0.0 # Track vertical rotation to clamp within limits


# Facial Animation Variables
@onready var face_mesh = $ActiveArmature/Armature/Skeleton3D/BodyMesh # Adjust path as needed
@onready var face_material = face_mesh.get_active_material(0) # Get material from Surface 0
@onready var blink_timer = $BlinkTimer
@onready var unblink_timer = $UnBlinkTimer
@onready var look_timer = $LookTimer 

@onready var face_animation_map = {
	"forward": [0, 0],
	"left": [0, 1],
	"right": [0, 2],
	"blink": [1, 0],
	"dead": [1, 1],
}
var current_expression = "forward"
@onready var last_expression = "forward"

# Player ID Input Map
var input_map = {
	1: {
		"move_forward": "player1_move_forward",
		"move_back": "player1_move_back",
		"move_left": "player1_move_left",
		"move_right": "player1_move_right",
		"primary_action": "player1_primary_action",
		"secondary_action": "player1_secondary_action",
		"sprint": "player1_sprint",
		"toggle_ragdoll": "player1_toggle_ragdoll"
	},
	2: {
		"move_forward": "player2_move_forward",
		"move_back": "player2_move_back",
		"move_left": "player2_move_left",
		"move_right": "player2_move_right",
		"primary_action": "player2_primary_action",
		"secondary_action": "player2_secondary_action",
		"sprint": "player2_sprint",
		"toggle_ragdoll": "player2_toggle_ragdoll"
	}
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#READY FUNCTION
func _ready():
	#set the camera up
	camera_pivot.player_id = player_id
	camera_pivot.camera.current = camera_toggle
	# Initialize physical skeleton
	physical_skel.physical_bones_start_simulation()
	physics_bones = physical_skel.get_children().filter(func(x): return x is PhysicalBone3D)
	
	# Batch Set bone attributes
	set_bone_damping()
	
	#Facial Animation Prep
	randomize()  # Ensure randomness
	# Set random initial timer durations
	blink_timer.wait_time = randf_range(3.0, 6.0)
	# Connect timer signals
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	blink_timer.start()

#PHYSICS PROCESS (FASTEST UPDATE)
func _physics_process(delta):
	current_delta = delta
	if not ragdoll_mode:# if not in ragdoll mode
		# rotate the physical bones toward the animated bones rotations using hookes law
		for b:PhysicalBone3D in physics_bones:
			var target_transform: Transform3D = static_skel.global_transform * static_skel.get_bone_global_pose(b.get_bone_id())
			var current_transform: Transform3D = physical_skel.global_transform * physical_skel.get_bone_global_pose(b.get_bone_id())
			var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
			var torque = hookes_law(rotation_difference.get_euler(), b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
			torque = torque.limit_length(max_angular_force)
			b.angular_velocity += torque * delta
		
		#Pin the Head to the marker
		head_bone.global_position = head_pin.global_position
		
		# Move the body Bone closer to the head (this has it's own section because it's custom)
		var target_position = head_bone.global_position + Vector3(0, -1.3, 0) # Slight offset downwards
		var displacement = target_position - body_bone.global_position
		var linear_force = hookes_law(displacement, body_bone.linear_velocity, neck_spring_stiffness, neck_spring_damping)
		body_bone.apply_central_impulse(linear_force * current_delta)
		
		# Apply the same logic to the other pinned bones
		pin_bones_to_marker(left_hip_pin,leftHip_bone, pin_spring_stiffness, pin_spring_damping, current_delta)
		pin_bones_to_marker(right_hip_pin,rightHip_bone, pin_spring_stiffness, pin_spring_damping,current_delta)	
		pin_bones_to_marker(left_shoulder_pin,leftShoulder_bone, pin_spring_stiffness, pin_spring_damping,current_delta)
		pin_bones_to_marker(right_shoulder_pin,rightShoulder_bone, pin_spring_stiffness, pin_spring_damping,current_delta)
		pin_bones_to_marker(left_leg_pin,left_leg_bone, pin_spring_stiffness/20, pin_spring_damping/10, current_delta)
		pin_bones_to_marker(right_leg_pin,right_leg_bone, pin_spring_stiffness/20, pin_spring_damping/10,current_delta)
		pin_bones_to_marker(left_arm_pin,left_arm_bone, pin_spring_stiffness/40, pin_spring_damping/10, current_delta)
		if is_throwing:
			pin_bones_to_marker(picked_dodgeball,right_arm_bone, pin_spring_stiffness/60, pin_spring_damping/40,current_delta)
		else:
			pin_bones_to_marker(right_arm_pin,right_arm_bone, pin_spring_stiffness/40, pin_spring_damping/10,current_delta)
		
# PROCESS FUNCTION (NON PHYSICS)
func _process(_delta):
	
	handle_input(_delta)
	
	if !ragdoll_mode:
		move_character(_delta)
		if Input.is_action_just_pressed(input_map[player_id]["move_forward"]):
			set_expression("forward")
		elif Input.is_action_just_pressed(input_map[player_id]["move_right"]):
			set_expression("right")
		elif Input.is_action_just_pressed(input_map[player_id]["move_left"]):
			set_expression("left")
		
		handle_camera_swivel(_delta)
		check_for_dodgeball_pickup()
		
		if picked_dodgeball != null and !is_throwing:
			picked_dodgeball.global_transform = dodgeball_marker.global_transform

		handle_dodgeball_throw(_delta)
	else:
		set_expression("dead")

#~~~~~~~~~~~~~~ Character Control Functions ~~~~~~~~~~~~~
#input handling
func handle_input(delta):
	if Input.is_action_just_pressed(input_map[player_id]["toggle_ragdoll"]):
		ragdoll_mode = !ragdoll_mode
		if ragdoll_mode == false:
			reset_bone_positions()
			
	if !ragdoll_mode:
			
		velocity = Vector3.ZERO

		# Check for movement inputs
		if Input.is_action_pressed(input_map[player_id]["move_forward"]):
			velocity.z += 1
		if Input.is_action_pressed(input_map[player_id]["move_back"]):
			velocity.z -= 1
		if Input.is_action_pressed(input_map[player_id]["move_left"]):
			velocity.x += 1
		if Input.is_action_pressed(input_map[player_id]["move_right"]):
			velocity.x -= 1

		if Input.is_action_just_pressed(input_map[player_id]["sprint"]) and not is_dodging:
			is_dodging = true
			dodge_timer = dodge_duration
			velocity *= dodge_speed
			
		# Normalize velocity to prevent faster diagonal movement
		velocity = velocity.normalized()
		if velocity.length() > movethreshold:
			is_moving = true
		else:
			is_moving = false

# Apply movement based on input
func move_character(delta):
	if is_dodging:
		# Handle dodge movement
		var current_speed = dodge_speed
		var movement = velocity * current_speed * delta
		translate(movement)
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
	else:
		# Regular movement
		var current_speed = move_speed
		var movement = velocity * current_speed * delta
		translate(movement)
		
func set_expression(expression: String):
	if face_animation_map.has(expression):
		var expression_vec = face_animation_map[expression]
		face_material.set_shader_parameter("expression_index", expression_vec)
		current_expression = expression
		
func handle_camera_swivel(delta):
	var mouse_delta = Input.get_last_mouse_velocity()

	# Rotate the top node based on horizontal mouse movement
	self.rotate_y(deg_to_rad(-mouse_delta.x * rotation_speed * delta * 0.01))

	# Adjust vertical rotation with clamping
	vertical_rotation -= mouse_delta.y * vertical_rotation_speed * delta * 0.01
	vertical_rotation = clamp(vertical_rotation, -vertical_rotation_limit, vertical_rotation_limit)


	
#~~~~~~~~~~~~~~ Combat Functions ~~~~~~~~~~~~~
func check_for_dodgeball_pickup():
	if picked_dodgeball == null and Input.is_action_just_pressed(input_map[player_id]["secondary_action"]):
		#This is a bunch of raycast code I stole
		var viewport_center = get_viewport().get_size() / 2
		Input.warp_mouse(viewport_center)
		var space_state = get_world_3d().direct_space_state
		var mousepos = get_viewport().get_mouse_position()
		var origin = camera_pivot.camera.project_ray_origin(mousepos)
		var end = origin + camera_pivot.camera.project_ray_normal(mousepos) * 200
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		
		# Basically if you cast a ray until it intersect something and if that something is a ball pick it up
		var result = space_state.intersect_ray(query)
		print(result)
		if result.has("collider") and result["collider"] is RigidBody3D and result["collider"].name.begins_with("DodgeBall"):
			# Check if the thing the ray hit is a ball and move it to the marker
			picked_dodgeball = result["collider"] as RigidBody3D
			picked_dodgeball.global_transform = dodgeball_marker.global_transform
			has_ball = true
			pull_back_progress = 0.0
			picked_dodgeball.ball_owner = player_id


# Handle dodgeball throw mechanics
func handle_dodgeball_throw(delta):

	if has_ball and Input.is_action_pressed(input_map[player_id]["primary_action"]):

		# Gradually pull the dodgeball back
		if not is_throwing:
			# Initial setup for the throw, grab viewport, player position etc
			var viewport_center = get_viewport().get_size() / 2
			Input.warp_mouse(viewport_center)
			initial_player_position = global_transform.origin
		# This calculates how far the ball should be pulled back 
		pull_back_progress = min(pull_back_progress + SLIDE_BACK_SPEED * delta, SLIDE_BACK_DIST)
		is_throwing = true
		
		
		# Determine the aiming direction based on the mouse position
		var mousepos = get_viewport().get_mouse_position()
		var ray_origin = camera_pivot.camera.project_ray_origin(mousepos)
		var ray_normal = camera_pivot.camera.project_ray_normal(mousepos)

		# Perform a raycast to find the first object hit
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		
		query.from = ray_origin
		query.to = ray_origin + ray_normal * 1000  # Raycast range, adjust as needed
		query.collide_with_areas = true
		query.collide_with_bodies = true
		
		var intersection_point = space_state.intersect_ray(query)

		#DebugDraw3D.draw_line(picked_dodgeball.global_transform.origin, intersection_point.position, Color.RED)
		if intersection_point:
			DebugDraw3D.draw_line(picked_dodgeball.global_transform.origin, intersection_point.position, Color.RED)
			
			# This code could be useful if we find that aiming low causes too many problems			
			#if intersection_point.position.y < picked_dodgeball.global_transform.origin.y - 1.0:
				#intersection_point.position.y = picked_dodgeball.global_transform.origin.y + 1.0
				
			aim_direction = (intersection_point.position - picked_dodgeball.global_transform.origin).normalized()
			DebugDraw3D.draw_line(picked_dodgeball.global_transform.origin, picked_dodgeball.global_transform.origin + 100*aim_direction, Color.GREEN)
			var player_movement_delta = global_transform.origin - initial_player_position
			var offset_transform = dodgeball_marker.global_transform
			
			# Here I basically pull the ball back in the opposite direction as the player is aiming, but I only really care about the z for now
			var pullbackdirection = aim_direction
			#pullbackdirection.x = 0
			pullbackdirection.y = 0
			pullbackdirection = pullbackdirection.normalized()
			
			# Here I am basically moving the ball back and trying to account for the player having moved so the ball doesn't appear stuck in space
			offset_transform.origin -= pullbackdirection*(pull_back_progress)
			offset_transform.origin += player_movement_delta
			picked_dodgeball.global_transform = offset_transform
			initial_player_position = global_transform.origin
			
			#DebugDraw3D.draw_line(picked_dodgeball.global_transform.origin, picked_dodgeball.global_transform.origin + aim_direction * 1000, Color.RED)
			
	elif has_ball and Input.is_action_just_released(input_map[player_id]["primary_action"]):	
		if aim_direction:
			# Apply forward force to the dodgeball
			var force = aim_direction * THROW_FORCE * pull_back_progress # Throw force is based on pull back progress
			if force.y < 0:
				force.y = 0
			# Adjusting the force upwards based on the pull back progress (more up for harder throw)
			force.y += 10*pull_back_progress
			print("force: ", force)
			picked_dodgeball.apply_central_impulse(force)
			picked_dodgeball = null
			has_ball = false
			pull_back_progress = 0.0

			is_throwing = false

# Drop or place dodgeball (if needed)
func drop_dodgeball():
	if picked_dodgeball != null:
		picked_dodgeball.ball_owner = null
		picked_dodgeball.set_as_toplevel(false)
		picked_dodgeball = null



#~~~~~~~~~~~~~~ Generic Physics Functions ~~~~~~~~~~~~~

func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)

func pin_bones_to_marker(target, bone, spring_stiffness, spring_damp, current_delta):
	var target_position = target.global_position
	var displacement = target_position - bone.global_position
	var linear_force = hookes_law(displacement, bone.linear_velocity, spring_stiffness, spring_damp)
	bone.apply_central_impulse(linear_force * current_delta)

#~~~~~~~~~~~~~ One Time Use Functions ~~~~~~~~~~~~~~~~~~~~
func set_bone_damping():
	for bone in physics_bones:
		bone.angular_damp = bone_angular_damping
		bone.linear_damp = bone_linear_damping

func reset_bone_positions():
	for i in range(physics_bones.size()):
		var active_bone = physics_bones[i]
		var static_bone = static_skel.get_child(i)

		if active_bone is PhysicalBone3D and static_bone is PhysicalBone3D:
			active_bone.global_position = static_bone.global_position

#~~~~~~~~~~~~~ Signal Connection Functions ~~~~~~~~~~~~~~~~

# Blink animation
func _on_blink_timer_timeout():
	if current_expression != "dead":
		last_expression = current_expression
		set_expression("blink")
		#set_expression(current_expression)  # Return to previous expression
		blink_timer.wait_time = randf_range(3.0, 6.0)  # Reset with new random interval	
		unblink_timer.start()
	blink_timer.start()
	
func _on_un_blink_timer_timeout():
	set_expression(last_expression)

func _on_hit_box_area_body_entered(body):
	if body is RigidBody3D and body.name.begins_with("DodgeBall"):
		if body.ball_owner != player_id and body.ball_owner != null:
			# Enable ragdoll mode
			ragdoll_mode = true  

			# Calculate the impact direction
			var impact_direction = (body.global_position - body_bone.global_position).normalized()

			# Get the dodgeball's velocity to scale the impact force
			var ball_velocity = body.linear_velocity
			var impact_force = -impact_direction * ball_velocity.length() * 5.0  # Scale force multiplier as needed

			# Apply the impulse to the body bone
			body_bone.apply_central_impulse(impact_force)
			body.ball_owner = null
			# Drop ball if you got it (the if is handled in the function)
			drop_dodgeball()

#~~~~~~~~~~~~~ Extra Goodies ~~~~~~~~~~~~~~~~

#I can use this later if I want to active ragdoll animations
#func _on_skeleton_3d_skeleton_updated():
		#if not ragdoll_mode:# if not in ragdoll mode
			## rotate the physical bones toward the animated bones rotations using hookes law
			#for b:PhysicalBone3D in physics_bones:
				##if not active_arm_left and b.name.contains("LArm"): continue # only rotated the arms if its activated
				##if not active_arm_right and b.name.contains("RArm"): continue # only rotated the arms if its activated
				#var target_transform: Transform3D = static_skel.global_transform * static_skel.get_bone_global_pose(b.get_bone_id())
				#var current_transform: Transform3D = physical_skel.global_transform * physical_skel.get_bone_global_pose(b.get_bone_id())
				#var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
				#var torque = hookes_law(rotation_difference.get_euler(), b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
				#torque = torque.limit_length(max_angular_force)
				#
				#b.angular_velocity += torque * current_delta
