extends Control

@onready var Play = $MarginContainer/VBoxContainer/Play
@onready var SplitScreen =$MarginContainer/VBoxContainer/SplitScreen
@onready var Options =$MarginContainer/VBoxContainer/Options
@onready var Quit =$MarginContainer/VBoxContainer/Quit


func _ready():
	# Set the first button as focused on start
	if Play:
		Play.grab_focus()


func _on_split_screen_pressed():
	get_tree().change_scene_to_file("res://map/SplitScreenTestWorld.tscn")

func _on_quit_pressed():
	print("quit pressed")
	get_tree().quit()

func _on_play_button_up():
	get_tree().change_scene_to_file("res://map/SingleScreenTestWorld.tscn")

func _on_options_pressed():
	pass  # Implement options menu logic
