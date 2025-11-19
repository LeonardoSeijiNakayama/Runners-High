extends Area

onready var animation1 = $Icosphere1/AnimationPlayer
onready var animation2 = $Icosphere2/AnimationPlayer
onready var animation3 = $Icosphere3/AnimationPlayer

var timer = 0.0
var TTL = 1.0
var settle_timer = 0.0
var SETTLE_TIME = 2.0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	timer = TTL
	animation1.play("Icosphere001Action", 1.5, true)
	animation2.play("Icosphere001Action001", 1.0, true)
	animation3.play("IcosphereAction", 2.0, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if timer <=0.0:
		timer = 0.0
		if settle_timer <=0.0:
			settle_timer = 0.0
		else:
			settle_timer -= delta
			
		queue_free()
	else:
		timer -=  delta
	
