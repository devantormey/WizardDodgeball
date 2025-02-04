extends RigidBody3D

#Player ID:
@export var player_id: int
@export var camera_toggle: bool = false
@export var splitscreen = false
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
@export var controller_look_sensitivity = 100

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
var crosshair_offset = Vector2(-16,-15)

# This is the pickup cast I named it dumb
@onready var shape_cast = $AimMarker/PickupShapeCast  # Reference the ShapeCast3D node
# ShapeCast for Aiming
@onready var aim_cast = $AimMarker/AimShapeCast

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

# Clothing and Items
@export var hat: PackedScene
var equipped_hat: Node3D  # Store the instantiated hat

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
		"toggle_ragdoll": "player1_toggle_ragdoll",
		"look_up"    : "player_1_look_up",
		"look_down"  : "player_1_look_down",
		"look_left"  : "player_1_look_left",
		"look_right" : "player_1_look_right"
	},
	2: {
		"move_forward": "player_2_move_forward",
		"move_back": "player_2_move_back",
		"move_left": "player_2_move_left",
		"move_right": "player_2_move_right",
		"primary_action": "player_2_primary_action",
		"secondary_action": "player_2_secondary_action",
		"sprint": "player_2_sprint",
		"toggle_ragdoll": "player2_toggle_ragdoll",
		"look_up"    : "player_2_look_up",
		"look_down"  : "player_2_look_down",
		"look_left"  : "player_2_look_left",
		"look_right" : "player_2_look_right"
	}
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#READY FUNCTION
func _ready():
	
	#set the camera up
	camera_pivot.player_id = player_id
	camera_pivot.camera.current = camera_toggle
	camera_pivot.topNode = self
	camera_pivot.controller_sensitivity = controller_look_sensitivity
	
	$CursorControl.player_id = player_id
	$CursorControl.splitscreen = splitscreen
	# Initialize physical skeleton
	physical_skel.physical_bones_start_simulation()
	physics_bones = physical_skel.get_children().filter(func(x): return x is PhysicalBone3D)
	
	# Batch Set bone attributes
	set_bone_damping()
	
	# Duplicate the face material so each player has their own
	face_material = face_mesh.get_active_material(0).duplicate()
	face_mesh.set_surface_override_material(0, face_material)
	
	#Facial Animation Prep
	randomize()  # Ensure randomness
	# Set random initial timer durations
	blink_timer.wait_time = randf_range(3.0, 6.0)
	# Connect timer signals
	blink_timer.start()
	
	#clothes stuff
	if hat != null:
		equipped_hat = hat.instantiate()
		head_bone.add_child(equipped_hat)
		# Reset the transform to ensure proper positioning
		equipped_hat.transform = Transform3D()
		# Apply a rotation offset to correct orientation (adjust if needed)
		equipped_hat.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90)) 
	
	aim_direction = aim_cast.global_transform.basis.z 
		
#PHYSICS PROCESS (FASTEST UPDATE)
func _physics_process(delta):
	if hat != null:
		# Reset the transform to ensure proper positioning
		equipped_hat.transform = Transform3D()
		# Apply a rotation offset to correct orientation (adjust if needed)
		equipped_hat.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90)) 
		
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
		body_bone.apply_central_impulse(linear_force * delta)
		
		# Apply the same logic to the other pinned bones
		pin_bones_to_marker(left_hip_pin,leftHip_bone, pin_spring_stiffness, pin_spring_damping, delta)
		pin_bones_to_marker(right_hip_pin,rightHip_bone, pin_spring_stiffness, pin_spring_damping,delta)	
		pin_bones_to_marker(left_shoulder_pin,leftShoulder_bone, pin_spring_stiffness, pin_spring_damping,delta)
		pin_bones_to_marker(right_shoulder_pin,rightShoulder_bone, pin_spring_stiffness, pin_spring_damping,delta)
		pin_bones_to_marker(left_leg_pin,left_leg_bone, pin_spring_stiffness/20, pin_spring_damping/10, delta)
		pin_bones_to_marker(right_leg_pin,right_leg_bone, pin_spring_stiffness/20, pin_spring_damping/10,delta)
		pin_bones_to_marker(left_arm_pin,left_arm_bone, pin_spring_stiffness/40, pin_spring_damping/10, delta)
		if is_throwing:
			pin_bones_to_marker(picked_dodgeball,right_arm_bone, pin_spring_stiffness/60, pin_spring_damping/40,delta)
		else:
			pin_bones_to_marker(right_arm_pin,right_arm_bone, pin_spring_stiffness/40, pin_spring_damping/10,delta)
		
