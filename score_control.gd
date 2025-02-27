extends Control

@onready var team1_score = 0
@onready var team2_score = 0
@onready var team1_score_label = $CanvasLayer/PanelContainer/HBoxContainer/Team1Score
@onready var team2_score_label = $CanvasLayer/PanelContainer/HBoxContainer2/Team2Score
@onready var win_menu = $CanvasLayer/WinMenu
@onready var winnerLabel = $CanvasLayer/WinMenu/PanelContainer2/VBoxContainer/WinnerLabel
@onready var win_menu_animation = $CanvasLayer/WinMenu/AnimationPlayer
@onready var restart = $CanvasLayer/WinMenu/PanelContainer2/VBoxContainer/Restart
@onready var exit = $CanvasLayer/WinMenu/PanelContainer2/VBoxContainer/Exit
@onready var win_timer = $WinTimer
@export var score_to_win : int = 3
@onready var winner = false

func _ready():
	win_menu_animation.play("RESET")
	get_tree().paused = false
	
	
	# Automatically connect all players to listen for hits
	for player in get_tree().get_nodes_in_group("Players"):
		player.player_hit.connect(_on_player_hit)

	update_score_display()  # Ensure labels show initial score

func pause():	
	get_tree().paused = true
	win_menu_animation.play("blur")
	if restart:
		restart.grab_focus()

func _process(delta):
	if team1_score >= score_to_win and !get_tree().paused and !winner:
		winnerLabel.text = "Team 1 Wins!"
		win_timer.start()
		winner=true
		print("starting win timer")
	if team2_score >= score_to_win and !get_tree().paused and !winner:
		winnerLabel.text = "Team 2 Wins!"
		winner=true
		win_timer.start()

func _on_player_hit(player_id, attacker_id):
	if player_id == 1:
		team2_score += 1  # Team 2 scores when Player 1 is hit
	elif player_id == 2:
		team1_score += 1  # Team 1 scores when Player 2 is hit

	update_score_display()  # Update labels with new score

func update_score_display():
	team1_score_label.text = str(team1_score)
	team2_score_label.text = str(team2_score)

func _on_restart_pressed():
	get_tree().reload_current_scene()


func _on_exit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/Main_menu.tscn") # Replace with function body.


func _on_win_timer_timeout():
	print("win timer timed out")
	$WinSound.play()
	pause()
