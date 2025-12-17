extends Node
class_name PlayerMovement

const NORMAL_SPEED = 7.5
const WR_SPEED = 9.5
const RUNNING_SPEED = 12.0
const NORMAL_GRAVITY = 12
const WR_GRAVITY := 2

signal stamina_changed(current, maxv)

var global_delta

export (float, 0.0, 5.0) var st_timer := 0.0
export (float, 0.0, 0.5) var wr_slip_timer := 0.0
export (float, 0.0, 1.0) var wr_cooldown := 0.0
var velocity := Vector3.ZERO
var _snap_vector := Vector3.DOWN
var wr_flag := false

var sliding = false

const GET_UP_TIME = 3.0
var get_up_timer = 0
const SLIP_TIME = 0.35
var slip_timer = 0

var grapple_active := false
var grapple_anchor := Vector3.ZERO
var grapple_len := 0.0

onready var Player = get_parent()
onready var abilities = $"../Abilities"
onready var animation = $"../Animation"
onready var camera = $"../Camera"

func _ready():
	pass


func physics_update(delta:float, input_dir:Vector3, prefix:String, slipped:bool):
	global_delta = delta
	var is_idle = Player.is_on_floor() and input_dir.length()<=0.0 and Player.state != Player.WALLRUNNING and not Player.slipped
	if is_idle:
		Player.state = Player.IDLE
	
	if not Player.is_on_floor():
		if not grapple_active:
			velocity.y -= Player.gravity * delta
	else:
		abilities.release_gp()
	
	# Movimento no referencial da camera
	movement(input_dir, prefix)
	# lógica do wallrun
	wall_run(prefix)
	# lógica de pulo/estado no ar
	jump(is_idle, input_dir, prefix, slipped)
	
	velocity = Player.move_and_slide_with_snap(velocity, _snap_vector, Vector3.UP, true)
	
	if grapple_active:
		_apply_grapple_constraint()
	
	camera.apply_speed_fov(velocity, delta)
	
	Player.stamina = clamp(Player.stamina, 0, 100)

func set_stamina(v:float) ->void:
	Player.stamina = clamp(v, 0.0, Player.stamina_max)
	emit_signal("stamina_changed", Player.stamina, Player.stamina_max)



func slip():
	if not abilities.Shield_Flag:
		_snap_vector = Vector3.ZERO
		velocity.y = 2
		velocity.z = velocity.z * 1.75
		velocity.x = velocity.x * 1.75
		Player.slipped = true
		get_up_timer = GET_UP_TIME
		slip_timer = SLIP_TIME
		animation.playDeathAnimation()
	else:
		abilities.Shield_Flag = false
		abilities.Shield_Timer = 0.0
		abilities.current_hability = abilities.HABILITY_NONE
		abilities.shield.queue_free()



func wall_run(prefix:String)->void:
	if (wr_cooldown < 1.0):
		wr_cooldown += global_delta

	if Input.is_action_pressed(prefix+"jump") \
	and !Player.is_on_floor() \
	and Player.is_on_wall() \
	and _is_wall_runnable() \
	and wr_cooldown >= 1.0 \
	and not Player.slipped \
	and (Input.get_action_strength(prefix+"left") > 0.0 or Input.get_action_strength(prefix+"right") > 0.0):

		Player.state = Player.WALLRUNNING
		Player.speed = Player.WR_SPEED

		if Input.get_action_strength(prefix+"left") > 0.0:
			Player.rotation_degrees.z = 10
		if Input.get_action_strength(prefix+"right") > 0.0:
			Player.rotation_degrees.z = -10

		wr_flag = true
		if (wr_slip_timer < 1):
			wr_slip_timer += global_delta
			velocity.y = 0.0
		else:
			Player.gravity = WR_GRAVITY

	elif Input.is_action_just_released(prefix+"jump") and wr_flag and Player.is_on_wall():
		Player.rotation_degrees.z = 0
		velocity.y = Player.jump_force
		Player.gravity = NORMAL_GRAVITY
		Player.speed = NORMAL_SPEED
		_snap_vector = Vector3.ZERO
		wr_flag = false
		wr_slip_timer = 0.0
		wr_cooldown = 0.0
	else:
		Player.gravity = NORMAL_GRAVITY
		Player.speed = NORMAL_SPEED
		Player.rotation_degrees.z = 0



