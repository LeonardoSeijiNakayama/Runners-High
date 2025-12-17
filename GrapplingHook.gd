extends KinematicBody

onready var collision = $CollisionShape
onready var area = $Area

var player_id
var hooked = false
var speed = 50.0
var distance = null
var velocity = Vector3.ZERO

var anchor_pos = Vector3() 

onready var rope = $RopeMesh


func _ready():
	collision.set_deferred("disabled", true)
	area.connect("body_entered", self, "_on_body_entered")


func _physics_process(_delta):
	if not hooked:
		velocity = -transform.basis.z * speed
		move_and_slide(velocity)
	else:
		global_transform.origin = anchor_pos
	_update_rope()


func _update_rope() -> void:
	var pArray = get_tree().get_nodes_in_group(player_id)
	if pArray.empty(): 
		return
	var player = pArray[0]
	
	var p0 = player.global_transform.origin
	var p1
	if hooked:
		p1 = anchor_pos
	else:
		p1 = global_transform.origin
		
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
	
	var pArray = get_tree().get_nodes_in_group(player_id)
	if not pArray.empty() and distance == null:
		var player = pArray[0]
		distance = anchor_pos.distance_to(player.global_transform.origin)


func set_player(p) -> void:
	player_id = p
