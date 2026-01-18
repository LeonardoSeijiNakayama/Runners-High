extends Node

onready var audio = $AudioStreamPlayer
onready var Player = get_parent()
onready var lap_audio : AudioStream = preload("res://audios/game-level-complete-143022.mp3")

signal lap_changed(current)

# Called when the node enters the scene tree for the first time.
func _ready():
	lap_audio.loop = false
	pass # Replace with function body.


func next_lap()->void:
	Player.currentLap += 1
	emit_signal("lap_changed", Player.currentLap)
	audio.stream = lap_audio
	audio.volume_db = -20
	audio.play()
	


