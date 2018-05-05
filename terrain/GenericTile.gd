tool
extends "res://terrain/TileBase.gd"

const RAND_MAX = 1 << 32

const axis = Vector3(0, 1, 0)
const start_dir = Vector3(0, 0, 1)

var inner_radius = sqrt(3) / 2 * (radius - path_width)
var subdivisions = 3
var noise_detail = 6

var _noise_amplitudes = null
var _seed = 0
var _mesh_instance

export(float, EASE) var terrain_ease = 1.0 setget set_terrain_ease
export(int) var noise_seed = 0 setget set_noise_seed
export(float) var noise_base = 0.0 setget set_noise_base
export(float) var noise_scale = 1.0 setget set_noise_scale
export(float) var noise_exponent = 1.0 setget set_noise_exponent
export(Material) var material_ground setget set_material_ground
export(Material) var material_terrain setget set_material_terrain

func set_terrain_ease(new):
	terrain_ease = new; regenerate_mesh()
func set_noise_seed(new):
	noise_seed = new; regenerate_mesh()
func set_noise_base(new):
	noise_base = new; regenerate_mesh()
func set_noise_scale(new):
	noise_scale = new; regenerate_mesh()
func set_noise_exponent(new):
	noise_exponent = new; regenerate_mesh()
func set_material_ground(new):
	material_ground = new; regenerate_mesh()
func set_material_terrain(new):
	material_terrain = new; regenerate_mesh()
func set_coordinates(new_coordinates): # Override
	.set_coordinates(new_coordinates)
	if noise_seed < 0: regenerate_mesh()

func _ready():
	if _mesh_instance != null:
		_mesh_instance.queue_free()
	_mesh_instance = MeshInstance.new()
	add_child(_mesh_instance)
	regenerate_mesh()

func polar(theta, radius):
	return start_dir.rotated(axis, -theta) * radius

func reset_noise():
	if noise_seed < 0:
		_seed = noise_seed
		_seed = int(coordinates.x) ^ _seed * 17
		_seed = int(coordinates.y) ^ _seed * 17
		if _seed < 0: _seed += RAND_MAX
	else:
		_seed = noise_seed
	
	_seed = rand_seed(_seed)[1]
	
	_noise_amplitudes = []
	for i in range(noise_detail):
		# offset, offset, rotation, scale
		_noise_amplitudes.push_back([
			get_next_float() * PI * 2,
			get_next_float() * PI * 2,
			get_next_float() * PI * 2,
			pow(float(i) / noise_detail, noise_exponent) * get_next_float(),
		])

func get_next_random():
	var result = rand_seed(_seed)
	_seed = result[1]
	return result[0] % RAND_MAX
func get_next_float():
	return get_next_random() / float(RAND_MAX)

func get_noise(position):
	var result = 0
	position = Vector2(position.x, position.z)
	for frequency in _noise_amplitudes.size():
		var amplitude = _noise_amplitudes[frequency]
		var rotated_position = position.rotated(amplitude[2])
		result += amplitude[3] * sin(amplitude[0] + position.x * frequency / radius)
		result += amplitude[3] * sin(amplitude[1] + position.y * frequency / radius)
	result = result * noise_scale + noise_base
	return ease(1 - Vector2(position.x, position.y).length() / inner_radius, terrain_ease) * result

func add_noisy_vertex(st, vertex):
	st.add_vertex(vertex + axis * get_noise(vertex))

func make_triangle_mesh(st, a, b, c):
	var db = (b - a) / subdivisions
	var dc = (c - b) / subdivisions
	for i in range(0, subdivisions):
		for j in range(0, i + 1):
			add_noisy_vertex(st, a + db * i + dc * j)
			add_noisy_vertex(st, a + db * (i + 1) + dc * j)
			add_noisy_vertex(st, a + db * (i + 1) + dc * (j + 1))
			if i > 0 and j > 0:
				add_noisy_vertex(st, a + db * i + dc * j)
				add_noisy_vertex(st, a + db * i + dc * (j - 1))
				add_noisy_vertex(st, a + db * (i + 1) + dc * j)

func regenerate_mesh():
	if !is_inside_tree(): return
	reset_noise()
	var depth = axis * height / 2
	var st = SurfaceTool.new()
	var mesh = null

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material_ground)
	for i in range(6):
		# Path
		st.add_triangle_fan([
			polar(PI / 3 * i, radius) + depth,
			polar(PI / 3 * (i + 1), radius) + depth,
			polar(PI / 3 * (i + 1), radius - path_width) + depth,
			polar(PI / 3 * i, radius - path_width) + depth,
		])
		# Side
		st.add_triangle_fan([
			polar(PI / 3 * (i + 1), radius) + depth,
			polar(PI / 3 * i, radius) + depth,
			polar(PI / 3 * i, radius) - depth,
			polar(PI / 3 * (i + 1), radius) - depth,
		])
		# Bottom
		st.add_triangle_fan([
			polar(PI / 3 * i, radius) - depth,
			Vector3() - depth,
			polar(PI / 3 * (i + 1), radius) - depth,
		])
	st.index()
	st.generate_normals()
	mesh = st.commit(mesh)

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material_terrain)
	for i in range(6):
		# Terrain
		make_triangle_mesh(st,
			Vector3(0, 0, 0) + depth,
			polar(PI / 3 * i, radius - path_width + EPS) + depth,
			polar(PI / 3 * (i + 1), radius - path_width + EPS) + depth
		)
	st.index()
	st.generate_normals()
	mesh = st.commit(mesh)

	_mesh_instance.mesh = mesh
