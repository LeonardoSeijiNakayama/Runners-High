extends Node


onready var Player = get_parent()

signal lap_changed(current)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func next_lap()->void:
	Player.currentLap += 1
	print(Player.currentLap)
	emit_signal("lap_changed", Player.currentLap)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
