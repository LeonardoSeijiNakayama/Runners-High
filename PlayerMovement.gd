extends Node
class_name PlayerMovement

signal stamina_changed(current, maxv)

var global_delta

export (float, 0.0, 5.0) var st_timer := 0.0
export (float, 0.0, 0.5) var wr_slip_timer := 0.0
export (float, 0.0, 1.0) var wr_cooldown := 0.0

var wr_flag := false


const GET_UP_TIME = 3.0
var get_up_timer = 0
const SLIP_TIME = 0.35
var slip_timer = 0

var grapple_active := false
var grapple_anchor := Vector3.ZERO
var grapple_len := 0.0
var is_idle = true

export var POST_GRAPPLE_STEER_ACCEL := 12.0 # força do input pra puxar pro target
export var POST_GRAPPLE_DRAG_AIR := 0.1 # resistência no ar
export var POST_GRAPPLE_DRAG_GROUND := 3.0 # resistência no chão
export var POST_GRAPPLE_WIN_EPS := 0.50 # quão perto do target pra “acabou”
export var POST_GRAPPLE_STOP_SPEED := 0.70 # se não tem input, para quando ficar lento
export var POST_GRAPPLE_GROUND_TIME := 0.35 # quanto tempo o "slide" dura ao tocar no chão
var post_grapple_ground_timer := -1.0       # -1 = ainda não começou (só começa ao encostar no chão)


var post_grapple_active := false
var post_grapple_vel := Vector3.ZERO # guarda a velocidade horizontal “carregada”


onready var Player = get_parent()
onready var abilities = $"../Abilities"
onready var animation = $"../Animation"
onready var camera = $"../Camera"


func _ready():
	pass



func physics_update(delta:float, input_dir:Vector3, prefix:String, slipped:bool):
	global_delta = delta
	
	if not Player.is_on_floor():
		if not grapple_active:
			Player.velocity.y -= Player.gravity * delta
	else:
		abilities.release_gp()
	
	# lógica do wallrun
	wall_run(prefix)
	# Movimento no referencial da camera
	movement(input_dir, prefix)
	# lógica de pulo/estado no ar
	jump(input_dir, prefix, slipped)
	
	Player.velocity = Player.move_and_slide_with_snap(Player.velocity, Player._snap_vector, Vector3.UP, true)
	
	check_idle(input_dir)
	
	if grapple_active:
		_apply_grapple_constraint()
	
	camera.apply_speed_fov(Player.velocity, delta)
	
	Player.stamina = clamp(Player.stamina, 0, 100)



func check_idle(input_dir)->void:
	var horiz = Vector2(Player.velocity.x, Player.velocity.z).length()
	is_idle = Player.is_on_floor() \
	and input_dir.length() <= 0.1 \
	and horiz < 0.2 \
	and (Player.state != Player.WALLRUNNING_LEFT or Player.state != Player.WALLRUNNING_RIGHT )\
	and not Player.slipped \
	and not Player.state == Player.SWINGING
	if is_idle:
		Player.state = Player.IDLE



func set_stamina(v:float) ->void:
	Player.stamina = clamp(v, 0.0, Player.stamina_max)
	emit_signal("stamina_changed", Player.stamina, Player.stamina_max)



func slip():
	if Player.slipped:
		return
	
	if not abilities.Shield_Flag:
		abilities.release_gp()
		Player._snap_vector = Vector3.ZERO
		Player.velocity.y = 2
		Player.velocity.z = Player.velocity.z * 1.75
		Player.velocity.x = Player.velocity.x * 1.75
		Player.slipped = true
		get_up_timer = GET_UP_TIME
		slip_timer = SLIP_TIME
		animation.playDeathAnimation()
		
	else:
		abilities.Shield_Flag = false
		abilities.Shield_Timer = 0.0
		abilities.current_ability = abilities.ABILITY_NONE
		abilities.shield.queue_free()



