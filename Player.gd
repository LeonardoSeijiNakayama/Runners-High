extends KinematicBody

export(int, 1, 2) var playerId := 1
export var speed := 7.5
export var running_speed = 10.0
export var gravity := 12
export var wr_gravity := 0.5
export var jump_force := 6.0

signal stamina_changed(current, maxv)

export var stamina_max = 100.0
var stamina := 100.0

var prefix = ""
export (float, 0.0, 5.0) var st_timer := 0.0
export (float, 0.0, 0.5) var wr_slip_timer := 0.0
export (float, 0.0, 1.0) var wr_cooldown := 0.0

# Controle de rotação conforme câmera
export(bool) var smooth_camera_yaw := true
export(float, 0.0, 20.0) var turn_speed := 8.0   # usado se smooth_camera_yaw = true

var velocity := Vector3.ZERO
var _snap_vector := Vector3.DOWN
var wr_flag := false

const IDLE = 0
const JOGGING = 1
const RUNNING = 2
const JUMPING = 3
const RUNNING_JUMP = 4
const JOGGING_JUMP = 5
const WALLRUNNING = 6
const FALLING = 7
const SLIPPED = 8
var state = 0
var sliding = false

const SLIP_TIME = 3
var slip_timer = 0
var slipped = false
onready var banana_scene = preload("res://Banana_peel.tscn")

onready var missile_scene = preload("res://Missile.tscn")

const HABILITY_NONE = 0
const MISSILE = 1
const BANANA_PEEL = 2
var current_hability = 0

var rng = RandomNumberGenerator.new()
var global_delta

onready var _spring_arm: SpringArm = $SpringArm
onready var _model: CollisionShape = $CollisionShape   # apenas colisor (não usado para “look”)
onready var _mesh: MeshInstance = $MeshInstance
onready var _animation_player: AnimationPlayer = $Man/AnimationPlayer

func _ready():
	if playerId == 1:
		prefix = "p1_"
		name = "Player1"
	else:
		prefix = "p2_"
		name = "Player2"
	add_to_group("Player")
	add_to_group(prefix)
	emit_signal("stamina_changed", stamina, stamina_max)



func _physics_process(delta: float):
	global_delta = delta
	# ---- INPUT NO ESPAÇO DA CÂMERA (ignora pitch) ----
	var ix := Input.get_action_strength(prefix+"right") - Input.get_action_strength(prefix+"left")
	var iz := Input.get_action_strength(prefix+"up")  - Input.get_action_strength(prefix+"down")

	var cam_basis := _spring_arm.global_transform.basis
	var cam_fwd := -cam_basis.z
	cam_fwd.y = 0
	cam_fwd = cam_fwd.normalized()
	var cam_right := cam_basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	var input_dir := (cam_right * ix + cam_fwd * iz)
	if input_dir.length() > 0.001:
		input_dir = input_dir.normalized()
	# -----------------------------------------------
	
	var is_idle = is_on_floor() and input_dir.length()<=0.0 and state != WALLRUNNING and not slipped
	
	# IDLE só no chão, sem input
	if is_idle:
		state = IDLE
	
	velocity.y -= gravity * delta
	
	# Movimento (sempre no referencial da câmera)
	if not slipped:
		if Input.is_action_pressed(prefix+"run") and stamina > 0:
			if is_on_floor():
				if input_dir.length() != 0:
					state = RUNNING
					set_stamina(stamina - 25.0 * delta)
				else:
					state = IDLE
			velocity.x = input_dir.x * running_speed
			velocity.z = input_dir.z * running_speed
			
			st_timer = 0.0
		else:
			if is_on_floor():
				if input_dir.length() != 0:
					state = JOGGING
				else:
					state = IDLE
			velocity.x = input_dir.x * speed
			velocity.z = input_dir.z * speed
			st_timer += delta
			if (stamina < 100.0 and st_timer >= 5.0):
				set_stamina(stamina + 15.0 * delta)
	
	# Wall run (mantém possibilidade de roll em Z)
	if (wr_cooldown < 1.0):
		wr_cooldown += delta
	if Input.is_action_pressed(prefix+"jump") and !is_on_floor() and is_on_wall() and wr_cooldown >= 1.0 and not slipped and (Input.get_action_strength(prefix+"left") or Input.get_action_strength(prefix+"right")):
		state = WALLRUNNING
		if Input.get_action_strength(prefix+"left"):
			rotation_degrees.z = 10
		if Input.get_action_strength(prefix+"right"):
			rotation_degrees.z = -10
		wr_flag = true
		if (wr_slip_timer < 1):
			wr_slip_timer += delta
			velocity.y = 0.0
		else:
			velocity.y -= wr_gravity * delta
	elif Input.is_action_just_released(prefix+"jump") and wr_flag and is_on_wall():
		rotation_degrees.z = 0
		velocity.y = jump_force
		_snap_vector = Vector3.ZERO
		wr_flag = false
		wr_slip_timer = 0.0
		wr_cooldown = 0.0
	else:
		rotation_degrees.z = 0
	
	stamina = clamp(stamina, 0, 100)
	
	# Pulo / estado no ar
	if Input.is_action_just_pressed(prefix+"jump") and is_on_floor():
		# Se estiver correndo e com direção, é um RUNNING_JUMP
		if is_idle:
			state = JUMPING
		elif Input.is_action_pressed(prefix+"run") and input_dir.length() != 0:
			state = RUNNING_JUMP
		else:
			state = JOGGING_JUMP
		velocity.y = jump_force
		_snap_vector = Vector3.ZERO
	elif not is_on_floor() and state != WALLRUNNING:
		# Enquanto estiver no ar:
		# - se começou como RUNNING_JUMP, mantém
		# - senão, usa JUMPING normal
		if state == JUMPING:
			state = JUMPING
		elif state == RUNNING_JUMP:
			state = RUNNING_JUMP
		elif state == JOGGING_JUMP:
			state = JOGGING_JUMP
	elif is_on_floor() and _snap_vector == Vector3.ZERO:
		_snap_vector = Vector3.DOWN
	
	if velocity.y < 0 and not is_on_floor(): 
		state = FALLING
	velocity = move_and_slide_with_snap(velocity, _snap_vector, Vector3.UP, true)
	
	# ---- YAW DO PLAYER = YAW DA CÂMERA (apenas) ----
	var forward := cam_fwd  # já está no plano XZ e normalizado
	var cam_yaw := atan2(forward.x, forward.z) # radianos
	
	if not slipped:
		if smooth_camera_yaw:
			rotation.y = lerp_angle(rotation.y, cam_yaw, clamp(turn_speed * delta, 0, 1))
		else:
			rotation.y = cam_yaw
	# -----------------------------------------------



