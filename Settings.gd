extends Control

onready var btnBack : Button = $VBoxContainer/Button/btnBack

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if btnBack.pressed:
		get_tree().change_scene("res://Menu.tscn")
	pass
