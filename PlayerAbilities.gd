extends Node
class_name PlayerAbilities   

const HABILITY_NONE   := 0
const MISSILE         := 1
const BANANA_PEEL     := 2
const RUNNERS_HIGH    := 3
const SHIELD          := 4

onready var banana_scene  = preload("res://Banana_peel.tscn")
onready var shield_scene  = preload("res://Shield.tscn")
onready var missile_scene = preload("res://Missile.tscn")
onready var gp_hook_scene = preload("res://GrapplingHook.tscn")

var current_hability := HABILITY_NONE

var RH_Flag := false
var RH_Timer := 0.0
export(float) var RH_TIME    := 5.0

var Shield_Flag := false
var Shield_Timer := 0.0
export(float) var SHIELD_TIME := 5.0
var shield: Node = null

var GP_TIME = 1.0
var Gp_Timer = 0.0
var Gp_Flag = false
var Gp_Hook

var rng := RandomNumberGenerator.new()

onready var Player := get_parent()
onready var PlayerMove = $"../Movement"

func _ready() -> void:
	rng.randomize()


func physics_update(delta: float) -> void:
	_update_runners_high(delta)
	_update_shield(delta)
	_update_gp(delta)
	gp_hook_logic()


func handle_input() -> void:
	if Input.is_action_just_pressed(Player.prefix + "hability"):
		match current_hability:
			HABILITY_NONE:
				print("none")
			MISSILE:
				_throw_missile()
				current_hability = HABILITY_NONE
			BANANA_PEEL:
				_drop_banana()
				current_hability = HABILITY_NONE
			RUNNERS_HIGH:
				if not RH_Flag:
					RH_Flag = true
					RH_Timer = RH_TIME
			SHIELD:
				if not Shield_Flag:
					Shield_Flag = true
					Shield_Timer = SHIELD_TIME
					shield = shield_scene.instance()
					Player.add_child(shield)
					shield.global_position = Player.global_position
	
	if Input.is_action_pressed(Player.prefix + "grappling_hook") and not Gp_Flag and not Player.is_on_floor() and not Player.slipped:
		shoot_gp()
	
	if Input.is_action_just_released(Player.prefix + "grappling_hook"):
		release_gp()


func gp_hook_logic()->void:
	if Gp_Hook and Gp_Hook.hooked and Gp_Hook.distance != null:
		PlayerMove.set_grapple(true, Gp_Hook.anchor_pos, Gp_Hook.distance)
	else:
		PlayerMove.set_grapple(false)


func release_gp()->void:
	PlayerMove.set_grapple(false)
	if Gp_Hook:
		Gp_Hook.queue_free()
		Gp_Hook = null


func shoot_gp()->void:
	if not Gp_Hook:
			Gp_Hook = gp_hook_scene.instance()
			var cam_basis = Player._spring_arm.global_transform.basis
			var cam_dir = -cam_basis.z.normalized()
			
			Gp_Hook.set_player(Player.prefix)
			Player.get_parent().add_child(Gp_Hook)
			
			Gp_Hook.global_transform.origin = Player.global_transform.origin + cam_dir
			Gp_Hook.look_at(Gp_Hook.global_transform.origin + cam_dir, Vector3.UP)
			
			Gp_Flag = true
			Gp_Timer = GP_TIME


func get_new_hability() -> void:
	current_hability = rng.randi_range(1, 4)
	print(current_hability)


func is_runners_high_active() -> bool:
	return RH_Flag


func _update_gp(delta:float)->void:
	if Gp_Flag:
		if Gp_Timer<=0.0:
			Gp_Timer = 0.0
			Gp_Flag = false
		Gp_Timer -= delta


func _update_runners_high(delta: float) -> void:
	if RH_Flag:
		RH_Timer -= delta
		# Afeta o pulo do player
		Player.jump_force = 8.0
		if RH_Timer <= 0.0:
			RH_Flag = false
			RH_Timer = 0.0
			current_hability = HABILITY_NONE
			Player.jump_force = 6.0


func _update_shield(delta: float) -> void:
	if Shield_Flag:
		Shield_Timer -= delta
		if shield:
			shield.global_transform.origin = Player.global_transform.origin
		if Shield_Timer <= 0.0:
			Shield_Flag = false
			Shield_Timer = 0.0
			current_hability = HABILITY_NONE
			if shield:
				shield.queue_free()
				shield = null


func _drop_banana() -> void:
	var banana = banana_scene.instance()
	Player.get_parent().add_child(banana)
	var behind_dir = -Player.global_transform.basis.z.normalized()
	var offset = behind_dir * 1.0
	banana.global_transform.origin = Player.global_transform.origin + offset


func _throw_missile() -> void:
	var missile = missile_scene.instance()
	if Player.playerId == 1:
		missile.target = 2
	else:
		missile.target = 1
	
	Player.get_parent().add_child(missile)
	
	var front_dir = Player.global_transform.basis.z.normalized()
	var up_dir = Player.global_transform.basis.y.normalized()
	var offset = front_dir * 1.0 + up_dir * 2.0
	
	missile.global_transform.origin = Player.global_transform.origin + offset
