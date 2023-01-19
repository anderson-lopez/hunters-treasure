extends KinematicBody2D

export(int, 1, 10) var health : int = 3
var playback : AnimationNodeStateMachinePlayback

func _ready():
	$Animation.play("Idle")


func _process(delta):
	if health <= 0:
		queue_free()


func damage_ctrl():
	health -= 1
#	match playback.get_current_node():
#		"Idle":
#			playback.travel("Damage")
	print("La vida del enemigo es igual a: " + str(health))
