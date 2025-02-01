#extends Control
#
#@onready var crosshair = $TextureRect  # Path to your TextureRect with the crosshair image
#
## Called every frame
#func _process(delta):
	## Update the position of the crosshair to match the mouse
	#crosshair.position = get_viewport().get_mouse_position()
#
	## Optionally, hide the system cursor
	##Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
