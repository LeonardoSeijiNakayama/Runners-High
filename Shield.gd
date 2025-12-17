extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


func _ready():
	pass

func _process(delta):
	rotate_y(delta*4)