func _get_wall_collision() -> KinematicCollision:
	for i in range(Player.get_slide_count()):
		var c = Player.get_slide_collision(i)
		if c == null:
			continue
		
		if abs(c.normal.dot(Vector3.UP)) < 0.6:
			return c
	
	return null


func _is_wall_runnable() -> bool:
	var c := _get_wall_collision()
	return c != null and c.collider != null and c.collider.is_in_group("WallRunnable")


func jump(is_idle:bool, input_dir:Vector3, prefix:String, slipped:bool)->void:
	if Input.is_action_just_pressed(prefix+"jump") and Player.is_on_floor():
		if is_idle:
			Player.state = Player.JUMPING
		elif Input.is_action_pressed(prefix+"run") and input_dir.length() != 0:
			Player.state = Player.RUNNING_JUMP
		else:
			Player.state = Player.JOGGING_JUMP
		velocity.y = Player.jump_force
		_snap_vector = Vector3.ZERO
	elif not Player.is_on_floor() and Player.state != Player.WALLRUNNING:
		if Player.state == Player.JUMPING:
			Player.state = Player.JUMPING
		elif Player.state == Player.RUNNING_JUMP:
			Player.state = Player.RUNNING_JUMP
		elif Player.state == Player.JOGGING_JUMP:
			Player.state = Player.JOGGING_JUMP
	elif Player.is_on_floor() and _snap_vector == Vector3.ZERO:
		if not slipped:
			_snap_vector = Vector3.DOWN
	if velocity.y < 0 and not Player.is_on_floor(): 
		Player.state = Player.FALLING



func movement(input_dir:Vector3, prefix:String)->void:
	if grapple_active:
		_grapple_air_control(input_dir)
		return
	
	if not Player.slipped:
		if Input.is_action_pressed(prefix+"run") and Player.stamina > 0:
			if Player.is_on_floor():
				if input_dir.length() != 0:
					Player.state = Player.RUNNING
				else:
					Player.state = Player.IDLE
			if not abilities.RH_Flag:
				set_stamina(Player.stamina - 25.0 * global_delta)
				print("diminuindo")
			Player.speed = RUNNING_SPEED
			st_timer = 0.0
		else:
			if Player.is_on_floor():
				if input_dir.length() != 0:
					Player.state = Player.JOGGING
				else:
					Player.state = Player.IDLE
			Player.speed = NORMAL_SPEED
			st_timer += global_delta
			if (Player.stamina < 100.0 and st_timer >= 2.5):
				set_stamina(Player.stamina + 15.0 * global_delta)
				print("aumentando")
		velocity.x = input_dir.x * Player.speed
		velocity.z = input_dir.z * Player.speed
	else:
		if velocity.z > 0.0:
			velocity.z -= global_delta
		elif velocity.z<0.0:
			velocity.z += global_delta
		
		if velocity.x >0.0:
			velocity.x -= global_delta
		elif velocity.x<0.0:
			velocity.x += global_delta
		
		get_up_timer-=global_delta 
		slip_timer-=global_delta
		
		if slip_timer <=0:
			slip_timer = 0
			if Player.is_on_floor():
				velocity.z = 0
				velocity.x = 0
		
		if get_up_timer <=0: 
			get_up_timer = 0 
			Player.slipped = false


func set_grapple(active: bool, anchor := Vector3.ZERO, length := 0.0) -> void:
	grapple_active = active
	grapple_anchor = anchor
	grapple_len = length


