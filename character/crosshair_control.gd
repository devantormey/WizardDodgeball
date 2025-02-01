extends Control

@onready var crosshair =  $CursorTextureRect # Path to the TextureRect holding the crosshair image
@onready var top_node = $".."
@export var default_crosshair_size: Vector2 = Vector2(32, 32)  # Default size in pixels
@export var crosshair_scale: float = 1.0  # Scale factor for the crosshair
@onready var crosshair_x_offest = 12
@onready var crosshair_y_offest = 12

# Called when the node enters the scene tree for the first time
func _ready():
	pass
	# Set the initial size of the crosshair
	#crosshair.rect_min_size = default_crosshair_size * crosshair_scale

	# Ensure the system cursor is hidden
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# Called every frame
func _process(delta):
	# Update the position of the crosshair to match the mouse
	if top_node.is_throwing:
		var mouse_pos = get_viewport().get_mouse_position()
		mouse_pos.x -= crosshair_x_offest
		mouse_pos.y -= crosshair_y_offest
		crosshair.position = mouse_pos
	else:
		pass
		var viewport_center = get_viewport().get_size() / 2
		viewport_center.x -= crosshair_x_offest
		viewport_center.y -= crosshair_y_offest
		crosshair.position = viewport_center
# Dynamically update the crosshair size
#func update_crosshair_size(new_scale: float):
	#crosshair_scale = new_scale
	#crosshair.rect_min_size = default_crosshair_size * crosshair_scale
