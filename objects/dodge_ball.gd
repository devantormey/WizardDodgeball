extends RigidBody3D

@export var impact_effect: PackedScene  # Drag your `ImpactEffect.tscn` here

# Signal to notify a hit

@onready var ball_owner = null
@onready var THROW_FORCE = 40.0
var start_position
var out_of_bounds = false

func _ready():
	start_position = global_position
	# Enable contact monitoring to detect collisions
	contact_monitor = true

# Called when a body enters the collision shape
func on_body_entered(body):
	if body and (body.name == "Ground" or body.name == "Wall"):
		#print("hitta dah ground")
		ball_owner = null
		if self.linear_velocity.length() > 1.0:
			#print("speed was good")
			var state = PhysicsServer3D.body_get_direct_state(body)
			var collider_position = state.get_contact_collider_position(0)
			collider_position.y += 1
			spawn_effect(self.global_position)
		
func spawn_effect(spawn_position: Vector3):
	if impact_effect:
		var effect_instance = impact_effect.instantiate() as Node3D
		effect_instance.global_transform.origin = spawn_position
		get_parent().add_child(effect_instance)

func reset_velocity():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func start_respawn_timer():
	if !out_of_bounds:
		$RespawnTimer.start()
		out_of_bounds = true
	
func _on_respawn_timer_timeout():
	reset_velocity()
	global_position = start_position
	out_of_bounds = false
