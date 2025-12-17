extends MeshInstance

export var rope_radius := 0.03

func update_rope(p0: Vector3, p1: Vector3) -> void:
	var dir = p1 - p0
	var dist = dir.length()
	if dist < 0.001:
		visible = false
		return
	visible = true
	
	dir /= dist
	
	var cyl := mesh as CylinderMesh
	if cyl:
		cyl.top_radius = rope_radius
		cyl.bottom_radius = rope_radius
		cyl.height = dist
	
	# coloca no meio
	global_transform.origin = (p0 + p1) * 0.5
	
	# cria uma base com Y apontando pra dir
	var y = dir
	var x = Vector3.UP.cross(y)
	if x.length() < 0.001:
		x = Vector3.RIGHT
	x = x.normalized()
	var z = x.cross(y).normalized()
	
	global_transform.basis = Basis(x, y, z)
