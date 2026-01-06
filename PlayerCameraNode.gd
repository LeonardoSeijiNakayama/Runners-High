extends Spatial

export var mouse_sensitivity := 0.05

export var stick_sensitivity := 180.0
export var stick_deadzone := 0.15

onready var playerId = $"../".playerId
var prefix = ""

func _ready():
	set_as_toplevel(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if playerId == 1:
		prefix = "p1_"
	else:
		prefix = "p2_"



func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_apply_look(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)



func _process(delta: float) -> void:
	var look_x := Input.get_action_strength(prefix + "look_right") - Input.get_action_strength(prefix + "look_left")
	var look_y := Input.get_action_strength(prefix + "look_down")  - Input.get_action_strength(prefix + "look_up")
	
	
	if abs(look_x) < stick_deadzone:
		look_x = 0.0
	if abs(look_y) < stick_deadzone:
		look_y = 0.0
	
	if look_x != 0.0 or look_y != 0.0:
		_apply_look(-look_x * stick_sensitivity * delta, -look_y * stick_sensitivity * delta)



func _apply_look(delta_yaw_deg: float, delta_pitch_deg: float) -> void:
	rotation_degrees.x += delta_pitch_deg
	rotation_degrees.x = clamp(rotation_degrees.x, -90.0, 30.0)
	
	rotation_degrees.y += delta_yaw_deg
	rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360.0)