func wall_run(prefix:String)->void:
	if (wr_cooldown < 1.0):
		wr_cooldown += global_delta
	
	if Player.is_on_floor() or grapple_active:
		wr_flag = false
		wr_slip_timer = 0.0
		wr_cooldown = 0.0
	
	if Input.is_action_pressed(prefix+"jump") \
	and !Player.is_on_floor() \
	and Player.is_on_wall() \
	and _is_wall_runnable() \
	and wr_cooldown >= 1.0 \
	and not Player.slipped \
	and (Input.get_action_strength(prefix+"left") > 0.0 or Input.get_action_strength(prefix+"right") > 0.0):
		
		
		
		Player.speed = Player.WR_SPEED
		
		if Input.get_action_strength(prefix+"left") > 0.0:
			Player.state = Player.WALLRUNNING_LEFT
		if Input.get_action_strength(prefix+"right") > 0.0:
			Player.state = Player.WALLRUNNING_RIGHT
	
		wr_flag = true
		if (wr_slip_timer < 1):
			wr_slip_timer += global_delta
			Player.velocity.y = 0.0
		else:
			Player.gravity = Player.WR_GRAVITY

	elif Input.is_action_just_released(prefix+"jump") and wr_flag and Player.is_on_wall():
		Player.velocity.y = Player.jump_force
		Player.gravity = Player.NORMAL_GRAVITY
		Player.speed = Player.NORMAL_SPEED
		Player._snap_vector = Vector3.ZERO
		wr_flag = false
		wr_slip_timer = 0.0
		wr_cooldown = 0.0
	else:
		Player.gravity = Player.NORMAL_GRAVITY
		Player.speed = Player.NORMAL_SPEED
		wr_flag = false



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



func jump(input_dir:Vector3, prefix:String, slipped:bool)->void:
	if Player.jump_timer >0:
		Player.jump_timer -= global_delta
	if Player.jump_timer <0.0:
		Player.jump_flag = false
		Player.jump_timer = 0.0
	
	if Input.is_action_just_pressed(prefix+"jump") and Player.is_on_floor():
		Player.jump_flag = true
		Player.jump_timer = Player.JUMP_TIME
		if is_idle:
			Player.state = Player.JUMPING
		elif Input.is_action_pressed(prefix+"run") and input_dir.length() != 0:
			Player.state = Player.RUNNING_JUMP
		else:
			Player.state = Player.JOGGING_JUMP
		Player.velocity.y = Player.jump_force
		Player._snap_vector = Vector3.ZERO
	elif not Player.is_on_floor() and (Player.state != Player.WALLRUNNING_LEFT or Player.state != Player.WALLRUNNING_RIGHT):
		if Player.state == Player.JUMPING:
			Player.state = Player.JUMPING
		elif Player.state == Player.RUNNING_JUMP:
			Player.state = Player.RUNNING_JUMP
		elif Player.state == Player.JOGGING_JUMP:
			Player.state = Player.JOGGING_JUMP
	elif Player.is_on_floor() and Player._snap_vector == Vector3.ZERO and Player.velocity.y <= 0.0:
		if not slipped:
			Player._snap_vector = Vector3.DOWN
	if Player.velocity.y < 0 and not (Player.is_on_floor()\
	or Player.state == Player.SWINGING\
	or wr_flag): 
		Player.state = Player.FALLING
	if Player.velocity.y > 0 and not Player.is_on_floor()\
	and not (Player.state == Player.SWINGING\
	or Player.jump_flag): 
		Player.state = Player.ASCENDING



