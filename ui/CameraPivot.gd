extends Node3D

var player_id: int

@export var target_node: Node3D  # The player this camera follows
@export var mouse_sensitivity = 0.1  # Mouse look speed
var controller_sensitivity # Controller look speed

@export var physical_skel: Skeleton3D  # Prevents clipping

@onready var topNode : Node3D
@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D

var mouse_lock = false  # Track if mouse is locked
var input_map = {
	1: {
		"look_up"    : "player_1_look_up",
		"look_down"  : "player_1_look_down",
		"look_left"  : "player_1_look_left",
		"look_right" : "player_1_look_right",
		},
	2: {
		"look_up"    : "player_2_look_up",
		"look_down"  : "player_2_look_down",
		"look_left"  : "player_2_look_left",
		"look_right" : "player_2_look_right",
		}
}
func _ready():
	mouse_lock = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _physics_process(_delta):
	# Prevent camera from clipping into character
	for child in physical_skel.get_children():
		if child is PhysicalBone3D:
			spring_arm.add_excluded_object(child.get_rid())

	# Follow the target character smoothly
	if target_node != null:
		global_position = lerp(global_position, target_node.global_position, 0.5)

func _input(event):
	# Ensure input is only processed for the correct player
	#if not get_viewport().has_focus():
		#return

	# Mouse Lock Toggle
	if Input.is_action_just_pressed("camera_capture_toggle"):
		mouse_lock = !mouse_lock
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_lock else Input.MOUSE_MODE_VISIBLE

	# Rotate camera with mouse
	if event is InputEventMouseMotion and mouse_lock:
		rotation_degrees.y -= mouse_sensitivity * event.relative.x
		rotation_degrees.x -= mouse_sensitivity * event.relative.y
		rotation_degrees.x = clamp(rotation_degrees.x, -45, 45)

func _process(delta):
	# Controller support
	var look_x = Input.get_action_strength(input_map[player_id]["look_right"]) - Input.get_action_strength(input_map[player_id]["look_left"])
	var look_y = Input.get_action_strength(input_map[player_id]["look_down"]) - Input.get_action_strength(input_map[player_id]["look_up"])

	if look_x != 0 or look_y != 0:
		rotation_degrees.x -= look_y * controller_sensitivity * delta
		rotation_degrees.x = clamp(rotation_degrees.x, -45, 45)
		topNode.rotation_degrees.y -= look_x * controller_sensitivity * delta
		clamp(topNode.rotation_degrees.y, -20, 20)
		# Rotate the top node based on horizontal mouse movement
