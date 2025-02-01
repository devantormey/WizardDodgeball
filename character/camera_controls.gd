extends Node3D

@onready var rear_cam = $RearCam
@onready var side_cam = $SideCam


func _ready():
	# Set default active camera
	activate_camera(rear_cam)

func _process(delta):
	# Check for input to switch cameras
	if Input.is_action_just_pressed("select_1"):
		activate_camera(rear_cam)
		print("selecting Rear camera")
	elif Input.is_action_just_pressed("select_2"):
		activate_camera(side_cam)
		print("selecting Side camera")

func activate_camera(camera: Camera3D):
	# Ensure only the selected camera is active
	rear_cam.current = false
	side_cam.current = false
	camera.current = true