func _process(delta) -> void:
	if not slipped:
		match state:
			IDLE:
				_animation_player.play("HumanArmature|Man_Idle")
			JOGGING:
				_animation_player.play("HumanArmature|Man_Run")
			RUNNING:
				_animation_player.play("HumanArmature|Man_Run", -1, 1.5)
			JUMPING:
				_animation_player.play("HumanArmature|Man_Jump")
			JOGGING_JUMP:
				_animation_player.play("HumanArmature|Man_RunningJump")
			RUNNING_JUMP:
				_animation_player.play("HumanArmature|Man_RunningJump",-1,1.5)
			WALLRUNNING:
				_animation_player.play("HumanArmature|Man_Walk")
	else:
		slip_timer-=delta
		if slip_timer <=0:
			slip_timer = 0
			slipped = false
	
	if Input.is_action_just_pressed(prefix+"hability"):
		match current_hability:
			HABILITY_NONE:
				print("none")
			MISSILE:
				throw_missile()
				current_hability = HABILITY_NONE
			BANANA_PEEL:
				drop_banana()
				current_hability = HABILITY_NONE
	_spring_arm.translation = translation



func set_stamina(v:float) ->void:
	stamina = clamp(v, 0.0, stamina_max)
	emit_signal("stamina_changed", stamina, stamina_max)



func get_item():
	rng.randomize()
	current_hability = rng.randi_range(1,2)
	print(current_hability)



func drop_banana()->void:
	var banana = banana_scene.instance()
	get_parent().add_child(banana)
	var behind_dir = -global_transform.basis.z.normalized() 
	var offset = behind_dir * 1.0                           
	banana.global_transform.origin = global_transform.origin + offset



func throw_missile()->void:
	var missile = missile_scene.instance()
	if playerId == 1:
		missile.target = 2
	else:
		missile.target = 1
	get_parent().add_child(missile)
	var front_dir = global_transform.basis.z.normalized() 
	var up_dir = global_transform.basis.y.normalized()
	var offset = front_dir * 1.0 + up_dir * 2                     
	missile.global_transform.origin = global_transform.origin + offset
	



func slip():
	velocity.x = 0
	velocity.z = 0
	velocity.y = 0
	print(velocity.y)
	slipped = true
	slip_timer = SLIP_TIME
	_animation_player.play("HumanArmature|Man_Death")
