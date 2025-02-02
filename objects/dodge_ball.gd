extends RigidBody3D

@export var impact_effect: PackedScene  # Drag your `ImpactEffect.tscn` here

# Signal to notify a hit
signal hit_player(player, dodgeball)
@onready var ball_owner = null


func _ready():
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
			var position = state.get_contact_collider_position(0)
			position.y += 1
			spawn_effect(self.global_position)
		
func spawn_effect(position: Vector3):
	if impact_effect:
		var effect_instance = impact_effect.instantiate() as Node3D
		effect_instance.global_transform.origin = position
		get_parent().add_child(effect_instance)
