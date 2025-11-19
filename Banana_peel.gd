extends KinematicBody


var GRAVITY = 12
var velocity = Vector3.ZERO
onready var SlipArea = $SlipArea


# Called when the node enters the scene tree for the first time.
func _ready():
	SlipArea.connect("area_entered", self, "_on_area_entered")
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_area_entered(area):
	if area.is_in_group("Player"):
		var player = area.get_parent()
		player.slip()
		queue_free()

func _physics_process(delta):
	velocity.y -= delta*GRAVITY
	move_and_slide(velocity)
