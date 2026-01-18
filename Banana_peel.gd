extends KinematicBody

var grounded = false
var GRAVITY = 12
var velocity = Vector3.ZERO
onready var SlipArea = $SlipArea


const slipAudio = preload("res://audios/9-7-cartoon-slip.mp3")


# Called when the node enters the scene tree for the first time.
func _ready():
	SlipArea.connect("area_entered", self, "_on_area_entered")
	SlipArea.connect("body_entered", self, "_on_body_entered")
	pass 

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_area_entered(area):
	if area.is_in_group("Player"):
		var player = area.get_parent()
		var abilities = player.get_child(0)
		var movement = player.get_child(2)
		movement.slip()

		# cria um player 2D temporário
		if not abilities.Shield_Flag:
			var p := AudioStreamPlayer.new()
			p.stream = slipAudio
			p.stream.loop = false
			get_tree().current_scene.add_child(p)
			p.volume_db = -20
			p.play()
		
			p.connect("finished", p, "queue_free")
	
		queue_free()


func _on_body_entered(body):
	if not body.is_in_group("Player") and not body.is_in_group("Banana_Peel"):
		grounded = true

func _physics_process(delta):
	if not grounded:
		velocity.y -= delta*GRAVITY
	if grounded:
		velocity.y = 0
		velocity.z = 0
		velocity.x = 0
	move_and_slide(velocity)
