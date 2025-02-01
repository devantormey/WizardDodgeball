extends RigidBody3D

@export var move_speed: float = 1000.0  # Linear movement speed
@export var strafe_speed: float = 1500.0  # Strafing speed
@export var jump_strength: float = 1000.0  # Jump impulse strength
@export var max_speed: float = 8.0  # Maximum velocity limit
@export var drag: float = 5.0  # Drag factor to slow down when no input
@export var blend_speed: float = 5.0  # Speed of animation blending
@export var jump_delay: float = 0.1  # Delay before applying jump force
@export var rotation_speed: float = 3.0  # Speed of rotation
@export var sprint_speed: float = 10000.0
@export var walk_speed: float = 700.0

var is_moving: bool = false  # Track if the player is moving
var is_jumping: bool = false  # Track if the player is actively jumping
var is_jumping_animation: bool = false  # Track if the jump animation is playing
var jump_timer_started: bool = false  # Prevent multiple timer calls

@onready var jump_timer = $JumpTimer
@onready var animation_tree = $AnimationTree
@onready var animation_player = $AnimationPlayer

enum {IDLE, RUN, WALK, JUMP, STRAFE_LEFT, STRAFE_RIGHT}
var curAnim = IDLE

# Blend values for animations
var walk_val = 0.0
var run_val = 0.0
var jump_val = 0.0
var strafe_left_val = 0.0
var strafe_right_val = 0.0

# Constants for AnimationTree parameter paths
const PARAMS = {
	"walk": "parameters/walk/blend_amount",
	"run": "parameters/run/blend_amount",
	"jump": "parameters/jump/blend_amount",
	"strafe_left": "parameters/strafe_left/blend_amount",
	"strafe_right": "parameters/strafe_right/blend_amount"
}

func _ready():
	print("Character ready!")

func _physics_process(delta):
	handle_animations(delta)
	handle_rotation(delta)  # Add rotation handling

	# Update jumping state
	if is_jumping_animation and !jump_timer_started:
		is_jumping_animation = false  # Reset animation state after the delay

	if is_jumping and is_on_floor():
		is_jumping = false  # Reset jumping state when back on the ground

func _integrate_forces(state: PhysicsDirectBodyState3D):
	handle_movement(state)

func handle_rotation(delta):
	# Rotate character based on left and right keys
	if Input.is_action_pressed("move_right"):  # Bind to "Left" key or equivalent
		rotate_y(-rotation_speed * delta)  # Rotate counterclockwise
	elif Input.is_action_pressed("move_left"):  # Bind to "Right" key or equivalent
		rotate_y(rotation_speed * delta)  # Rotate clockwise

func handle_movement(state: PhysicsDirectBodyState3D):
	var input_vector = Vector3()

	# Forward and backward movement
	if Input.is_action_pressed("move_forward") and !is_jumping:
		if Input.is_action_pressed("sprint"):
			move_speed = sprint_speed
		else:
			move_speed = walk_speed
		input_vector.z -= move_speed
	if Input.is_action_pressed("move_backward") and !is_jumping:
		input_vector.z += move_speed

	## Strafing left and right
	#if Input.is_action_pressed("move_left"):
		#input_vector.x += strafe_speed
		#curAnim = STRAFE_LEFT
	#if Input.is_action_pressed("move_right"):
		#input_vector.x -= strafe_speed
		#curAnim = STRAFE_RIGHT

	# Start jump if on the ground and animation delay not active
	if Input.is_action_just_pressed("jump") and is_on_floor() and not jump_timer_started:
		is_jumping_animation = true
		jump_timer_started = true
		animation_tree.set("parameters/jump/time", 0.0)
		curAnim = JUMP
		jump_timer.start(jump_delay)
		#jump_delay = .01
		print("Jump animation playing, timer started.")

	# Apply movement forces if input exists
	if input_vector != Vector3.ZERO and not is_jumping_animation:
		is_moving = true
		var local_velocity = -global_transform.basis.z * input_vector.z + global_transform.basis.x * input_vector.x
		apply_central_impulse(local_velocity * state.step)

		# Determine walk or run
		if linear_velocity.length() > 7.5 && !is_jumping:
			curAnim = RUN
		elif curAnim != STRAFE_LEFT and curAnim != STRAFE_RIGHT and !is_jumping:
			curAnim = WALK
	else:
		is_moving = false
		if not is_jumping_animation and not is_jumping:
			curAnim = IDLE
	#print("is jumping: ",is_jumping)
	# Apply drag
	if linear_velocity.length() > 0 and !is_jumping:
		apply_central_force(-linear_velocity * drag)

	# Clamp velocity
	if linear_velocity.length() > max_speed and !is_jumping:
		linear_velocity = linear_velocity.normalized() * max_speed

func _on_jump_timer_timeout():
	print("Jump timer timeout, applying impulse!")
	var jump_impulse = Vector3(0, jump_strength, 0)
	print("applying jump impulse: ", jump_impulse )
	apply_central_impulse(jump_impulse)  # Apply the jump force
	is_jumping = true  # Set active jumping state
	jump_timer_started = false  # Reset the timer state

func handle_animations(delta):
	match curAnim:
		IDLE:
			blend_animation(delta, 0.0, 0.0, 0.0, 0.0, 0.0)
		RUN:
			blend_animation(delta, 0.0, 1.0, 0.0, 0.0, 0.0)
		WALK:
			blend_animation(delta, 1.0, 0.0, 0.0, 0.0, 0.0)
		JUMP:
			blend_animation(delta, 0.0, 0.0, 1.0, 0.0, 0.0)
		STRAFE_LEFT:
			blend_animation(delta, 0.0, 0.0, 0.0, 1.0, 0.0)
		STRAFE_RIGHT:
			blend_animation(delta, 0.0, 0.0, 0.0, 0.0, 1.0)

	update_tree()

func blend_animation(delta, walk: float, run: float, jump: float, strafe_left: float, strafe_right: float):
	walk_val = lerpf(walk_val, walk, blend_speed * delta)
	run_val = lerpf(run_val, run, blend_speed * delta)
	jump_val = lerpf(jump_val, jump, blend_speed * delta * 2)
	strafe_left_val = lerpf(strafe_left_val, strafe_left, blend_speed * delta)
	strafe_right_val = lerpf(strafe_right_val, strafe_right, blend_speed * delta)

func update_tree():
	animation_tree[PARAMS["walk"]] = walk_val
	animation_tree[PARAMS["run"]] = run_val
	animation_tree[PARAMS["jump"]] = jump_val
	animation_tree[PARAMS["strafe_left"]] = strafe_left_val
	animation_tree[PARAMS["strafe_right"]] = strafe_right_val

func is_on_floor() -> bool:
	return abs(linear_velocity.y) <= 0.01
