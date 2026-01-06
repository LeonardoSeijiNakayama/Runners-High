extends Node
class_name PlayerCamera

export(bool) var smooth_camera_yaw := true
export(float, 0.0, 20.0) var turn_speed := 8.0

export(bool) var speed_effect_enabled := true
export(bool) var ignore_vertical_speed := true

export(float, 0.0, 999.0) var min_speed_for_effect := 3.0

export(float, 1.0, 179.0) var base_fov := 70.0
export(float, 1.0, 179.0) var max_fov := 100.0

export(float, 0.0, 10.0) var extra_arm_length_max := 5.0
export(float, 0.1, 999.0) var speed_for_max_effect := 18.0

export(float, 0.0, 50.0) var fov_lerp_speed := 2.0
export(float, 0.0, 50.0) var arm_lerp_speed := 2.0

export(float) var effect_deadzone_speed := 1.0  

export(float) var speed_point_a := 7.5
export(float, 0.0, 1.0) var effect_at_a := 0.3

export(float) var speed_point_b := 15.0
export(float, 0.0, 1.0) var effect_at_b := 0.6

onready var Player = get_parent()
onready var _spring_arm: SpringArm = Player.get_node("SpringArm") as SpringArm
onready var _cam3d: Camera = Player.get_node("SpringArm/Camera") as Camera
var _base_arm_length := 0.0

func _ready():
	if _spring_arm:
		_base_arm_length = _spring_arm.spring_length

	if _cam3d:
		_cam3d.current = true
		base_fov = _cam3d.fov


func update(ix, iz):
	var cam_basis = _spring_arm.global_transform.basis
	var cam_fwd = -cam_basis.z
	cam_fwd.y = 0
	cam_fwd = cam_fwd.normalized()
	
	var cam_right = cam_basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	return (cam_right * ix + cam_fwd * iz)


func rotatePlayerWithCamera(slipped:bool, delta:float):
	var cam_basis = _spring_arm.global_transform.basis
	var cam_fwd = -cam_basis.z
	var cam_yaw = atan2(cam_fwd.x, cam_fwd.z)
	
	if not slipped:
		if smooth_camera_yaw:
			Player.rotation.y = lerp_angle(Player.rotation.y, cam_yaw, clamp(turn_speed * delta, 0, 1))
		else:
			Player.rotation.y = cam_yaw


func apply_speed_fov(velocity: Vector3, delta: float) -> void:
	if not speed_effect_enabled or _spring_arm == null or _cam3d == null:
		return
	
	var v := velocity
	if ignore_vertical_speed:
		v.y = 0.0
	
	var speed := v.length()
	var t := _speed_to_effect_t(speed)
	
	
	if _cam3d.projection == Camera.PROJECTION_PERSPECTIVE:
		var target_fov = lerp(base_fov, max_fov, t)
		_cam3d.fov = lerp(_cam3d.fov, target_fov, clamp(fov_lerp_speed * delta, 0.0, 1.0))
	
	var target_len := _base_arm_length + (extra_arm_length_max * t)
	_spring_arm.spring_length = lerp(_spring_arm.spring_length, target_len, clamp(arm_lerp_speed * delta, 0.0, 1.0))


func _speed_to_effect_t(speed: float) -> float:
	if speed < effect_deadzone_speed:
		return 0.0
	
	# 0 -> A
	if speed <= speed_point_a:
		var u := (speed - effect_deadzone_speed) / max(0.001, (speed_point_a - effect_deadzone_speed))
		return lerp(0.0, effect_at_a, clamp(u, 0.0, 1.0))
	
	# A -> B
	if speed <= speed_point_b:
		var u := (speed - speed_point_a) / max(0.001, (speed_point_b - speed_point_a))
		return lerp(effect_at_a, effect_at_b, clamp(u, 0.0, 1.0))
	
	# acima de B
	return effect_at_b
