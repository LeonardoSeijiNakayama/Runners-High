extends Spatial

onready var p1 = $HBoxContainer/ViewportContainer2/Viewport/Player1
onready var p2 = $HBoxContainer/ViewportContainer/Viewport/Player2

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass 


func _process(_delta):
	if p1.currentLap == 3 or p2.currentLap == 3:
		get_tree().change_scene("res://Menu.tscn")
	pass
