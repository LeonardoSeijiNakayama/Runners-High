extends Area


const HOVER_CHANGE_TIME = 1.0
var degree = 0.0
var rotation_speed = 1.0
var rotation_speed_slow = rotation_speed/10
var hover_speed = 0.005
var hover_change_timer = 0.0
var hover_flag = true
var global_delta
var disappearing_timer := 0.0
var disappearing = false
var original_scale
var catched = false
const DISAPPEAR_TIME := 0.5



func _ready():
	connect("area_entered", self, "_on_area_entered")
	original_scale = scale
	pass 



func _process(delta):
	if disappearing:
		if disappearing_timer == 0:
			disappearing_timer = DISAPPEAR_TIME
		rotation_speed = rotation_speed_slow
		disappear()
	global_delta = delta
	rotation(degree, delta)
	hover(delta)



func rotation(degree:float, delta: float)->void:
	degree = rotation_speed * delta
	if degree >= 360.0:
		degree = 0.0
	rotate_y(degree)



func hover(delta:float)->void:
	if hover_flag:
		if hover_change_timer <=0:
			hover_change_timer = HOVER_CHANGE_TIME
			hover_flag = false
		else:
			hover_change_timer-=delta
		position.y += hover_speed
	else:
		if hover_change_timer <=0:
			hover_change_timer = HOVER_CHANGE_TIME
			hover_flag = true
		else:
			hover_change_timer-=delta
		position.y -= hover_speed



func disappear()->void:
	rotation_speed = 50
	if disappearing_timer <= 0:
		disappearing_timer = 0
		queue_free()
	else:
		var t := disappearing_timer/DISAPPEAR_TIME
		t = clamp(t, 0.0, 1.0)
		disappearing_timer-=global_delta
		scale = original_scale*t



func _on_area_entered(area):
	if area.is_in_group("Player"):
		var player = area.get_parent()
		if player.current_hability == player.HABILITY_NONE:
			var id = player.playerId
			if not catched:
				player.get_item()
				disappearing = true
				catched = true
