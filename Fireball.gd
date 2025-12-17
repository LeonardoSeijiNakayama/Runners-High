extends Area

onready var animation1 = $Icosphere1/AnimationPlayer
onready var animation2 = $Icosphere2/AnimationPlayer
onready var animation3 = $Icosphere3/AnimationPlayer
onready var light = $OmniLight

var timer = 0.0
var TTL = 1.0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	timer = 0.0
	animation1.play("Icosphere001Action", 2.5, true)
	animation2.play("Icosphere001Action001", 2.0, true)
	animation3.play("IcosphereAction", 3.0, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if timer >=TTL:
		timer = TTL
		queue_free()
	else:
		timer +=  delta
		light.light_energy = timer*4
	
