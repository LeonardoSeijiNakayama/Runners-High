extends Spatial

onready var area = $Area
export(float) var speed_u = 0.02
export(float) var speed_v = 0.01

onready var mesh := $MeshInstance
var mat: SpatialMaterial


func _ready():
	area.connect("body_entered", self, "on_water_area_entered")
	mat = mesh.get_active_material(0)


func on_water_area_entered(body)->void:
	if body.is_in_group("Player"):
		print(body)
	


func _process(delta):
	if mat:
		var off = mat.uv1_offset
		off.x = fposmod(off.x + speed_u * delta, 1.0)
		off.y = fposmod(off.y + speed_v * delta, 1.0)
		mat.uv1_offset = off
