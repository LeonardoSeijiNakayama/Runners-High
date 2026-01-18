extends Node
class_name PlayerAnimation

onready var _animation_player = $"../Man2/AnimationPlayer"
onready var Player = get_parent()

var lastState = null


func update(state: int, slipped: bool) -> void:
	if not slipped:
		match state:
			Player.IDLE:
				_animation_player.play("HumanArmature|Man_Idle")
				lastState = state
			Player.JOGGING:
				_animation_player.play("HumanArmature|Man_Run")
				lastState = state
			Player.RUNNING:
				_animation_player.play("HumanArmature|Man_Run", -1, 1.5)
				lastState = state
			Player.JUMPING:
				if state == lastState:
					return
				_animation_player.play("HumanArmature|Man_Jump")
				lastState = state
			Player.JOGGING_JUMP:
				_animation_player.play("HumanArmature|Man_RunningJump")
				lastState = state
			Player.RUNNING_JUMP:
				_animation_player.play("HumanArmature|Man_RunningJump",-1,1.5)
				lastState = state
			Player.WALLRUNNING_LEFT:
				_animation_player.play("HumanArmature|Sliding_Left")
				lastState = state
			Player.WALLRUNNING_RIGHT:
				_animation_player.play("HumanArmature|Sliding_Right")
				lastState = state
			Player.FALLING:
				_animation_player.play("HumanArmature|Man_Falling")
				lastState = state
			Player.ASCENDING:
				_animation_player.play("HumanArmature|Man_Ascending")
				lastState = state
			Player.SWINGING:
				_animation_player.play("HumanArmature|Man_Swinging")
				lastState = state


func playDeathAnimation()->void:
	_animation_player.play("HumanArmature|Man_Slipping")