func movement(input_dir:Vector3, prefix:String)->void:
	if grapple_active:
		_grapple_air_control(input_dir)
		return
	
	if Player.state == Player.WALLRUNNING_LEFT or Player.state == Player.WALLRUNNING_RIGHT:
		Player.velocity.x = input_dir.x * Player.WR_SPEED
		Player.velocity.z = input_dir.z * Player.WR_SPEED
		return
	
	var dir := input_dir
	
	if not Player.slipped:
		if Input.is_action_pressed(prefix+"run") \
		and Player.stamina > 0 \
		and (Player.state != Player.WALLRUNNING_LEFT or Player.state != Player.WALLRUNNING_RIGHT):
			if Player.is_on_floor():
				if input_dir.length() != 0:
					Player.state = Player.RUNNING
			if not abilities.RH_Flag:
				set_stamina(Player.stamina - 10.0 * global_delta)
			Player.speed = Player.RUNNING_SPEED
			st_timer = 0.0
		else:
			if Player.is_on_floor():
				if input_dir.length() != 0:
					Player.state = Player.JOGGING
			Player.speed = Player.NORMAL_SPEED
			st_timer += global_delta
			if (Player.stamina < 100.0 and st_timer >= 1.5):
				set_stamina(Player.stamina + 7.5 * global_delta)
		var sp = Player.speed
		var target_h := Vector3(dir.x * sp, 0.0, dir.z * sp)
	
		if post_grapple_active and not grapple_active and (Player.state != Player.WALLRUNNING_LEFT and Player.state != Player.WALLRUNNING_RIGHT):
			
			var on_floor = Player.is_on_floor()
			
			# --- NO CHÃO: momentum limitado por tempo ---
			if on_floor:
				# começa a contagem só quando encostar no chão
				if post_grapple_ground_timer < 0.0:
					post_grapple_ground_timer = POST_GRAPPLE_GROUND_TIME
				else:
					post_grapple_ground_timer -= global_delta
					
				# acabou o tempo? termina o pós e volta pro normal
				if post_grapple_ground_timer <= 0.0:
					post_grapple_active = false
					Player.velocity.x = target_h.x
					Player.velocity.z = target_h.z
					return
					
			# --- Drag sempre atua (no ar ou no chão) ---
			var drag := POST_GRAPPLE_DRAG_GROUND if on_floor else POST_GRAPPLE_DRAG_AIR
			var k := max(0.0, 1.0 - drag * global_delta)
			post_grapple_vel *= k
			
			# --- Se tem input, o jogador "vence" puxando pro target (no ar e no chão) ---
			if dir.length() > 0.05:
				post_grapple_vel = post_grapple_vel.move_toward(target_h, POST_GRAPPLE_STEER_ACCEL * global_delta)
			
			# aplica a velocidade carregada
			Player.velocity.x = post_grapple_vel.x
			Player.velocity.z = post_grapple_vel.z
			
			# --- NO AR vence pelo EPS / STOP ---
			if not on_floor:
				var err := (post_grapple_vel - target_h).length()
				if dir.length() > 0.05:
					if err < POST_GRAPPLE_WIN_EPS:
						post_grapple_active = false
				else:
					if post_grapple_vel.length() < POST_GRAPPLE_STOP_SPEED:
						post_grapple_active = false
		else:
			Player.velocity.x = target_h.x
			Player.velocity.z = target_h.z
	else:
		if Player.velocity.z > 0.0:
			Player.velocity.z -= global_delta
		elif Player.velocity.z<0.0:
			Player.velocity.z += global_delta
		
		if Player.velocity.x >0.0:
			Player.velocity.x -= global_delta
		elif Player.velocity.x<0.0:
			Player.velocity.x += global_delta
		
		get_up_timer-=global_delta 
		slip_timer-=global_delta
		
		if slip_timer <=0:
			slip_timer = 0
			if Player.is_on_floor():
				Player.velocity.z = 0
				Player.velocity.x = 0
		
		if get_up_timer <=0: 
			get_up_timer = 0 
			Player.slipped = false



func set_grapple(active: bool, anchor := Vector3.ZERO, length := 0.0) -> void:
	# soltou agora
	if grapple_active and not active:
		post_grapple_active = true
		post_grapple_vel = Vector3(Player.velocity.x, 0.0, Player.velocity.z)
		post_grapple_ground_timer = -1.0

		# saiu do swinging: se estiver no ar, cai
		if not Player.is_on_floor():
			Player.state = Player.FALLING

	# engatou agora
	if active and not grapple_active:
		post_grapple_active = false
		post_grapple_ground_timer = -1.0
	
		Player._snap_vector = Vector3.ZERO
		wr_flag = false

	grapple_active = active
	grapple_anchor = anchor
	grapple_len = length





export var GRAPPLE_MAX_ANGLE_DEG := 100.0



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
	if angle_deg > GRAPPLE_MAX_ANGLE_DEG and Player.velocity.y >= 0.0:
		if is_instance_valid(abilities) and abilities.has_method("release_gp"):
			abilities.release_gp()
		else:
			set_grapple(false)
		return
	
	# remove componente radial da velocidade para a corda não esticar
	var radial_speed = Player.velocity.dot(dir)
	Player.velocity -= dir * radial_speed
	
	# projeta posição para ficar exatamente no raio da corda
	var target = grapple_anchor + dir * grapple_len
	Player.global_transform.origin = target



export var GRAPPLE_AIR_ACCEL := 10.0        
export var GRAPPLE_DAMPING := 4.0           
export var GRAPPLE_MAX_TAN_SPEED := 20.0    
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
	Player.velocity += g_tan * global_delta

	# --- input na tangente ---
	var tang = input_dir - dir * input_dir.dot(dir)

	# separa velocidades
	var v_rad = dir * Player.velocity.dot(dir)
	var v_tan = Player.velocity - v_rad

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
			Player.velocity += tang.normalized() * GRAPPLE_AIR_ACCEL * global_delta
	
	v_rad = dir * Player.velocity.dot(dir)
	v_tan = Player.velocity - v_rad
	
	v_tan = v_tan.move_toward(Vector3.ZERO, GRAPPLE_DAMPING * global_delta)
	
	if v_tan.length() > GRAPPLE_MAX_TAN_SPEED:
		v_tan = v_tan.normalized() * GRAPPLE_MAX_TAN_SPEED
	
	Player.velocity = v_tan + v_rad


