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
				_animation_player.play("HumanArmature|Man_Walk")
				lastState = state
			Player.WALLRUNNING_RIGHT:
				_animation_player.play("HumanArmature|Man_Clapping")
				lastState = state
			Player.FALLING:
				lastState = state


func playDeathAnimation()->void:
	_animation_player.play("HumanArmature|Man_Slipping")
