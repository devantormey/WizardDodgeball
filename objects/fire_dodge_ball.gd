extends Node3D
@onready var dodgeball = $DodgeBall
@onready var firemesh = $DodgeBall/FireballMesh
@onready var ember_emitter = $DodgeBall/EmberEmitter
@onready var is_being_thrown = false
@onready var THROW_FORCE = 60.0
var start_position
var out_of_bounds = false
# Called when the node enters the scene tree for the first time.
func _ready():
	start_position = global_position
	firemesh.visible = false
	ember_emitter.visible = true
	ember_emitter.emitting = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	out_of_bounds = dodgeball.out_of_bounds
	if dodgeball.linear_velocity.length() > 60:
		ember_emitter.emitting = false
		firemesh.visible = true
	else:
		firemesh.visible = false
		ember_emitter.visible = true
		ember_emitter.emitting = true	
	#print("out of bounds: ", out_of_bounds )
func reset_velocity():
	dodgeball.linear_velocity = Vector3.ZERO

func start_respawn_timer():
	if !out_of_bounds:
		dodgeball.start_respawn_timer()

#func _on_respawn_timer_timeout():
	#reset_velocity()
	#dodgeball.angular_velocity = Vector3.ZERO
	#global_position = start_position
	#out_of_bounds = false
	#firemesh.visible = false
	#ember_emitter.visible = true
	#ember_emitter.emitting = true
