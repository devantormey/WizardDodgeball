extends Control


@onready var Resume = $PanelContainer/VBoxContainer/Resume
@onready var Restart = $PanelContainer/VBoxContainer/Restart
@onready var Options = $PanelContainer/VBoxContainer/Options
@onready var Quit = $PanelContainer/VBoxContainer/Exit


func _ready():
	# Set the first button as focused on start
	$AnimationPlayer.play("RESET")
	get_tree().paused = false
	

func _process(delta):
	if Input.is_action_just_pressed("pause") and !get_tree().paused:
		if Resume:
			Resume.grab_focus()
		pause()
	elif Input.is_action_just_pressed("pause") and get_tree().paused:
		resume()

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	
	
	
func pause():	
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	
	
func _on_resume_pressed():
	resume() # Replace with function body.


func _on_restart_pressed():
	get_tree().reload_current_scene()
	#resume()


func _on_options_pressed():
	pass # Replace with function body.


func _on_exit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/Main_menu.tscn") # Replace with function body.
