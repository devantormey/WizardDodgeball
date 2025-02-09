extends Control

@export var first_button: Button

@onready var Play = $MarginContainer/VBoxContainer/Play
@onready var SplitScreen =$MarginContainer/VBoxContainer/SplitScreen
@onready var Options =$MarginContainer/VBoxContainer/Options
@onready var Quit =$MarginContainer/VBoxContainer/Quit

#var input_map = {
	#1: {
		#"dpad_up": "player_1_dpad_up",
		#"dpad_down": "player_1_dpad_down",
		#"dpad_left": "player_1_dpad_left",
		#"dpad_right": "player_1_dpad_right",
		#"select": "player_1_a"
	#},
	#2: {
		#"dpad_up": "player_2_dpad_up",
		#"dpad_down": "player_2_dpad_down",
		#"dpad_left": "player_2_dpad_left",
		#"dpad_right": "player_2_dpad_right",
		#"select": "player_2_a"
	#}
#}

func _ready():
	# Set the first button as focused on start
	if Play:
		Play.grab_focus()

#func _unhandled_input(event):
	#var focused = get_viewport().gui_get_focus_owner()
	#if focused == null or not focused is Button:
		#return
	#
	## Check for D-pad navigation
	#for player in input_map.keys():
		#if Input.is_action_just_pressed(input_map[player]["dpad_up"]):
			#_focus_next_button(focused, "up")
		#elif Input.is_action_just_pressed(input_map[player]["dpad_down"]):
			#_focus_next_button(focused, "down")
		#elif Input.is_action_just_pressed(input_map[player]["dpad_left"]):
			#_focus_next_button(focused, "left")
		#elif Input.is_action_just_pressed(input_map[player]["dpad_right"]):
			#_focus_next_button(focused, "right")
		#elif Input.is_action_just_pressed(input_map[player]["select"]):
			#focused.emit_signal("pressed")  # Simulate button press

#func _focus_next_button(current: Button, direction: String):
	#var next_button = null
	#
	#match direction:
		#"up":
			#next_button = current.focus_neighbor_top
		#"down":
			#next_button = current.focus_neighbor_bottom
		#"left":
			#next_button = current.focus_neighbor_left
		#"right":
			#next_button = current.focus_neighbor_right
#
	#if next_button and next_button is Button:
		#next_button.grab_focus()

func _on_split_screen_pressed():
	get_tree().change_scene_to_file("res://map/SplitScreenTestWorld.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_play_button_up():
	get_tree().change_scene_to_file("res://map/SingleScreenTestWorld.tscn")

func _on_options_pressed():
	pass  # Implement options menu logic
