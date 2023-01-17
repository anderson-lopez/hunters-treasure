extends KinematicBody2D

const SPEED = 128
const FLOOR = Vector2(0, -1)
const GRAVITY = 16
const JUMP_HEIGHT = 384
const BOUNCING_JUMP: = 112
const CAST_WALL = 10
const CAST_ENEMY = 22 
onready var motion : Vector2 = Vector2.ZERO
var can_move : bool

"""" STATE MACHINE """
var playback : AnimationNodeStateMachinePlayback


func _ready():
	playback = $AnimationTree.get("parameters/playback")
	playback.start("Idle")
	$AnimationTree.active = true

func _process(_delta):
	motion_ctrl()
	direction_ctrl()
	jump_ctrl()
	attack_ctrl()


func get_axis() -> Vector2:
	var axis = Vector2.ZERO
	axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	return axis

#Control de movimiento
func motion_ctrl():
	motion.y += GRAVITY
	
	if can_move:
		motion.x = get_axis().x * SPEED
		
		if get_axis().x == 0:
			playback.travel("Idle")
		else:
			playback.travel("Run")
		
		match playback.get_current_node():
			"Idle":
				motion.x = 0
				$Particles.emitting = false
			"Run":
				$Particles.emitting = true
		
		if get_axis().x == 1:
			$Sprite.flip_h = false
		elif get_axis().x == -1:
			$Sprite.flip_h = true
			
	motion = move_and_slide(motion, FLOOR)

#Control de Direccion
func direction_ctrl():
	match $Sprite.flip_h:
		true: 
			$RayWall.cast_to.x = -CAST_WALL
			$RayEnemy.cast_to.x = -CAST_ENEMY
		false:
			$RayWall.cast_to.x = CAST_WALL
			$RayEnemy.cast_to.x = CAST_ENEMY

# Control de Salto
func jump_ctrl():
	match is_on_floor():
		true:
			can_move = true
			$RayWall.enabled = false
			
			if Input.is_action_just_pressed("Jump"):
				$Sounds/Jump.play()
				motion.y -= JUMP_HEIGHT
			
		false:
			$Particles.emitting = false
			$RayWall.enabled = true
			
			if motion.y < 0:
				playback.travel("Jump")
			else:
				playback.travel("Fall")
			
			if $RayWall.is_colliding():
				can_move = false
				
				var col = $RayWall.get_collider()
				
				if col.is_in_group("Wall") and Input.is_action_just_pressed("Jump"):
					$Sounds/Jump.play()
					motion.y -= JUMP_HEIGHT
					
					if $Sprite.flip_h: 
						motion.x += BOUNCING_JUMP
						$Sprite.flip_h = false
					else:
						motion.x -= BOUNCING_JUMP
						$Sprite.flip_h = true

# Control de Ataques
func attack_ctrl():
	if is_on_floor():
		if get_axis().x == 0 and Input.is_action_just_pressed("Attack"):
			match playback.get_current_node():
				"Idle":
					playback.travel("Attack-1")
					$Sounds/Sword.play()
				"Attack-1":
					playback.travel("Attack-2")
					$Sounds/Sword.play()
				"Attack-2":
					playback.travel("Attack-3")
					$Sounds/Sword.play()
	else:
		if get_axis().y != 0 and Input.is_action_just_pressed("Attack"):
			match playback.get_current_node():
				"Jump":
					playback.travel("Air-Attack-1")
					$Sounds/Sword.play()
				"Air-Attack-1":
					playback.travel("Air-Attack-2")
					$Sounds/Sword.play()
			
			match playback.get_current_node():
				"Fall":
					playback.travel("Air-Attack-1")
					$Sounds/Sword.play()
				"Air-Attack-1":
					playback.travel("Air-Attack-2")
					$Sounds/Sword.play()
	
	if playback.get_current_node() == "Attack-1" or playback.get_current_node() == "Attack-2" or playback.get_current_node() == "Attack-3":
		$RayEnemy.enabled = true
	else:
		$RayEnemy.enabled = false
	
	var col = $RayEnemy.get_collider()
	
	if $RayEnemy.is_colliding() and col.is_in_group("Enemy"):
		col.queue_free()
