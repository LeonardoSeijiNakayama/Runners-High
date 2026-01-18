extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var resumeBtn = $CenterContainer/VBoxContainer/HBoxContainer2/ResumeBtn
onready var menuBtn = $CenterContainer/VBoxContainer/HBoxContainer2/MenuBtn



func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	resumeBtn.pause_mode = Node.PAUSE_MODE_PROCESS
	menuBtn.pause_mode = Node.PAUSE_MODE_PROCESS
	resumeBtn.grab_focus()



func _on_ResumeBtn_pressed():
	get_tree().paused = false
	hide()
	pass 



func _on_MenuBtn_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://MenuScreen.tscn")

