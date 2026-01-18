extends Spatial
onready var winnerAnimation = $Winner/AnimationPlayer
onready var loserAnimation = $Loser/AnimationPlayer

onready var playAgainBtn = $Control/CenterContainer/VBoxContainer/HBoxContainer2/PlayAgainBtn
onready var winnerLabel = $Control/CenterContainer/VBoxContainer/HBoxContainer/WinnerLabel



func _ready():
	playAgainBtn.grab_focus()
	winnerLabel.text = "Player " + String(Global.winner) + " won!"
	pass # Replace with function body.
	


func _process(_delta):
	winnerAnimation.play("HumanArmature|Man_Idle")
	loserAnimation.play("HumanArmature|Man_Clapping")
	pass


func _on_MenuBtn_pressed():
	get_tree().change_scene("res://MenuScreen.tscn")
	pass # Replace with function body.


func _on_PlayAgainBtn_pressed():
	get_tree().change_scene("res://Teste.tscn")
	pass # Replace with function body.