# PROCESS FUNCTION (NON PHYSICS)
func _process(_delta):
	
	handle_input()
	#Update the pickupShapeCast
	shape_cast.global_transform = camera_pivot.global_transform
	shape_cast.rotation.y += deg_to_rad(180)
	shape_cast.rotation.x = -shape_cast.rotation.x
	#Update the aim ShapeCast
	aim_cast.global_transform = camera_pivot.global_transform
	aim_cast.rotation.y += deg_to_rad(180)
	aim_cast.rotation.x = -aim_cast.rotation.x
	
	if !ragdoll_mode:
		move_character(_delta)		
		#handle_camera_swivel(_delta)
		check_for_dodgeball_pickup()
		
		if picked_dodgeball != null and !is_throwing:
			picked_dodgeball.global_transform = dodgeball_marker.global_transform

		handle_dodgeball_throw(_delta)
	else:
		set_expression("dead")

#~~~~~~~~~~~~~~ Character Control Functions ~~~~~~~~~~~~~
#input handling
func handle_input():
	if Input.is_action_just_pressed(input_map[player_id]["toggle_ragdoll"]):
		ragdoll_mode = !ragdoll_mode
		if ragdoll_mode == false:
			reset_bone_positions()
			set_expression("forward")
			
	if !ragdoll_mode:
			
		velocity = Vector3.ZERO

		# Check for movement inputs
		if Input.is_action_pressed(input_map[player_id]["move_forward"]):
			set_expression("forward")
			velocity.z += 1
		if Input.is_action_pressed(input_map[player_id]["move_back"]):
			velocity.z -= 1
			set_expression("forward")
		if Input.is_action_pressed(input_map[player_id]["move_left"]):
			velocity.x += 1
			set_expression("left")
		if Input.is_action_pressed(input_map[player_id]["move_right"]):
			velocity.x -= 1
			set_expression("right")

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
		movement = global_transform.basis*movement
		move_and_collide(movement)
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
	else:
		# Regular movement
		var current_speed = move_speed
		var movement = velocity * current_speed * delta
		movement = global_transform.basis*movement
		move_and_collide(movement)
		
func set_expression(expression: String):
	if face_animation_map.has(expression):
		var expression_vec = face_animation_map[expression]
		face_material.set_shader_parameter("expression_index", expression_vec)
		current_expression = expression

#~~~~~~~~~~~~~~ Combat Functions ~~~~~~~~~~~~~
func check_for_dodgeball_pickup():
	if picked_dodgeball == null and Input.is_action_just_pressed(input_map[player_id]["secondary_action"]):
		# Align the ShapeCast3D with the camera direction
		shape_cast.global_transform = camera_pivot.global_transform
		shape_cast.rotation.y += deg_to_rad(180)
		shape_cast.rotation.x = -shape_cast.rotation.x
		# Move the cast forward in the direction the camera is looking
		#shape_cast.target_position = -shape_cast.transform.basis.z * 20.0  # Adjust range as needed

		# Force an update so the new direction takes effect
		shape_cast.force_shapecast_update()

		for i in range(shape_cast.get_collision_count()):
			var collider = shape_cast.get_collider(i)

			if collider is RigidBody3D and collider.name.begins_with("DodgeBall"):
				picked_dodgeball = collider
				picked_dodgeball.global_transform = dodgeball_marker.global_transform
				has_ball = true
				pull_back_progress = 0.0
				picked_dodgeball.ball_owner = player_id
				break  # Stop after picking up the first dodgeball

