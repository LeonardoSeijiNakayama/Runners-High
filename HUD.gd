extends Control

export(String, "p1_","p2_") var player_group := "p1_"

onready var bar := $ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
	_connect_to_player()
	

func _on_stamina_changed(current: float, maxv: float) -> void:
	bar.max_value = maxv
	bar.value = current

func _connect_to_player():
	var list := get_tree().get_nodes_in_group(player_group)
	if list.size() == 0:
		return
	var player = list[0]
	player.connect("stamina_changed", self, "_on_stamina_changed")
	# Inicializa visual se o player já tiver valores
	# (caso você mantenha getters no player)
	# bar.max_value = player.stamina_max
	# bar.value = player.stamina


