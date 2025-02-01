extends Node3D

# Hand animation variables
@export var idle_float_speed: float = 1.0  # Speed of floating animation in IDLE
@export var idle_float_amplitude: float = 0.02  # Amplitude of floating animation in IDLE
@export var random_front_back_amplitude: float = 0.005  # Random front-to-back amplitude
@export var random_front_back_speed: float = 0.5  # Speed of random front-to-back motion
@export var walk_swing_speed: float = 5.0  # Speed of swinging animation in WALK
@export var walk_swing_amplitude: float = 0.4  # Amplitude of swinging animation in WALK
@export var run_swing_speed: float = 8.0  # Speed of swinging animation in RUN
@export var run_swing_amplitude: float = 0.5  # Amplitude of swinging animation in RUN

# Attacking export variables
@export var arc_radius: float = 1.3  # Radius of the horizontal arc
@export var arc_speed: float = 0.01  # Speed at which the hand slides along the arc
@export var right_hand_arc_limit: float = PI / 2  # Maximum arc angle (90 degrees left/right)
@export var attack_forward_offset: float = 0.5 # Damping coefficient
@export var attack_upward_offset: float = 0.1 # Damping coefficient

# Hooke's Law parameters
@export var stiffness: float = 500.0  # Spring stiffness
@export var damping: float = 20.0  # Damping coefficient

# Attacking local variables
var right_hand_angle: float = 0.0  # Current angle of the right hand on the arc

# Hand movement/animation local variables
var time_offset_left: float = 0.0
var time_offset_right: float = 0.0
var is_attacking: bool = false

@onready var left_hand = $Left_Hand
@onready var right_hand = $Right_Hand
@onready var left_hand_rigid_body = $LeftHandRigidBody3D
@onready var right_hand_rigid_body = $RightHandRigidBody3D
@onready var attack_vertical_up_offset = 1.5
@onready var mouse_delta_y
enum {IDLE, RUN, WALK, JUMP, STRAFE_LEFT, STRAFE_RIGHT}

var left_hand_initial_pos: Vector3
var right_hand_initial_pos: Vector3

enum SwingState { NONE, HORIZONTAL, VERTICAL, IDLE }
var current_swing_state: SwingState = SwingState.NONE

func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Assign random time offsets for a desynchronized effect
	time_offset_left = randf() * 2 * PI
	time_offset_right = randf() * 2 * PI

	# Store the initial positions of the hands
	left_hand_initial_pos = left_hand.position
	right_hand_initial_pos = right_hand.position

func _physics_process(delta):
	var parent = get_parent()
	match parent.curAnim:
		parent.IDLE:
			animate_hands_idle()
		parent.WALK:
			animate_hands_walk()
		parent.RUN:
			animate_hands_run()
		parent.STRAFE_LEFT:
			animate_hands_run()
		parent.STRAFE_RIGHT:
			animate_hands_run()
		parent.JUMP:
			animate_hands_idle()

	if Input.is_action_pressed("primary_action"):
		is_attacking = true
		update_right_hand_position(delta)
	else:
		is_attacking = false
		current_swing_state = SwingState.NONE
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Apply spring force to hands
	apply_spring_force(left_hand, left_hand_rigid_body)
	apply_spring_force(right_hand, right_hand_rigid_body)

func animate_hands_idle():
	var time_seconds = Time.get_ticks_msec() / 1000.0
	var left_float_y = sin(time_seconds * idle_float_speed) * idle_float_amplitude
	var right_float_y = sin(time_seconds * idle_float_speed) * idle_float_amplitude
	var left_random_z = sin(time_seconds * random_front_back_speed + time_offset_left) * random_front_back_amplitude
	var right_random_z = sin(time_seconds * random_front_back_speed + time_offset_right) * random_front_back_amplitude
	left_hand.position = left_hand_initial_pos + Vector3(0, left_float_y, left_random_z)
	if !is_attacking:
		right_hand.position = right_hand_initial_pos + Vector3(0, right_float_y, right_random_z)

func animate_hands_walk():
	var time_seconds = Time.get_ticks_msec() / 1000.0
	var left_swing_z = sin(time_seconds * walk_swing_speed) * walk_swing_amplitude
	var right_swing_z = sin(time_seconds * walk_swing_speed + PI) * walk_swing_amplitude
	left_hand.position = left_hand_initial_pos + Vector3(0, 0, left_swing_z)
	if !is_attacking:
		right_hand.position = right_hand_initial_pos + Vector3(0, 0, right_swing_z)

func animate_hands_run():
	var time_seconds = Time.get_ticks_msec() / 1000.0
	var left_swing_z = sin(time_seconds * run_swing_speed) * run_swing_amplitude
	var right_swing_z = sin(time_seconds * run_swing_speed + PI) * run_swing_amplitude
	left_hand.position = left_hand_initial_pos + Vector3(0, 0, left_swing_z)
	if !is_attacking:
		right_hand.position = right_hand_initial_pos + Vector3(0, 0, right_swing_z)



