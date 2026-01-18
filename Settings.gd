extends Control

onready var btnBack : Button = $VBoxContainer/CenterContainer/btnBack
const SAVE_PATH := "user://settings.cfg"

onready var music_slider := $VBoxContainer/HBoxContainer/VBoxContainer/SliderMVolume
onready var sfx_slider := $VBoxContainer/HBoxContainer/VBoxContainer/SliderGVolume

var music_bus := -1
var sfx_bus := -1

func _ready():
	btnBack.grab_focus()
	music_bus = AudioServer.get_bus_index("Music")
	sfx_bus = AudioServer.get_bus_index("SFX")

	# Carrega valores salvos (padrão 70 se não existir)
	var music_val = _load_value("Music", 70)
	var sfx_val = _load_value("SFX", 70)

	# Seta slider e aplica volume
	music_slider.value = music_val
	sfx_slider.value = sfx_val

	_apply_percent_to_bus(music_bus, music_val)
	_apply_percent_to_bus(sfx_bus, sfx_val)

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

	# Converte linear -> dB (curva natural pro ouvido)
	var db = linear2db(linear)

	# (Opcional) Limita o mínimo pra não ficar baixo "demais"
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


func _on_btnBack_pressed():
	get_tree().change_scene("res://MenuScreen.tscn")
	pass 




