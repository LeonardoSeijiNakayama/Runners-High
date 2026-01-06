extends Area


export (int, 10, 50) var jumpPower


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "_on_area_body_entered")
	pass # Replace with function body.


func _on_area_body_entered(body):
	if body.is_in_group("Player"):
		body.velocity.y = jumpPower
		body._snap_vector = Vector3.ZERO
		body.state = body.JUMPING

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