# Handle dodgeball throw mechanics
func handle_dodgeball_throw(delta):

	if has_ball and Input.is_action_pressed(input_map[player_id]["primary_action"]):

		# Gradually pull the dodgeball back
		if not is_throwing:
			# Initial setup for the throw, grab viewport, player position etc
			#var viewport_center = get_viewport().get_size() / 2
			##Input.warp_mouse(viewport_center)
			#Input.warp_mouse($CursorControl/CursorTextureRect.position)
			initial_player_position = global_transform.origin
		# This calculates how far the ball should be pulled back 
		
		aim_cast.global_transform = camera_pivot.global_transform
		aim_cast.rotation.y += deg_to_rad(180)
		aim_cast.rotation.x = -aim_cast.rotation.x
		# Move the cast forward in the direction the camera is looking
		#shape_cast.target_position = -shape_cast.transform.basis.z * 20.0  # Adjust range as needed

		# Force an update so the new direction takes effect
		aim_cast.force_shapecast_update()
		
		pull_back_progress = min(pull_back_progress + SLIDE_BACK_SPEED * delta, SLIDE_BACK_DIST)
		is_throwing = true

		# Default aim direction: Use AimMarker's full global orientation
		aim_direction = aim_cast.global_transform.basis.z

		# If the shape cast hits something, use that position to aim
		if aim_cast.get_collision_count() > 0:
			var aimPoint = aim_cast.get_collision_point(0)  # Get first collision
			aim_direction = (aimPoint - picked_dodgeball.global_transform.origin).normalized()


		DebugDraw3D.draw_line(picked_dodgeball.global_transform.origin, picked_dodgeball.global_transform.origin + (aim_direction * 100), Color.GREEN)


		#DebugDraw3D.draw_line(picked_dodgeball.global_transform.origin, picked_dodgeball.global_transform.origin + 100*aim_direction, Color.GREEN)
		var player_movement_delta = global_transform.origin - initial_player_position
		var offset_transform = dodgeball_marker.global_transform
		
		# Here I basically pull the ball back in the opposite direction as the player is aiming, but I only really care about the z for now
		var pullbackdirection = aim_direction
		#pullbackdirection.x = 0
		#pullbackdirection.y = 0
		pullbackdirection = pullbackdirection.normalized()
		
		# Here I am basically moving the ball back and trying to account for the player having moved so the ball doesn't appear stuck in space
		offset_transform.origin -= pullbackdirection*(pull_back_progress)
		offset_transform.origin += player_movement_delta
		picked_dodgeball.global_transform = offset_transform
		initial_player_position = global_transform.origin

	elif has_ball and Input.is_action_just_released(input_map[player_id]["primary_action"]):	
		print("aim direction: ",aim_direction)
		print("throw force: ",picked_dodgeball.THROW_FORCE)
		print("pullback progress: ",pull_back_progress)
		var force = aim_direction * picked_dodgeball.THROW_FORCE * pull_back_progress

		# Ensure force is always applied in the correct direction
		if force.y < 0:
			force.y = 0  # Prevent downward throws

		# Add a slight upward boost
		force.y += 7 * pull_back_progress

		print("Final Throw Force:", force)

		# Move the ball slightly forward before applying impulse
		picked_dodgeball.global_transform.origin += aim_direction * 0.5
		picked_dodgeball.global_transform.origin += aim_direction * 0.5
		# Apply force
		picked_dodgeball.apply_central_impulse(force)

		# Reset throwing state
		picked_dodgeball = null
		has_ball = false
		pull_back_progress = 0.0
		is_throwing = false


# Drop or place dodgeball (if needed)
func drop_dodgeball():
	if picked_dodgeball != null:
		picked_dodgeball.ball_owner = null
		#picked_dodgeball.set_as_toplevel(false)
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
	var k = 0
	while k < 4:
		physical_skel.global_transform = $".".global_transform
		static_skel.global_transform = $".".global_transform
		for i in range(physics_bones.size()):
			var active_bone = physics_bones[i]
			var static_bone_position = static_skel.get_bone_pose_position(i)
			#print("active Bone position: ", active_bone.position)
			#print("static Bone position: ", static_bone_position)
			#print("static bone pos adjusted: ", static_bone_position*static_skel.global_basis)
			active_bone.global_position = static_bone_position
		k +=1

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
