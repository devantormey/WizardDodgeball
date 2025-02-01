extends Node3D

# References to cameras
@onready var main_cam = $MainCamera
@onready var side_cam = $SideCamera
@onready var front_cam = $FrontCamera
@onready var top_node = $".."

# Camera rotation speed
@export var rotation_speed: float = 20.0  # Degrees per second
@export var vertical_rotation_speed: float = 10.0  # Degrees per second
@export var vertical_rotation_limit: float = 45.0  # Maximum vertical rotation in degrees

# State for mouse mode toggle
var is_mouse_captured: bool = true

# Track vertical rotation to clamp within limits
var vertical_rotation: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize the first active camera
	set_active_camera(main_cam)
	# Set initial mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if top_node.is_throwing:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	else:
		if is_mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			handle_camera_swivel(delta)

	handle_mouse_capture_toggle()

	# Handle camera switching
	if Input.is_action_just_pressed("num1"):
		set_active_camera(main_cam)
	elif Input.is_action_just_pressed("num2"):
		set_active_camera(side_cam)
	elif Input.is_action_just_pressed("num3"):
		set_active_camera(front_cam)

# Function to switch the active camera
func set_active_camera(camera_to_activate):
	for child in get_children():
		if child is Camera3D:
			child.current = false

	camera_to_activate.current = true

# Rotate the player and camera based on mouse movement while captured
func handle_camera_swivel(delta):
	var mouse_delta = Input.get_last_mouse_velocity()

	# Rotate the top node based on horizontal mouse movement
	top_node.rotate_y(deg_to_rad(-mouse_delta.x * rotation_speed * delta * 0.01))

	# Adjust vertical rotation with clamping
	vertical_rotation -= mouse_delta.y * vertical_rotation_speed * delta * 0.01
	vertical_rotation = clamp(vertical_rotation, -vertical_rotation_limit, vertical_rotation_limit)

	# Apply the vertical rotation to the main camera
	main_cam.rotation_degrees.x = vertical_rotation

# Toggle mouse capture mode
func handle_mouse_capture_toggle():
	if Input.is_action_just_pressed("camera_capture_toggle"):
		is_mouse_captured = not is_mouse_captured

		if is_mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			print("Mouse captured.")
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			print("Mouse released.")
