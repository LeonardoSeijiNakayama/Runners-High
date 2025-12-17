extends Node
class_name PlayerAnimation

onready var _animation_player = $"../Man2/AnimationPlayer"
onready var Player = get_parent()


func update(state: int, slipped: bool) -> void:
	if not slipped:
		match state:
			Player.IDLE:
				_animation_player.play("HumanArmature|Man_Idle")
			Player.JOGGING:
				_animation_player.play("HumanArmature|Man_Run")
			Player.RUNNING:
				_animation_player.play("HumanArmature|Man_Run", -1, 1.5)
			Player.JUMPING:
				_animation_player.play("HumanArmature|Man_Jump")
			Player.JOGGING_JUMP:
				_animation_player.play("HumanArmature|Man_RunningJump")
			Player.RUNNING_JUMP:
				_animation_player.play("HumanArmature|Man_RunningJump",-1,1.5)
			Player.WALLRUNNING:
				_animation_player.play("HumanArmature|Man_Walk")


func playDeathAnimation()->void:
	_animation_player.play("HumanArmature|Man_Slipping")
