extends Area

onready var spawnArea = $SpawnArea

export (int,1,12) var id = 1
export (bool) var final = false


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "_on_body_entered")
	pass # Replace with function body.


func _on_body_entered(body):
	if body.is_in_group("Player"):
		var laps = body.get_child(4)
		if body.currentCheckpoint == id-1:
			if final:
				body.onFinalCheckpoint = true
			else:
				body.onFinalCheckpoint = false
			body.checkpointPosition = spawnArea.global_position
			body.currentCheckpoint = id
		elif body.onFinalCheckpoint and id == 1:
			body.checkpointPosition = spawnArea.global_position
			body.currentCheckpoint = id
			body.onFinalCheckpoint = false
			laps.next_lap()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
