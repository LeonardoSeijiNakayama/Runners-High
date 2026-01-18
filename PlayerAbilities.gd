extends Node
class_name PlayerAbilities   

const ABILITY_NONE   := 0
const MISSILE         := 1
const BANANA_PEEL     := 2
const RUNNERS_HIGH    := 3
const SHIELD          := 4

onready var banana_scene  = preload("res://Banana_peel.tscn")
onready var shield_scene  = preload("res://Shield.tscn")
onready var missile_scene = preload("res://Missile.tscn")
onready var gp_hook_scene = preload("res://GrapplingHook.tscn")


var spawn_offset_up := Vector3.UP * 1.2 

var current_ability := ABILITY_NONE

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
onready var psy_fx = Player.get_child(7).get_node("Camera/CanvasLayer/PsyFX")
onready var psy_mat = psy_fx.material as ShaderMaterial

signal ability_changed(name)

func _ready() -> void:
	rng.randomize()


func physics_update(delta: float) -> void:
	_update_runners_high(delta)
	_update_shield(delta)
	_update_gp(delta)
	gp_hook_logic()


func handle_input() -> void:
	if Input.is_action_just_pressed(Player.prefix + "hability") and not Shield_Flag and not RH_Flag:
		emit_signal("ability_changed", "-")
		match current_ability:
			ABILITY_NONE:
				return
			MISSILE:
				_throw_missile()
				current_ability = ABILITY_NONE
			BANANA_PEEL:
				_drop_banana()
				current_ability = ABILITY_NONE
			RUNNERS_HIGH:
				if not RH_Flag:
					current_ability = ABILITY_NONE
					RH_Flag = true
					RH_Timer = RH_TIME
					psy_fx.visible = true
					psy_mat.set_shader_param("strength", 0.0)
			SHIELD:
				if not Shield_Flag:
					current_ability = ABILITY_NONE
					Shield_Flag = true
					Shield_Timer = SHIELD_TIME
					shield = shield_scene.instance()
					Player.add_child(shield)
					shield.global_position = Player.global_position
	
	if Input.is_action_pressed(Player.prefix + "grappling_hook") and not Gp_Flag and not Player.is_on_floor() and not Player.slipped:
		shoot_gp()
		Player.state = Player.SWINGING
	if Input.is_action_just_released(Player.prefix + "grappling_hook"):
		Player.state = Player.IDLE
	
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
			
			Gp_Hook.global_transform.origin = Player.global_transform.origin + cam_dir + spawn_offset_up
			
			Gp_Hook.look_at(Gp_Hook.global_transform.origin + cam_dir, Vector3.UP)
			
			Gp_Flag = true
			Gp_Timer = GP_TIME
	else:
		if Gp_Hook.run_distance >= 75.0:
			release_gp()


func get_new_ability() -> void:
	current_ability = rng.randi_range(1, 3)
	var name = ""
	match current_ability:
			MISSILE:
				name = "Missile"
			BANANA_PEEL:
				name = "Banana Peel"
			RUNNERS_HIGH:
				name = "Runners High"
			SHIELD:
				name = "Shield"
	emit_signal("ability_changed", name)


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

		# buff
		Player.jump_force = 8.0

		# força do efeito (sobe rápido e fica)
		var target = 1.0
		var current = float(psy_mat.get_shader_param("strength"))
		current = lerp(current, target, 8.0 * delta)
		psy_mat.set_shader_param("strength", current)

		if RH_Timer <= 0.0:
			RH_Flag = false
			RH_Timer = 0.0
			Player.jump_force = 6.0

	else:
		# fade out suave
		if psy_fx.visible:
			var current = float(psy_mat.get_shader_param("strength"))
			current = lerp(current, 0.0, 10.0 * delta)
			psy_mat.set_shader_param("strength", current)
			if current <= 0.02:
				psy_mat.set_shader_param("strength", 0.0)
				psy_fx.visible = false


func _update_shield(delta: float) -> void:
	if Shield_Flag:
		Shield_Timer -= delta
		if shield:
			shield.global_transform.origin = Player.global_transform.origin
		if Shield_Timer <= 0.0:
			Shield_Flag = false
			Shield_Timer = 0.0
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
