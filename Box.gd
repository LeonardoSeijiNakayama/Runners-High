extends Area

const HOVER_CHANGE_TIME = 1.0
var degree = 0.0
var rotation_speed = 1.0
const rotation_speed_normal = 1.0
const rotation_speed_slow = 0.1
var hover_speed = 0.005
var hover_change_timer = 0.0
var hover_flag = true
var global_delta
var disappearing_timer := 0.0
var disappearing = false
var original_scale
var catched = false
var REESPAWN_TIME = 5.0
var reespawn_timer = 0.0
const DISAPPEAR_TIME := 0.5

onready var audio := $AudioStreamPlayer
onready var pick_up : AudioStream = preload("res://audios/pick_up.mp3")



func _ready():
	pick_up.loop = false
	connect("area_entered", self, "_on_area_entered")
	original_scale = scale
	pass 



func _process(delta):
	if disappearing:
		if disappearing_timer == 0:
			disappearing_timer = DISAPPEAR_TIME
		rotation_speed = rotation_speed_slow
		disappear()
	if catched:
		if reespawn_timer == 0:
			reespawn_timer = REESPAWN_TIME
		reespawn()
		
	global_delta = delta
	rotation(delta)
	hover(delta)


func reespawn()->void:
	if reespawn_timer <= 0:
		reespawn_timer = 0.0
		scale = original_scale
		disappearing = false
		catched = false
		set_deferred("monitoring", true)
		visible = true
		rotation_speed = rotation_speed_normal
	else:
		reespawn_timer -= global_delta


func rotation(delta: float)->void:
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
		set_deferred("monitoring", false)
		visible = false
	else:
		var t := disappearing_timer/DISAPPEAR_TIME
		t = clamp(t, 0.0, 1.0)
		disappearing_timer-=global_delta
		scale = original_scale*t



func _on_area_entered(area):
	if area.is_in_group("Player"):
		var player = area.get_parent()
		var playerAbilities = player.get_child(0)
		if playerAbilities.current_ability == playerAbilities.ABILITY_NONE:
			if not catched:
				playerAbilities.get_new_ability()
				disappearing = true
				catched = true
				audio.stream = pick_up
				audio.volume_db = -20
				audio.play()
