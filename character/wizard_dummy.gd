extends RigidBody3D

# Movement speed parameters
@export var move_speed: float = 8.0
@export var dodge_speed: float = 25.0
@export var movethreshold: float = 0.1
@export var hat: MeshInstance3D

@onready var dodgeball_marker: Marker3D = $Marker3D
@onready var rearCam: Camera3D = $CameraControl/MainCamera
@onready var skeleton_control = $Armature/Skeleton3D
@onready var head_joint: Generic6DOFJoint3D = $HeadJoint

@onready var active_skeleton = $Armature/Skeleton3D/PhysicalBoneSimulator3D
@onready var static_skeleton = $Armature/Skeleton3D/static_PhysicalBoneSimulator3D2
@onready var spine_bone = $"Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone spine"
@onready var collision_detector = $CollisionDetector
@onready var head_static_body = $StaticBody3D
# Variables to track movement
var velocity: Vector3 = Vector3.ZERO
var is_dodging: bool = false
var dodge_timer: float = 0.0
@export var dodge_duration: float = 0.3  # Duration of the dodge in seconds

@onready var is_throwing: bool = false

# Variable to track picked dodgeball
@onready var picked_dodgeball: RigidBody3D = null
@onready var isPacking: bool = false
@onready var head_bone =  $"Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone head"
@onready var is_moving: bool = false

const RAY_LENGTH = 1000
const THROW_FORCE = 70.0
const SLIDE_BACK_SPEED = 5.0  # Speed of the ball sliding back

var pull_back_progress: float = 0.0  # Tracks the progress of the pull-back

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to dodgeball hit signals
	for dodgeball in get_tree().get_nodes_in_group("Dodgeballs"):
		if dodgeball.has_signal("hit_player"):
			#print("dodgeball has the signal")
			dodgeball.connect("hit_player", Callable(self, "_on_dodgeball_hit"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#handle_input(delta)
	#move_character(delta)
	#check_for_dodgeball_pickup()
#
	#if picked_dodgeball != null:
		#picked_dodgeball.global_transform = dodgeball_marker.global_transform
	#else:
		#isPacking = false
#
	#handle_dodgeball_throw(delta)
	#if hat != null:
		#handle_hat_tilt()

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
		var end = origin + rearCam.project_ray_normal(mousepos) * 20
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
		var mousepos = get_viewport().get_mouse_position()
		var ray_origin = rearCam.project_ray_origin(mousepos)
		var ray_normal = rearCam.project_ray_normal(mousepos)

		# Define a plane in front of the player to calculate the aiming direction
		var plane_position = global_transform.origin + global_transform.basis.z * 5.0
		var plane_normal = global_transform.basis.z.normalized()
		var aim_plane = Plane(plane_normal, plane_position.dot(plane_normal))
		var intersection_point = aim_plane.intersects_ray(ray_origin, ray_normal)

		if intersection_point:
			var aim_direction = (intersection_point - dodgeball_marker.global_transform.origin).normalized()
			var offset_transform = dodgeball_marker.global_transform
			offset_transform.origin -= aim_direction * (0.5 * pull_back_progress)
			picked_dodgeball.global_transform = offset_transform

	elif isPacking and Input.is_action_just_released("primary_action"):
		# Determine the throw direction based on mouse position projected onto a plane in front of the player
		var mousepos = get_viewport().get_mouse_position()
		var ray_origin = rearCam.project_ray_origin(mousepos)
		var ray_normal = rearCam.project_ray_normal(mousepos)

		# Define a plane in front of the player
		var plane_position = global_transform.origin + global_transform.basis.z * 5.0
		var plane_normal = global_transform.basis.z.normalized()
		var aim_plane = Plane(plane_normal, plane_position.dot(plane_normal))

		# Find the intersection of the ray with the plane
		var intersection_point = aim_plane.intersects_ray(ray_origin, ray_normal)
		if intersection_point:
			var throw_direction = (intersection_point - dodgeball_marker.global_transform.origin).normalized()

			# Apply forward force to the dodgeball
			picked_dodgeball.apply_central_impulse(throw_direction * THROW_FORCE)
			picked_dodgeball = null
			isPacking = false
			pull_back_progress = 0.0
			print("Dodgeball thrown!")
			is_throwing = false

# Handle what happens when hit by a dodgeball
func handle_dodgeball_hit(dodgeball):
	#print("Player hit by dodgeball!")

	# Disable the Generic6DOFJoint3D to detach the ragdoll from the static body
	head_joint.node_b = ""
	head_joint.node_a = ""
	axis_lock_linear_y = false
	# Disable the Skeleton3D control
	skeleton_control.is_disabled = true
	collision_detector.disabled = true
	head_static_body.set_process_mode(PROCESS_MODE_DISABLED)
	
	#static_skeleton.physical_bones_start_simulation()
	static_skeleton.active = false
	#static_skeleton.set_disable_mode(DISABLE_MODE_REMOVE)
	static_skeleton.set_process_mode(PROCESS_MODE_DISABLED)
	active_skeleton.physical_bones_start_simulation()
	# Calculate the direction of the hit
	var hit_direction = (global_transform.origin - dodgeball.global_transform.origin).normalized()
	# Add an upward component to the hit direction
	hit_direction.y += 0.5  # Adjust this value for more or less upward force
	hit_direction = hit_direction.normalized()
	# Apply a force to the ragdoll in the direction of the hit
	var force = hit_direction * dodgeball.linear_velocity.length() * 10.0  # Adjust multiplier as needed
	for i in range(active_skeleton.get_child_count()):
		var active_bone = active_skeleton.get_child(i)
		active_bone.apply_central_impulse(force)
		#head_bone.apply_central_impulse(force)
	
# Handle dodgeball hit signal
func _on_dodgeball_hit(player,dodgeball):
	#print("function was called correctly")
	if player == self:
		#print("player was self")
		handle_dodgeball_hit(dodgeball)

# Drop or place dodgeball (if needed)
func drop_dodgeball():
	if picked_dodgeball != null:
		picked_dodgeball.set_as_toplevel(false)
		picked_dodgeball = null
		print("Dropped dodgeball!")

func handle_hat_tilt():
	pass
