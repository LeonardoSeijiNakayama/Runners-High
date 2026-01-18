extends KinematicBody

export var state = 0
const IDLE = 0
const JOGGING = 1
const RUNNING = 2
const JUMPING = 3
const RUNNING_JUMP = 4
const JOGGING_JUMP = 5
const WALLRUNNING_LEFT = 6
const WALLRUNNING_RIGHT = 7
const FALLING = 8
const SLIPPED = 9
const SWINGING = 10
const ASCENDING = 11


export(int, 1, 2) var playerId := 1

const NORMAL_SPEED = 7.5
const WR_SPEED = 17.0
const RUNNING_SPEED = 15
const NORMAL_GRAVITY = 12
const WR_GRAVITY := 2

export var speed := NORMAL_SPEED
export var gravity := NORMAL_GRAVITY
export var jump_force := 6.0
export var stamina_max = 100.0
export var stamina := 100.0
var velocity := Vector3.ZERO
var _snap_vector := Vector3.DOWN
var boost = false
var jump_flag = false
var jump_timer = 0.0
const JUMP_TIME = 0.725

signal stamina_changed(current, maxv)

var prefix = ""
export var slipped = false

var global_delta
var checkpointPosition
var currentCheckpoint = 0
var onFinalCheckpoint = false
var currentLap = 0

onready var abilities: PlayerAbilities = $Abilities
onready var animation: PlayerAnimation = $Animation
onready var movement = $Movement
onready var camera: PlayerCamera = $Camera
onready var _spring_arm: SpringArm = $SpringArm
onready var audio = $Audio


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
	var ix := Input.get_action_strength(prefix+"right") - Input.get_action_strength(prefix+"left")
	var iz := Input.get_action_strength(prefix+"up")  - Input.get_action_strength(prefix+"down")
	
	var cam_basis := _spring_arm.global_transform.basis
	var cam_fwd := -cam_basis.z
	cam_fwd.y = 0
	cam_fwd = cam_fwd.normalized()
	var cam_right := cam_basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	var input_dir = camera.update(ix, iz)
	if input_dir.length() > 0.001:
		input_dir = input_dir.normalized()
	
	movement.physics_update(delta, input_dir, prefix, slipped)
	
	stamina = clamp(stamina, 0, 100)
	
	camera.rotatePlayerWithCamera(slipped, delta)
	
	abilities.physics_update(delta)



func _process(_delta) -> void:
	animation.update(state, slipped)
	audio.update(state, slipped)
	abilities.handle_input()
	_spring_arm.translation = translation




