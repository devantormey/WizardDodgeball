extends Control

@onready var crosshair = $CursorTextureRect  # Crosshair TextureRect
@onready var top_node = $".."  # Reference to player node
@export var default_crosshair_size: Vector2 = Vector2(32, 32)  # Default size in pixels
@export var crosshair_scale: float = 1.0  # Scale factor for the crosshair
@export var player_id: int  # Player ID (1 or 2)
@export var splitscreen: bool = false  # If true, use SubViewports
@onready var crosshair_x_offset = 12
@onready var crosshair_y_offset = 12

# Reference to the player's viewport
var player_viewport: SubViewport

func _ready():
	if splitscreen:
		player_viewport = get_parent().get_viewport()
		print("viewport: ", player_viewport)
	update_crosshair_position()

func update_crosshair_position():
	var viewport_size: Vector2

	if splitscreen:
		player_viewport = get_parent().get_viewport()
		# Use SubViewport size for splitscreen
		viewport_size = player_viewport.size
	else:
		# Use full screen for single-player mode
		viewport_size = get_viewport().get_size()

	# Calculate the center of the viewport
	var viewport_center = viewport_size / 2
	viewport_center.x -= crosshair_x_offset
	viewport_center.y -= crosshair_y_offset

	# Set crosshair position
	crosshair.position = viewport_center

# Called every frame (adjust crosshair based on controller aim)
func _process(_delta):
	update_crosshair_position()
