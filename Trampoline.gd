extends Area


export (int, 10, 50) var jumpPower
onready var audio = $"AudioStreamPlayer"
onready var boing = preload("res://audios/boing-bounce-sound-effect-427577.mp3")


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "_on_area_body_entered")
	boing.loop = false
	audio.stream = boing
	audio.volume_db = -10
	pass # Replace with function body.


func _on_area_body_entered(body):
	if body.is_in_group("Player"):
		audio.play()
		body.velocity.y = jumpPower
		body._snap_vector = Vector3.ZERO
		body.jump_flag = true
		body.state = body.JUMPING
		body.jump_timer = body.JUMP_TIME

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