func update_right_hand_position(delta):
	# Thresholds for detecting horizontal or vertical motion
	var motion_threshold: float = 0.5  # Adjust this to tweak sensitivity
	var distance_threshold: float = 10.0  # Adjust this to define when to pick a state
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	if Input.is_action_pressed("primary_action"):
		match current_swing_state:
			SwingState.NONE:
				# Determine swing state based on mouse velocity and movement
				
				var mouse_velocity = Input.get_last_mouse_velocity()
				print("mouse velocity: ", mouse_velocity)
				var normalized_velocity = mouse_velocity.normalized()
				print("normalized mouse velocity: ", normalized_velocity)
				# Calculate "distance" in x and y directions
				var distance_x = abs(mouse_velocity.x * delta)
				var distance_y = abs(mouse_velocity.y * delta)
				print("distance_x: ", distance_x)
				print("distance_y: ", distance_y)
				if distance_x > distance_threshold and distance_x > distance_y * motion_threshold:
					current_swing_state = SwingState.HORIZONTAL
				elif distance_y > distance_threshold and distance_y > distance_x * motion_threshold:
					current_swing_state = SwingState.VERTICAL

			SwingState.HORIZONTAL:
				# Perform horizontal swing
				update_horizontal_swing(delta)
			SwingState.VERTICAL:
				# Perform vertical swing
				update_vertical_swing(delta)
	else:
	# Reset to NONE when mouse is released
		current_swing_state = SwingState.NONE



func update_horizontal_swing(delta):
	# Get mouse horizontal movement
	var mouse_delta_x = Input.get_last_mouse_velocity().x * arc_speed * delta

	# Update the hand's angle based on mouse movement
	right_hand_angle += mouse_delta_x
	right_hand_angle = clamp(right_hand_angle, -right_hand_arc_limit, right_hand_arc_limit)

	# Apply an angular offset to rotate the arc forward
	var angle_offset = PI / 9
	var adjusted_angle = right_hand_angle - angle_offset

	# Calculate the Y offset based on the angle to create the ramping effect
	var upward_ramp = sin(adjusted_angle) * attack_upward_offset - attack_upward_offset - 0.5

	# Calculate the new hand position relative to the player's local frame
	var local_hand_position = Vector3(
		-arc_radius * cos(adjusted_angle),  # X offset
		-upward_ramp,  # Dynamic Y offset
		-arc_radius * sin(adjusted_angle) + attack_forward_offset  # Z offset
	)

	# Convert the local hand position to global space relative to the player
	var parent_transform = get_parent().global_transform
	var global_hand_position = parent_transform.basis * local_hand_position + parent_transform.origin

	# Set the hand's global position
	right_hand.global_transform.origin = global_hand_position
#
func update_vertical_swing(delta):
	# Get mouse vertical movement
	mouse_delta_y = -Input.get_last_mouse_velocity().y * arc_speed * delta

	# Update the hand's angle based on mouse movement
	right_hand_angle -= mouse_delta_y
	right_hand_angle = clamp(right_hand_angle, -right_hand_arc_limit - .5, right_hand_arc_limit + .5)

	# Apply an angular offset to rotate the arc forward
	var angle_offset = PI / 1.5
	var adjusted_angle = right_hand_angle - angle_offset

	# Calculate the Z offset based on the angle to create the ramping effect
	var forward_ramp = sin(adjusted_angle) * attack_forward_offset - attack_forward_offset

	# Calculate the new hand position relative to the player's local frame
	var local_hand_position = Vector3(
		0.0,
		-arc_radius * sin(adjusted_angle) + attack_vertical_up_offset,  # Y offset
		-arc_radius * cos(adjusted_angle) + attack_forward_offset  # Z offset
	)

	# Convert the local hand position to global space relative to the player
	var parent_transform = get_parent().global_transform
	var global_hand_position = parent_transform.basis * local_hand_position + parent_transform.origin

	# Set the hand's global position
	right_hand.global_transform.origin = global_hand_position

	# Ensure the hand is correctly oriented
	var forward_vector = (global_hand_position - parent_transform.origin).normalized()

	# Determine if the hand is in front or behind the player
	var to_hand_vector = global_hand_position - parent_transform.origin
	var is_behind = to_hand_vector.dot(parent_transform.basis.z) < 0

	# Adjust the up vector dynamically based on the hand's position
	var up_vector = Vector3.UP if !is_behind else -Vector3.UP

	var right_vector = up_vector.cross(forward_vector).normalized()
	up_vector = forward_vector.cross(right_vector).normalized()

	# Apply the new basis
	var new_basis = Basis(right_vector, up_vector, forward_vector)
	right_hand.global_transform.basis = new_basis

	# Apply a local rotation for the hammer orientation
	right_hand.rotate_object_local(Vector3(0, 0, 1), deg_to_rad(90))


func apply_spring_force(target_node: Node3D, rigid_body: RigidBody3D):
	var target_position = target_node.global_transform.origin
	var current_position = rigid_body.global_transform.origin
	var displacement = target_position - current_position
	var spring_force = stiffness * displacement
	var damping_force = -damping * rigid_body.linear_velocity
	var total_force = spring_force + damping_force
	rigid_body.apply_central_force(total_force)
