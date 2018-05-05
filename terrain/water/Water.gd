tool
extends "res://terrain/TileBase.gd"

const axis = Vector3(0, 1, 0)
const start_dir = Vector3(0, 0, 1)
const subdivisions = 4
const vertex_snap = Vector3(0.01, 0.01, 0.01)

export(Material) var water_material
onready var _mesh_instance = MeshInstance.new()


func _ready():
	add_child(_mesh_instance)
	if get_script().has_meta("cached_mesh") and (Engine.editor_hint and get_tree().edited_scene_root != self):
		_mesh_instance.mesh = get_script().get_meta("cached_mesh")
	else:
		regenerate_mesh()

func polar(theta, radius):
	return start_dir.rotated(axis, -fmod(theta + 4 * PI, 2 * PI)) * radius

func make_triangle_mesh(st, a, b, c):
	var db = (b - a) / subdivisions
	var dc = (c - b) / subdivisions
	for i in range(0, subdivisions):
		for j in range(0, i + 1):
			st.add_vertex(a + db * i + dc * j)
			st.add_vertex(a + db * (i + 1) + dc * j)
			st.add_vertex(a + db * (i + 1) + dc * (j + 1))
			if i > 0 and j > 0:
				st.add_vertex(a + db * i + dc * j)
				st.add_vertex(a + db * i + dc * (j - 1))
				st.add_vertex(a + db * (i + 1) + dc * j)

func regenerate_mesh():
	if !is_inside_tree(): return
	var st = SurfaceTool.new()
	var mesh = null

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(water_material)
	for i in range(6):
		# Water plane
		make_triangle_mesh(st,
			Vector3(0, 0, 0),
			polar(PI / 3 * (i - 1), radius).snapped(vertex_snap),
			polar(PI / 3 * i, radius).snapped(vertex_snap)
		)
	st.index()
	st.generate_normals()
	mesh = st.commit(mesh)

	get_script().set_meta("cached_mesh", mesh)

	_mesh_instance.mesh = mesh
