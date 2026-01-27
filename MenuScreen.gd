extends Spatial


onready var btnPlay : Button = $Control/VBoxContainer/btnPlay
onready var btnSettings : Button = $Control/VBoxContainer/btnSettings
onready var btnExit : Button = $Control/VBoxContainer/btnExit
onready var missile = $missile
onready var missile2 = $missile2
onready var missile3 = $missile3
onready var manAnimation = $Man2/AnimationPlayer
onready var fireAnimation = $fire/AnimationPlayer
onready var fire2Animation = $fire2/AnimationPlayer
onready var fire3Animation = $fire3/AnimationPlayer
onready var fireballAnimation1 = $Spatial/icosphere1/AnimationPlayer
onready var fireballAnimation2 = $Spatial/icosphere2/AnimationPlayer
onready var fireballAnimation3 = $Spatial/icosphere3/AnimationPlayer
onready var fireballAnimation4 = $Spatial2/icosphere1/AnimationPlayer
onready var fireballAnimation5 = $Spatial2/icosphere2/AnimationPlayer
onready var fireballAnimation6 = $Spatial2/icosphere3/AnimationPlayer
onready var menu = $Control/VBoxContainer

onready var settings = $Control/Settings
onready var settingsBackBtn = $Control/Settings/VBoxContainer/CenterContainer/btnBack
onready var music_slider = $Control/Settings/VBoxContainer/HBoxContainer/VBoxContainer/SliderMVolume
onready var sfx_slider = $Control/Settings/VBoxContainer/HBoxContainer/VBoxContainer/SliderGVolume

const SAVE_PATH := "user://settings.cfg"

var music_bus := -1
var sfx_bus := -1

var dir := {}

func _process(delta):
	missile.rotate_z(0.5*delta)
	missile2.rotate_z(-0.5*delta)
	missile3.rotate_z(0.5*delta)
	manAnimation.play("HumanArmature|Man_Swinging", 1, 0.02)
	manAnimation.seek(2, true)
	manAnimation.stop(false)
	fireAnimation.play("Take 001", 1, .25)
	fire2Animation.play("Take 001", 1, .29)
	fire3Animation.play("Take 001", 1, .2)
	


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	btnPlay.grab_focus()
	_setup_pingpong(fireballAnimation1)
	_setup_pingpong(fireballAnimation2)
	_setup_pingpong(fireballAnimation3)
	_setup_pingpong(fireballAnimation4)
	_setup_pingpong(fireballAnimation5)
	_setup_pingpong(fireballAnimation6)
	play_all_fireballs()



func _setup_pingpong(p: AnimationPlayer) -> void:
	dir[p] = 1
	p.connect("animation_finished", self, "_on_fireball_anim_finished", [p])



func play_all_fireballs():
	fireballAnimation1.play("Icosphere001Action", 1, 0.10)
	fireballAnimation2.play("Icosphere001Action001", 1, 0.10)
	fireballAnimation3.play("IcosphereAction", 1, 0.10)
	yield(get_tree().create_timer(1), "timeout")
	fireballAnimation4.play("Icosphere001Action", 1, 0.10)
	fireballAnimation5.play("Icosphere001Action001", 1, 0.10)
	fireballAnimation6.play("IcosphereAction", 1, 0.10)



func _on_fireball_anim_finished(anim_name: String, p: AnimationPlayer) -> void:
	# inverte a direção do player que terminou
	dir[p] *= -1
	p.playback_speed = dir[p]
	
	# toca de novo a mesma animação
	p.play(anim_name, -1, 0.25)
	
	# garante que começa do lado certo
	if dir[p] == 1:
		p.seek(0.0, true)
	else:
		var length := p.get_animation(anim_name).length
		p.seek(length, true)



func _on_btnPlay_pressed():
	set_process(false)
	get_tree().change_scene("res://Teste.tscn")


func _on_btnSettings_pressed():
	music_bus = AudioServer.get_bus_index("Music")
	sfx_bus = AudioServer.get_bus_index("SFX")
	
	var music_val = _load_value("Music", 70)
	var sfx_val = _load_value("SFX", 70)
	
	music_slider.value = music_val
	sfx_slider.value = sfx_val
	
	_apply_percent_to_bus(music_bus, music_val)
	_apply_percent_to_bus(sfx_bus, sfx_val)
	
	settingsBackBtn.grab_focus()
	
	menu.visible = false
	settings.visible = true


func _on_btnBack_pressed():
	menu.visible = true
	settings.visible = false
	btnSettings.grab_focus()


func _on_btnExit_pressed():
	get_tree().quit()


func _on_SliderMVolume_value_changed(value):
	_apply_percent_to_bus(music_bus, value)
	_save_value("Music", value)

func _on_SliderGVolume_value_changed(value):
	_apply_percent_to_bus(sfx_bus, value)
	_save_value("SFX", value)


func _apply_percent_to_bus(bus_idx: int, percent: float) -> void:
	var linear = percent / 100.0
	
	# Mute se estiver no zero
	if linear <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
		AudioServer.set_bus_volume_db(bus_idx, -80) # praticamente silêncio
		return
	
	AudioServer.set_bus_mute(bus_idx, false)
	
	
	var db = linear2db(linear)
	
	
	db = clamp(db, -40, 0)
	
	AudioServer.set_bus_volume_db(bus_idx, db)

func _save_value(key: String, value: float) -> void:
	var cfg = ConfigFile.new()
	cfg.load(SAVE_PATH) # se não existir, OK
	cfg.set_value("audio", key, value)
	cfg.save(SAVE_PATH)


func _load_value(key: String, default_value: float) -> float:
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK:
		return default_value
	return float(cfg.get_value("audio", key, default_value))
