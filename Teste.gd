extends Spatial

onready var p1 = $HBoxContainer/ViewportContainer2/Viewport/Player1
onready var p2 = $HBoxContainer/ViewportContainer/Viewport/Player2
onready var audio = $AudioStreamPlayer
onready var song : AudioStream = preload("res://audios/Tides of the Jaguar Temple.mp3")

onready var PauseMenuScene = preload("res://PauseMenuScene.tscn")
onready var pause_menu = PauseMenuScene.instance()



func _ready():
	add_child(pause_menu)
	pause_menu.hide()
	pause_menu.pause_mode = Node.PAUSE_MODE_PROCESS
	song.loop = true
	audio.stream = song
	audio.volume_db=-20



func _unhandled_input(event):
	_toggle_pause(event)



func _toggle_pause(event):
	if event.is_action_pressed("ui_cancel"): # Esc
		if get_tree().paused:
			return
		else:
			get_tree().paused = true
			pause_menu.show()
			pause_menu.resumeBtn.grab_focus()



func _process(_delta):
	if not audio.playing:
		audio.play()
	if p1.currentLap == 3:
		Global.winner = 1
		get_tree().change_scene("res://VictoryScreen.tscn")
	elif p2.currentLap == 3:
		Global.winner = 2
		get_tree().change_scene("res://VictoryScreen.tscn")
	pass
