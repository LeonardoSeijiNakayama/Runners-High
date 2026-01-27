extends KinematicBody

onready var collision = $CollisionShape
onready var area = $Area
onready var audio = $AudioStreamPlayer
onready var corda = preload("res://audios/dando-corda-449901.mp3")
onready var hit = preload("res://audios/hitting-wood-6791.mp3")

var player_id
var hooked = false
var speed = 50.0
var distance = null
var run_distance = null
var velocity = Vector3.ZERO
var player
var anchor_pos = Vector3() 
var spawn_offset_up := Vector3.UP * 1.17
var spawn_offset_forward := 0.2



onready var rope = $RopeMesh


func _ready():
	var pArray = get_tree().get_nodes_in_group(player_id)
	if not pArray.empty() and distance == null:
		player = pArray[0]
	collision.set_deferred("disabled", true)
	area.connect("body_entered", self, "_on_body_entered")
	hit.loop = false
	


func _physics_process(_delta):
	if not hooked:
		velocity = -transform.basis.z * speed
		move_and_slide(velocity)
		audio.pitch_scale = 2.0
		if not audio.playing:
			audio.stream = corda
			audio.volume_db = -10
			audio.play()
	else:
		global_transform.origin = anchor_pos
	_update_rope()


func _update_rope() -> void:
	var player_fwd = player.global_transform.basis.z.normalized()
	var p0 = player.global_transform.origin \
	+ player_fwd * spawn_offset_forward \
	+ spawn_offset_up

	var p1
	if hooked:
		p1 = anchor_pos
	else:
		p1 = global_transform.origin
		
	run_distance = global_transform.origin.distance_to(player.global_transform.origin)
	rope.update_rope(p0, p1)
	rope.visible = true


func _on_body_entered(body):
	if body.is_in_group("Player"):
		return
	elif body.is_in_group("Hookable"):
		get_hooked()


func get_hooked() -> void:
	hooked = true
	speed = 0.0
	velocity = Vector3.ZERO
	anchor_pos = global_transform.origin
	area.set_deferred("monitoring", false)
	audio.stream = hit
	if not audio.playing:
		audio.play()
	
	if player:
		distance = anchor_pos.distance_to(player.global_transform.origin)


func set_player(p) -> void:
	player_id = p
