extends Node3D

# Movement speed parameters
@export var move_speed: float = 8.0
@export var dodge_speed: float = 25.0
@export var movethreshold: float = 0.1
@export var hat: MeshInstance3D

@onready var dodgeball_marker: Marker3D = $Marker3D
@onready var rearCam: Camera3D = $CameraControl/MainCamera
@onready var skeleton_control = $Armature/Skeleton3D
@onready var head_joint: Generic6DOFJoint3D = $HeadJoint
@onready var static_skeleton = $Armature/Skeleton3D/static_PhysicalBoneSimulator3D2

# Variables to track movement
var velocity: Vector3 = Vector3.ZERO
var is_dodging: bool = false
var dodge_timer: float = 0.0
@export var dodge_duration: float = 0.3  # Duration of the dodge in seconds

@onready var is_throwing: bool = false
@onready var is_disabled = false

# Variable to track picked dodgeball
@onready var picked_dodgeball: RigidBody3D = null
@onready var isPacking: bool = false
@onready var head_bone =  $"Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone head"
@onready var is_moving: bool = false

const RAY_LENGTH = 1000
const THROW_FORCE = 70.0
const SLIDE_BACK_SPEED = 5.0  # Speed of the ball sliding back

var pull_back_progress: float = 0.0  # Tracks the progress of the pull-back
var aim_direction 
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	# Connect to dodgeball hit signals
	#for dodgeball in get_tree().get_nodes_in_group("Dodgeballs"):
		#dodgeball.hit_player.connect(on_dodgeball_hit)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_disabled:
		handle_input(delta)
		move_character(delta)
		check_for_dodgeball_pickup()

		if picked_dodgeball != null:
			picked_dodgeball.global_transform = dodgeball_marker.global_transform
		else:
			isPacking = false

		handle_dodgeball_throw(delta)
		if hat != null:
			handle_hat_tilt()

# Handle input for movement
func handle_input(delta):
	velocity = Vector3.ZERO

	# Check for movement inputs
	if Input.is_action_pressed("move_forward"):
		velocity.z += 1
	if Input.is_action_pressed("move_back"):
		velocity.z -= 1
	if Input.is_action_pressed("move_left"):
		velocity.x += 1
	if Input.is_action_pressed("move_right"):
		velocity.x -= 1

	if Input.is_action_just_pressed("sprint") and not is_dodging:
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

# Check for dodgeball pickup
func check_for_dodgeball_pickup():
	if picked_dodgeball == null and Input.is_action_just_pressed("secondary_action"):
		var viewport_center = get_viewport().get_size() / 2
		Input.warp_mouse(viewport_center)
		var space_state = get_world_3d().direct_space_state
		var mousepos = get_viewport().get_mouse_position()
		var origin = rearCam.project_ray_origin(mousepos)
		var end = origin + rearCam.project_ray_normal(mousepos) * 200
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true

		var result = space_state.intersect_ray(query)
		print(result)
		if result.has("collider") and result["collider"] is RigidBody3D and result["collider"].name.begins_with("DodgeBall"):
			picked_dodgeball = result["collider"] as RigidBody3D
			print("found ball")
			picked_dodgeball.global_transform = dodgeball_marker.global_transform
			isPacking = true
			pull_back_progress = 0.0
			print("Picked up dodgeball!")

# Handle dodgeball throw mechanics
func handle_dodgeball_throw(delta):

	if isPacking and Input.is_action_pressed("primary_action"):
		# Gradually pull the dodgeball back
		if not is_throwing:
			var viewport_center = get_viewport().get_size() / 2
			Input.warp_mouse(viewport_center)
		pull_back_progress = min(pull_back_progress + SLIDE_BACK_SPEED * delta, 1.0)
		is_throwing = true

		# Determine the aiming direction based on the mouse position
		# Determine the throw direction based on mouse position projected onto a plane in front of the player
		var mousepos = get_viewport().get_mouse_position()
		var ray_origin = rearCam.project_ray_origin(mousepos)
		var ray_normal = rearCam.project_ray_normal(mousepos)
	
		# Perform a raycast to find the first object hit
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		
		query.from = ray_origin
		query.to = ray_origin + ray_normal * 1000  # Raycast range, adjust as needed
		query.collide_with_areas = true
		query.collide_with_bodies = true
		
		var intersection_point = space_state.intersect_ray(query)
		#intersection_point.position.y += 10

		if intersection_point:
			aim_direction = (intersection_point.position - picked_dodgeball.global_transform.origin).normalized()
			var offset_transform = picked_dodgeball.global_transform
			offset_transform.origin -= aim_direction * (0.5 * pull_back_progress)
			picked_dodgeball.global_transform = offset_transform
			DebugDraw3D.draw_line(picked_dodgeball.global_transform.origin, picked_dodgeball.global_transform.origin + aim_direction * 1000, Color.RED)
			
	elif isPacking and Input.is_action_just_released("primary_action"):	
		if aim_direction:
			DebugDraw3D.draw_line(picked_dodgeball.global_transform.origin, picked_dodgeball.global_transform.origin + aim_direction * 1000, Color.GREEN)
			#var throw_direction = (intersection_point.position - picked_dodgeball.global_transform.origin).normalized()
			print(aim_direction)
			aim_direction.y += .2
			print(aim_direction)
			# Apply forward force to the dodgeball
			picked_dodgeball.apply_central_impulse(aim_direction * THROW_FORCE)
			picked_dodgeball = null
			isPacking = false
			pull_back_progress = 0.0
			print("Dodgeball thrown!")
			is_throwing = false

# Handle what happens when hit by a dodgeball
func handle_dodgeball_hit():
	print("Player hit by dodgeball!")

	# Disable the Generic6DOFJoint3D to detach the ragdoll from the static body
	head_joint.disable_joint()

	# Disable the Skeleton3D control
	skeleton_control.is_disabled = true
	
# Handle dodgeball hit signal
func on_dodgeball_hit(player):
	if player == self:
		handle_dodgeball_hit()

# Drop or place dodgeball (if needed)
func drop_dodgeball():
	if picked_dodgeball != null:
		picked_dodgeball.set_as_toplevel(false)
		picked_dodgeball = null
		print("Dropped dodgeball!")

func handle_hat_tilt():
	pass
