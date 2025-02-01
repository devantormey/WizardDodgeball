extends Node3D

# Automatically called when added to the scene
func _ready():
	$DespawnTimer.start()  # Start the timer when the effect spawns
	$impactParticles.emitting = true # Ensure particles emit on spawn (if needed)

func _on_despawn_timer_timeout():
	queue_free()  # Safely remove the effect node from the scene tree
