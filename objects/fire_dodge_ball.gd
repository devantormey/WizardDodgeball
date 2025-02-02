extends Node3D
@onready var dodgeball = $DodgeBall
@onready var firemesh = $DodgeBall/FireballMesh
@onready var ember_emitter = $DodgeBall/EmberEmitter
@onready var is_being_thrown = false
# Called when the node enters the scene tree for the first time.
func _ready():
	firemesh.visible = false
	ember_emitter.visible = true
	ember_emitter.emitting = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
