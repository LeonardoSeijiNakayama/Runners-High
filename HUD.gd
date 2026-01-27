extends Control

export(String, "p1_","p2_") var player_group := "p1_"

onready var bar := $Stamina/StaminaBar
onready var abilityIcon := $Ability/AbilityTexture
onready var abilityLabel := $Ability/AbilityLabel
onready var lapsLabel := $LapsLabel

onready var missileTexture = load("res://images/icon foguete sujo.png")
onready var bananaTexture = load("res://images/icon banana sujo.png")
onready var runnersHighTexture = load("res://images/icon corrida sujo.png")
onready var frameTexture = load("res://images/icon moldura sujo.png")
onready var shieldTexture = load("res://images/icon escudo sujo.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	_connect_to_player()
	

func _on_stamina_changed(current: float, maxv: float) -> void:
	bar.max_value = maxv
	bar.value = current

func _on_ability_changed(name: String)->void:
	abilityLabel.text = "Ability: " + name
	print(name)
	match name:
		"Missile":
			abilityIcon.texture = missileTexture
		"Banana Peel":
			abilityIcon.texture = bananaTexture
		"Runners High":
			abilityIcon.texture = runnersHighTexture
		"Shield":
			abilityIcon.texture = shieldTexture
		"-":
			abilityIcon.texture = frameTexture

func _on_lap_changed(current:int)->void:
	lapsLabel.text = "Laps: " + String(current) + "/3"

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


