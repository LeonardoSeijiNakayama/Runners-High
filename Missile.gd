extends KinematicBody

var velocity = Vector3.ZERO
var speed = 17
var ascending_speed = 8
var target_group
var ascending = true
var ascending_timer = 0
var global_delta
var rotation_speed = 1.0
const ASCENDING_TIME = 3
var degree = 0.0
export (int, 1, 2) var target := 1
onready var collision = $CollisionShape
onready var area = $Area
onready var fire_animation = $"fire/AnimationPlayer"
onready var fire = $fire

var explosion_scene = preload("res://Fireball.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	if target == 1:
		target_group = "p1_"
	else: 
		target_group = "p2_"
	collision.set_deferred("disabled", true)
	area.connect("body_entered", self, "_on_body_entered")
	ascending_timer = ASCENDING_TIME
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_delta = delta
	match target_group:
		"p1_":
			follow_target()
		"p2_":
			follow_target()
	fire_animation.play("Take 001", 3.0, true)



func follow_target() -> void:
	var pArray = get_tree().get_nodes_in_group(target_group)
	if pArray.empty():
		return
	
	var player = pArray[0]
	var dir = (player.global_transform.origin - global_transform.origin).normalized()
	
	if ascending:
		if ascending_timer >= 4.0:
			ascending = false
			ascending_timer = 3.0
		ascending_timer += global_delta * 1.5
		velocity.y = (log(ascending_timer)/log(2))*3
		velocity.x = ascending_speed * dir.x
		velocity.z = ascending_speed * dir.z
	else:
		velocity = dir * speed
	velocity = move_and_slide(velocity, Vector3.UP)
	var move_dir = velocity
	
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()
		look_at(global_transform.origin + move_dir, Vector3.UP)



func _on_body_entered(body):
	if body.is_in_group("Player"):
		var movement = body.get_child(2)
		if body.is_in_group(target_group):
			movement.slip()
	queue_free()
	var explosion = explosion_scene.instance()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
