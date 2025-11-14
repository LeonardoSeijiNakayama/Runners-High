extends Control


onready var btnPlay : Button = $VBoxContainer/btnPlay
onready var btnSettings : Button = $VBoxContainer/btnSettings
onready var btnExit : Button = $VBoxContainer/btnExit


# Called when the node enters the scene tree for the first time.
func _ready():
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if btnPlay.pressed:
		get_tree().change_scene("res://Teste.tscn")
	if btnExit.pressed:
		get_tree().quit()
	if btnSettings.pressed:
		get_tree().change_scene("res://Settings.tscn")
