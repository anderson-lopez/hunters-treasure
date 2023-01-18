extends KinematicBody2D

const SPEED = 128
const FLOOR = Vector2(0, -1)
const GRAVITY = 16
const JUMP_HEIGHT = 384
const BOUNCING_JUMP: = 112
const CAST_WALL = 10
const CAST_ENEMY = 22 
const CAST_DAMAGE = 30
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
	jump_ctrl()
	attack_ctrl()
	damage_ctrl()


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
		elif get_axis().x == 1:
			playback.travel("Run")
			$Sprite.flip_h = false
		elif get_axis().x == -1:
			playback.travel("Run")
			$Sprite.flip_h = true
		
		match playback.get_current_node():
			"Idle":
				motion.x = 0
				$Particles.emitting = false
			"Run":
				$Particles.emitting = true
	
	match $Sprite.flip_h:
		true:
			$RayCast.scale.x = -1
		false:
			$RayCast.scale.x = 1
			
	motion = move_and_slide(motion, FLOOR)

# Control de Salto
func jump_ctrl():
	match is_on_floor():
		true:
			can_move = true
			
			if Input.is_action_just_pressed("Jump"):
				$Sounds/Jump.play()
				motion.y -= JUMP_HEIGHT
			
		false:
			$Particles.emitting = false
			
			if motion.y < 0:
				playback.travel("Jump")
			else:
				playback.travel("Fall")
			
			if $RayCast/RayWall.is_colliding():
				
				var body = $RayCast/RayWall.get_collider()
				
				if body.is_in_group("Wall"):
					can_move = false
					
					if Input.is_action_just_pressed("Jump"):
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
	var body = $RayCast/RayHit.get_collider()
	
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
			
			if $RayCast/RayHit.is_colliding():
				if body.is_in_group("Enemy"):
					body.damage_ctrl()
	else:
		if Input.is_action_just_pressed("Attack"):
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
				
			if $RayCast/RayHit.is_colliding():
				if body.is_in_group("Enemy"):
					body.damage_ctrl()

func damage_ctrl():
	if $RayCast/RayDamage.is_colliding():
		var damage = $RayCast/RayDamage.get_collider()
		
		if damage.is_in_group("Enemy"):
			playback.travel("Damage")