export var GRAPPLE_MAX_ANGLE_DEG := 85.0 # 90 = hemisfério (não passa acima); 85/80 = não chega perto do topo



func _apply_grapple_constraint() -> void:
	var pos = Player.global_transform.origin
	var to_pos = pos - grapple_anchor
	var dist = to_pos.length()
	if dist < 0.001:
		return

	var dir = to_pos / dist  # anchor -> player

	# --- ângulo em relação ao "para baixo" ---
	var dot_down = clamp(dir.dot(Vector3.DOWN), -1.0, 1.0)
	var angle_deg = rad2deg(acos(dot_down))

	# se passou do ângulo E está subindo, solta
	if angle_deg > GRAPPLE_MAX_ANGLE_DEG and velocity.y >= 0.0:
		if is_instance_valid(abilities) and abilities.has_method("release_gp"):
			abilities.release_gp()
		else:
			set_grapple(false)
		return

	# remove componente radial da velocidade para a corda não esticar
	var radial_speed = velocity.dot(dir)
	velocity -= dir * radial_speed

	# projeta posição para ficar exatamente no raio da corda
	var target = grapple_anchor + dir * grapple_len
	Player.global_transform.origin = target



export var GRAPPLE_AIR_ACCEL := 10.0        
export var GRAPPLE_DAMPING := 4.0           
export var GRAPPLE_MAX_TAN_SPEED := 18.0    
export var GRAPPLE_MIN_TAN_SPEED_FOR_UPHILL := 2.0  
export var GRAPPLE_UPHILL_INPUT_SCALE := 0.15
export var GRAPPLE_GRAVITY_MULT := 1.8



func _grapple_air_control(input_dir: Vector3) -> void:
	var pos = Player.global_transform.origin
	var to_pos = pos - grapple_anchor
	var dist = to_pos.length()
	if dist < 0.001:
		return

	var dir = to_pos / dist  # anchor -> player

	# --- gravidade APENAS na tangente da corda ---
	var g = Vector3.DOWN * Player.gravity * GRAPPLE_GRAVITY_MULT
	var g_tan = g - dir * g.dot(dir) # projeta gravidade no plano tangente
	velocity += g_tan * global_delta

	# --- input na tangente ---
	var tang = input_dir - dir * input_dir.dot(dir)

	# separa velocidades
	var v_rad = dir * velocity.dot(dir)
	var v_tan = velocity - v_rad

	# direção "descida" (mesma direção de g_tan)
	var downhill_dir := Vector3.ZERO
	if g_tan.length() > 0.001:
		downhill_dir = g_tan.normalized()

	if tang.length() > 0.001:
		var tang_dir = tang.normalized()

		# se input está indo "subida" (oposto da gravidade tangencial)
		var is_uphill = (downhill_dir != Vector3.ZERO and tang_dir.dot(downhill_dir) < 0.0)

		# se está quase parado, não permite subir (evita hover)
		if is_uphill and v_tan.length() < GRAPPLE_MIN_TAN_SPEED_FOR_UPHILL:
			tang = Vector3.ZERO
		elif is_uphill:
			# permite um pouco de controle pra cima, mas bem menor
			tang *= GRAPPLE_UPHILL_INPUT_SCALE

		# aplica aceleração
		if tang.length() > 0.001:
			velocity += tang.normalized() * GRAPPLE_AIR_ACCEL * global_delta

	# re-separa depois do input
	v_rad = dir * velocity.dot(dir)
	v_tan = velocity - v_rad

	# damping (pode manter o seu)
	v_tan = v_tan.move_toward(Vector3.ZERO, GRAPPLE_DAMPING * global_delta)

	# clamp tangencial
	if v_tan.length() > GRAPPLE_MAX_TAN_SPEED:
		v_tan = v_tan.normalized() * GRAPPLE_MAX_TAN_SPEED

	velocity = v_tan + v_rad

