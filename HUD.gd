extends Control

export(String, "p1_","p2_") var player_group := "p1_"

onready var bar := $StaminaBar
onready var abilityIcon := $AbilityIcon
onready var abilityLabel := $AbilityLabel
onready var lapsLabel := $LapsLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	_connect_to_player()
	

func _on_stamina_changed(current: float, maxv: float) -> void:
	bar.max_value = maxv
	bar.value = current

func _on_ability_changed(name: String)->void:
	abilityLabel.text = "Ability: " + name

func _on_lap_changed(current:int)->void:
	lapsLabel.text = "Lap: " + String(current) + "/3"

func _connect_to_player():
	var list := get_tree().get_nodes_in_group(player_group)
	if list.size() == 0:
		return
	var player = list[0]
	var movement = player.get_child(2)
	var ability = player.get_child(0)
	var laps = player.get_child(4)
	ability.connect("ability_changed", self, "_on_ability_changed")
	movement.connect("stamina_changed", self, "_on_stamina_changed")
	laps.connect("lap_changed", self, "_on_lap_changed")
	# Inicializa visual se o player já tiver valores
	# (caso você mantenha getters no player)
	# bar.max_value = player.stamina_max
	# bar.value = player.stamina


